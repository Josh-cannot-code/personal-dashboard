package main

import (
	"log"
	"net/http"
)

func main() {
	fs := http.FileServer(http.Dir("../"))
	http.Handle("/", fs)

	log.Print("Listening on http://192.168.1.173:3001")
	err := http.ListenAndServe("192.168.1.173:3001", nil)
	if err != nil {
		log.Fatal(err)
	}
}
