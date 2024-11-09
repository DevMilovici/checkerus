package models

import "time"

type UploadHistory struct {
	ID        uint `gorm:"primaryKey"`
	UserID    uint
	Filename  string
	Timestamp time.Time // Date of upload
	Result    string    // Result from Docker execution
}
