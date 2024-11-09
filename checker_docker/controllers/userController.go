package controllers

import (
	"checker/initializers"
	"checker/models"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt"
	"golang.org/x/crypto/bcrypt"
)

var QUEUE_SIZE = 10
var PARRALEL_CONTAINERS = 4
var TIMEOUT_UPLOAD = 60

var (
	requestQueue = make(chan uploadRequest, QUEUE_SIZE)
	semaphore    = make(chan struct{}, PARRALEL_CONTAINERS)
)

type uploadRequest struct {
	c        *gin.Context
	file     *multipart.FileHeader
	userID   interface{}
	userDir  string
	filename string
}

func Signup(c *gin.Context) {

	var body struct {
		Email    string
		Password string
	}

	if c.Bind(&body) != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Failed to read body!",
		})
		return
	}
	var existingUser models.User
	if err := initializers.DB.Where("email = ?", body.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email already in use"})
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(body.Password), 10)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Failed to hash password!",
		})
		return
	}

	user := models.User{Email: body.Email, Password: string(hash), Timeout: 0}
	result := initializers.DB.Create(&user)

	if result.Error != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Failed to add user!",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "Signup OK!"})
}

func Login(c *gin.Context) {
	var body struct {
		Email    string
		Password string
	}

	if c.Bind(&body) != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Failed to read body!",
		})
		return
	}

	var user models.User
	initializers.DB.First(&user, "email = ?", body.Email)

	if user.ID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid email or password!",
		})
		return
	}

	err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(body.Password))

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid email or password!",
		})
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"foo": user.ID,
		"exp": time.Now().Add(time.Hour * 24 * 7).Unix(),
	})

	// Sign and get the complete encoded token as a string using the secret
	tokenString, err := token.SignedString([]byte(os.Getenv("SECRET")))

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Failed to create token",
		})
		return
	}
	fmt.Println(tokenString, err)

	c.JSON(http.StatusOK, gin.H{"token": tokenString})
}

func Validate(c *gin.Context) {

	user, _ := c.Get("user")

	c.JSON(http.StatusOK, gin.H{
		"message": user.(models.User).Email,
	})
}

func LogoutHandler(c *gin.Context) {
	// Set the cookie to expire immediately
	c.SetCookie("token", "", -1, "/", "localhost", false, true) // HTTP-only cookie

	c.JSON(http.StatusOK, gin.H{"message": "Logout successful!"})
}

func CanUpload(c *gin.Context) {

	userID, _ := c.Get("user")
	var user models.User
	initializers.DB.First(&user, userID)

	waitTime := time.Now().Unix() - user.Timeout

	if waitTime < int64(TIMEOUT_UPLOAD) {
		c.JSON(http.StatusOK, gin.H{"wait": TIMEOUT_UPLOAD - int(waitTime)})
		return
	}
	if waitTime >= int64(TIMEOUT_UPLOAD) {
		c.JSON(http.StatusOK, gin.H{"wait": 0})
	}

}
func UploadFile(c *gin.Context) {
	file, err := c.FormFile("file")

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, _ := c.Get("user")
	var user models.User
	initializers.DB.First(&user, userID)

	// Check the timeout condition
	waitTime := time.Now().Unix() - user.Timeout

	if waitTime < int64(TIMEOUT_UPLOAD) {
		c.JSON(http.StatusOK, gin.H{"wait": TIMEOUT_UPLOAD - int(waitTime)})
		return
	}
	user.Timeout = time.Now().Unix()
	if err := initializers.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Create a user directory if it does not exist
	userDir := filepath.Join(os.Getenv("BPATH"), user.Email)
	if err := os.MkdirAll(userDir, os.ModePerm); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Generate a hash of the filename with timestamp
	hash := md5.Sum([]byte(string(time.Now().Unix())))
	hashString := hex.EncodeToString(hash[:])

	timestamp := time.Now().Format("02.01-15_04") // Day.Month_Hour:Min
	newFilename := fmt.Sprintf("%s_%s.c", hashString, timestamp)
	filePath := filepath.Join(userDir, newFilename)

	fmt.Println("Generated filename:", newFilename)
	fmt.Println("File path:", filePath)

	// Save the file to the specified location
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	if true {
		scriptsDir := filepath.Join(os.Getenv("BPATH"), "scripts") // Adjust as needed
		if err := copyFiles(scriptsDir, userDir); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}
	// Create an upload request and attempt to add it to the queue
	req := uploadRequest{c: c, file: file, userID: user.ID, userDir: userDir, filename: newFilename}
	select {
	case requestQueue <- req:
		c.JSON(http.StatusOK, gin.H{"status": "success"})
	default:
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Queue is full"})
	}
}
func ProcessQueue() {
	for req := range requestQueue {
		semaphore <- struct{}{}
		go func(req uploadRequest) {
			defer func() { <-semaphore }()

			println("I m in process queue!")
			output, err := runInDocker(req.filename, req.userDir)
			println("I finished running in docker!")
			println(output)
			result := output
			if err != nil {
				req.c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				result = err.Error()
			} else {
				println(output)
				req.c.JSON(http.StatusOK, gin.H{"status": "file executed successfully", "output": output})
			}

			// Log the upload details in UploadHistory
			uploadRecord := models.UploadHistory{
				UserID:    req.userID.(uint), // Assuming userID is of type uint
				Filename:  req.filename,
				Timestamp: time.Now(),
				Result:    result,
			}

			if dbErr := initializers.DB.Create(&uploadRecord).Error; dbErr != nil {
				fmt.Printf("Error saving upload history: %v\n", dbErr)
			}
		}(req)
	}
}
func copyFiles(srcDir, destDir string) error {
	files, err := ioutil.ReadDir(srcDir)
	if err != nil {
		return fmt.Errorf("failed to read source directory: %w", err)
	}

	for _, file := range files {
		if !file.IsDir() { // Ignore subdirectories
			srcFile := filepath.Join(srcDir, file.Name())
			destFile := filepath.Join(destDir, file.Name())
			if err := copyFile(srcFile, destFile); err != nil {
				return err
			}
		}
	}
	return nil
}

func copyFile(src, dst string) error {
	input, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	if err := os.WriteFile(dst, input, 0644); err != nil {
		return err
	}
	return nil
}
func runInDocker(filename, path string) (string, error) {

	fmt.Printf("Running Docker with: %s in path: %s\n", filename, path)

	// Command to unzip the file and execute the script
	cmd := exec.Command("docker", "run", "--rm", "--cpus=8.0", "--memory=2g",
		"-v", fmt.Sprintf("%s:/app", path), "gcc-runner",
		"bash", "-c", fmt.Sprintf("chmod u+x tema.sh && ./tema.sh %s", filename))

	output, err := cmd.CombinedOutput()

	return string(output), err
}

func QueueStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"queue-status": len(requestQueue)})
}
