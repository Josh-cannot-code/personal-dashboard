package main

import (
	"bytes"
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"github.com/jackc/pgx/v4"
	"github.com/joho/godotenv"
	"html/template"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

//go:embed index.html.tmpl
var indexTmpl string

type Activity struct {
	Id   string `json:"id"`
	Name string `json:"name"`
}

type ActivityResponse struct {
	Activities []*Activity `json:"activities"`
}

type ActivityPost struct {
	Activity Activity `json:"activity"`
	Action   string   `json:"action"` // either insert or delete
}

type templateFiller struct {
	ApiUrl string
}

func main() {
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal(err)
	}
	// Initialize database
	dsn := "postgresql://" + os.Getenv("COCKROACH_KEY") + "@free-tier11.gcp-us-east1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dpersonal-db-1796"
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dsn)
	defer conn.Close(context.Background())
	if err != nil {
		log.Fatal("failed to connect database", err)
	}
	var now time.Time
	err = conn.QueryRow(ctx, "SELECT NOW()").Scan(&now)
	if err != nil {
		log.Fatal("failed to execute query", err)
	}
	fmt.Println(now)

	// Wire env vars to the frontend
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

	http.HandleFunc("/activities/get", func(w http.ResponseWriter, r *http.Request) {
		actResp := &ActivityResponse{}

		rows, err := conn.Query(r.Context(), "SELECT * FROM activities")
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		defer rows.Close()
		for rows.Next() {
			var (
				id   string
				name string
			)
			if err := rows.Scan(&id, &name); err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			actResp.Activities = append(actResp.Activities, &Activity{
				Id:   id,
				Name: name,
			})
		}
		actJson, err := json.Marshal(actResp)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		_, err = w.Write(actJson)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
	})

	http.HandleFunc("/activities/post", func(w http.ResponseWriter, r *http.Request) {
		var ap ActivityPost
		err = json.NewDecoder(r.Body).Decode(&ap)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		switch ap.Action {
		case "insert":
			// TODO: make this unique?
			_, err = conn.Exec(r.Context(), fmt.Sprintf("INSERT INTO activities (id, name) VALUES (DEFAULT, '%s')", strings.ToLower(ap.Activity.Name)))
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
		case "delete":
			_, err = conn.Exec(r.Context(), fmt.Sprintf("DELETE FROM activities WHERE id = '%s'", strings.ToLower(ap.Activity.Id)))
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
		}
	})

	fs := http.FileServer(http.Dir("../"))
	http.Handle("/", fs)

	log.Print("Listening on http://localhost:3001")
	err = http.ListenAndServe(":3001", nil)
	if err != nil {
		log.Fatal(err)
	}
}
