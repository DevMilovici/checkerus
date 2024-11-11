package models

import "time"

type UploadHistory struct {
	ID        uint `gorm:"unique;primaryKey;autoIncrement"`
	UserID    uint
	Filename  string
	Timestamp time.Time // Date of upload
	Result    string    // Result from Docker execution
}
