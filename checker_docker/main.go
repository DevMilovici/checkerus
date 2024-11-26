package main

import (
	"checker/controllers"
	"checker/initializers"
	"checker/middleware"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func init() {
	initializers.LoadEnvVariables()
	DB := initializers.ConnectToDb()
	initializers.SyncDatabase(DB)
}
func main() {

	go controllers.ProcessQueue()

	r := gin.Default()
	config := cors.Config{
		AllowOrigins:     []string{"*"}, // Change to your frontend port
		AllowMethods:     []string{"GET", "POST"},           // Add other methods if needed
		AllowHeaders:     []string{"Authorization", "Content-Type"},
		AllowCredentials: true, // Allow credentials (cookies, authorization headers)
		MaxAge:           12 * time.Hour,
	}

	r.Use(cors.New(config))

	r.POST("/signup", controllers.Signup)
	r.POST("/login", controllers.Login)
	r.GET("/validate", middleware.RequireAuth, controllers.Validate)
	r.GET("/logout", middleware.RequireAuth, controllers.LogoutHandler)
	r.POST("/upload", middleware.RequireAuth, controllers.UploadFile)
	r.GET("/canLoad", middleware.RequireAuth, controllers.CanUpload)
	r.GET("/history", middleware.RequireAuth, controllers.GetUserUploads)
	r.GET("/queue-status", middleware.RequireAuth, controllers.QueueStatus)

	r.Run()

}
