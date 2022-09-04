package main

import (
	"bytes"
	"context"
	_ "embed"
	"fmt"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/joho/godotenv"
	"github.com/josh-cannot-code/backend/activity"
	"github.com/josh-cannot-code/backend/projecteuler"
	"html/template"
	"log"
	"net/http"
	"os"
	"time"
)

//go:embed index.html.tmpl
var indexTmpl string

type templateFiller struct {
	ApiUrl string
}

func main() {
	// Load environment variables
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal(err)
	}

	// Initialize database
	dsn := "postgresql://" + os.Getenv("COCKROACH_KEY") + "@free-tier11.gcp-us-east1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dpersonal-db-1796"
	ctx := context.Background()
	conn, err := pgxpool.Connect(ctx, dsn)
	defer conn.Close()
	if err != nil {
		log.Fatal("failed to connect database", err)
	}
	var now time.Time
	err = conn.QueryRow(ctx, "SELECT NOW()").Scan(&now)
	if err != nil {
		log.Fatal("failed to execute query", err)
	}
	fmt.Println(now)

	// Wire environment variables to the frontend
	var indexHtml bytes.Buffer
	templ, err := template.New("indexTmpl").Parse(indexTmpl)
	if err != nil {
		log.Fatal(err)
	}
	err = templ.Execute(&indexHtml, templateFiller{ApiUrl: os.Getenv("API_URL")})
	if err != nil {
		log.Fatal(err)
	}
	err = os.Chdir("../")
	if err != nil {
		log.Fatal(err)
	}
	f, err := os.Create("index.html")
	if err != nil {
		log.Fatal(err)
	}
	_, err = f.Write(indexHtml.Bytes())
	if err != nil {
		log.Fatal(err)
	}
	err = f.Close()
	if err != nil {
		log.Fatal(err)
	}
	err = os.Chdir("backend")
	if err != nil {
		log.Fatal(err)
	}

	// Register handlers
	http.Handle("/activities/", activity.ActivityHandler(conn))

	http.Handle("/project-euler/", projecteuler.EulerHandler(conn))

	fs := http.FileServer(http.Dir("../"))
	http.Handle("/", fs)

	log.Print("Listening on http://localhost:3001")
	err = http.ListenAndServe(":3001", nil)
	if err != nil {
		log.Fatal(err)
	}
}
