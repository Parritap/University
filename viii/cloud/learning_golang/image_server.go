package main

import (
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// Agregar los nombre de los archivos de imagen en una array
// y determinar la cantidad de imagenes disponibles.
func main() {
	args := os.Args
	dirPath := args[1] //First arg.
	imageFiles, err := GetImageFiles(dirPath)
	if err != nil {
		fmt.Println("Error:", err)
	} else {
		fmt.Println("Image files:")
		for _, img := range imageFiles {
			fmt.Println(img)
		}
	}

	fmt.Println("----------------------------------------------------")
	random_img := getRandomFile(imageFiles)
	fmt.Printf("A RANDOM IMAGE: %v \n", random_img)

	// Obtener el nombre del sistema operativo
	fmt.Println("Operating System:", runtime.GOOS)
	hostname, err := os.Hostname()
	fmt.Println("hostname ---->", hostname)

	//fmt.Println("Converting file into base64: ...........")
	//base64, err := FileToBase64(random_img)
	//fmt.Println(base64)

}
func GetImageFiles(dirPath string) ([]string, error) {
	// Check if the directory exists
	info, err := os.Stat(dirPath)
	if os.IsNotExist(err) {
		return nil, fmt.Errorf("directory does not exist: %s", dirPath)
	}

	// Ensure the path is a directory
	if !info.IsDir() {
		return nil, fmt.Errorf("%s is not a directory", dirPath)
	}

	// Variable to store image file paths
	var imageFiles []string

	// Walk through the directory and find image files
	err = filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Get the file extension
		ext := strings.ToLower(filepath.Ext(info.Name()))

		// Check if the file is a valid image type (jpg, jpeg, png)
		if ext == ".jpg" || ext == ".jpeg" || ext == ".png" {
			// Add the absolute path of the image file to the slice
			absPath, err := filepath.Abs(path)
			if err != nil {
				return err
			}
			imageFiles = append(imageFiles, absPath)
		}

		return nil
	})

	// Return an error if there was an issue walking through the directory
	if err != nil {
		return nil, err
	}

	return imageFiles, nil
}

func getRandomFile(files []string) string {
	rand.Seed(time.Now().UnixNano())
	return files[rand.Intn(len(files))]
}

func FileToBase64(filePath string) (string, error) {
	// Read the entire file
	fileBytes, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "", fmt.Errorf("error reading file: %v", err)
	}

	// Encode the bytes to base64
	base64String := base64.StdEncoding.EncodeToString(fileBytes)

	return base64String, nil
}
