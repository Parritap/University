package main

import (
	"encoding/base64"
	"fmt"
	"html/template"
	"io/ioutil"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

type Imagen struct {
	Nombre    string
	Extension string
	Contenido string
}

type PageData struct {
	Titulo   string
	Hostname string
	Tema     string
	Nombre   string
	Imagenes []Imagen
}

func handler(w http.ResponseWriter, r *http.Request) {

	rand.Seed(time.Now().UnixNano())
	carpeta := os.Args[3]
	//cantidad, _ := strconv.Atoi(os.Args[2])
	cantidad := rand.Intn(3) + 1

	//Chooses a random HTML template:
	randNumber := strconv.Itoa(rand.Intn(3) + 1)
	fmt.Println(os.Args[0])
	tmplPath := filepath.Join("html", "index"+randNumber+".html")

	//
	tmpl, err := template.ParseFiles(tmplPath)
	if err != nil {
		fmt.Println(err)
		http.Error(w, "Error al cargar la plantilla", http.StatusInternalServerError)
		return
	}

	hostname, err := os.Hostname()
	if err != nil {
		http.Error(w, "Error al obtener el hostname", http.StatusInternalServerError)
		return
	}

	imagenes, _ := GetImages("./images/"+carpeta, cantidad)

	fmt.Println(imagenes)
	data := PageData{
		Titulo:   "Servidor de imágenes",
		Hostname: hostname,
		Tema:     carpeta,
		Nombre:   "Anubis",
		Imagenes: imagenes,
	}

	if err = tmpl.Execute(w, data); err != nil {
		fmt.Printf("Error al renderizar la plantilla: %v\n", err)
	}
}

func main() {
	http.HandleFunc("/", handler)
	ip := os.Args[1]
	puerto := os.Args[2]
	address := ip + ":" + puerto
	fmt.Printf("Servidor iniciado en http://%s\n", address)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		fmt.Println("Error al iniciar el servidor", err)
	}
}

func esImagen(nombreArchivo string) bool {
	ext := filepath.Ext(nombreArchivo)
	switch ext {
	case ".jpg", ".jpeg", ".png":
		return true
	}
	return false
}

func GetImages(carpeta string, limite int) ([]Imagen, error) {
	archivos, err := ioutil.ReadDir(carpeta)
	if err != nil {
		return nil, err
	}

	var imagenes []Imagen
	for _, archivo := range archivos {
		if archivo.IsDir() || !esImagen(archivo.Name()) {
			continue
		}

		rutaArchivo := filepath.Join(carpeta, archivo.Name())
		contenido, err := ioutil.ReadFile(rutaArchivo)
		if err != nil {
			fmt.Println("Error al leer el archivo:", err)
			continue
		}

		imagenBase64 := base64.StdEncoding.EncodeToString(contenido)
		extension := filepath.Ext(archivo.Name())[1:]
		imagen := Imagen{
			Nombre:    archivo.Name(),
			Extension: extension,
			Contenido: imagenBase64,
		}

		imagenes = append(imagenes, imagen)
	}

	rand.Seed(time.Now().UnixNano())
	rand.Shuffle(len(imagenes), func(i, j int) {
		imagenes[i], imagenes[j] = imagenes[j], imagenes[i]
	})

	if len(imagenes) > limite {
		imagenes = imagenes[:limite]
	}
	return imagenes, nil
}
