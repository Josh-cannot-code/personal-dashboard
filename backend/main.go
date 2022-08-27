package main

import (
	"log"
	"net/http"
)

func main() {
	fs := http.FileServer(http.Dir("../"))
	http.Handle("/", fs)

	log.Print("Listening on http://localhost:3001")
	err := http.ListenAndServe(":3001", nil)
	if err != nil {
		log.Fatal(err)
	}
}
