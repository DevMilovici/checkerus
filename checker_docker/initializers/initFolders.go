package initializers

import (
	"fmt"
	"os"
)

func CreateDir(dirPath string) {

	// Create the directory with permissions 0755 (rwxr-xr-x)
	err := os.Mkdir(dirPath, 0755)
	if err != nil {
		fmt.Println("Error creating directory:", err)
		return
	}

	fmt.Println("Directory created successfully:", dirPath)
}
