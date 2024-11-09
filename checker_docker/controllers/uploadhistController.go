package controllers

import (
	"checker/initializers"
	"checker/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetUserUploads(c *gin.Context) {

	userID, _ := c.Get("user")
	var user models.User
	initializers.DB.First(&user, userID)

	// Query the upload history for the user
	var uploads []models.UploadHistory
	if err := initializers.DB.
		Select("user_id, timestamp, result"). // Only select these fields
		Where("user_id = ?", user.ID).
		Find(&uploads).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not retrieve uploads"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"uploads": uploads})
}
