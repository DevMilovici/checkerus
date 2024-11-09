package initializers

import (
	"checker/models"

	"gorm.io/gorm"
)

func SyncDatabase(db *gorm.DB) {
	db.AutoMigrate(&models.User{})
	db.AutoMigrate(&models.UploadHistory{})

}
