package main

import (
	"log"
	"net/http"
)

func main() {
	fs := http.FileServer(http.Dir("../"))
	http.Handle("/", fs)

	log.Print("Listening on 192.168.1.173")
	err := http.ListenAndServe("192.168.1.173:3000", nil)
	if err != nil {
		log.Fatal(err)
	}
}
