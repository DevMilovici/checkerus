package middleware

import (
	"checker/initializers"
	"checker/models"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
)

func RequireAuth(c *gin.Context) {
	//tokenString, err := c.Cookie("Authorization")
	tokenString := c.GetHeader("Authorization")

	if tokenString == "" {
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}

	// Remove "Bearer " prefix if it's there
	if strings.HasPrefix(tokenString, "Bearer ") {
		tokenString = strings.TrimPrefix(tokenString, "Bearer ")
	} else {
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}
	// if err != nil {
	// 	fmt.Print("1")
	// 	c.AbortWithStatus(http.StatusUnauthorized)
	// }

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {

		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}

		return []byte(os.Getenv("SECRET")), nil
	})

	if err != nil {
		fmt.Print("2")
		c.AbortWithStatus(http.StatusUnauthorized)
		return
		//log.Fatal(err)
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		if (float64)(time.Now().Unix()) > claims["exp"].(float64) {
			fmt.Print("3")
			c.AbortWithStatus(http.StatusUnauthorized)
		}
		var user models.User
		initializers.DB.First(&user, claims["foo"])

		if user.ID == 0 {
			fmt.Print("5")
			c.AbortWithStatus(http.StatusUnauthorized)
		}

		c.Set("user", user)

		c.Next()
		fmt.Println(claims["foo"], claims["exp"])
	} else {
		fmt.Print("1")
		c.AbortWithStatus(http.StatusUnauthorized)
	}

}
