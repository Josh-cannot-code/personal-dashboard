package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v4"
)

type Activity struct {
	Id   string `json:"id"`
	Name string `json:"name"`
}

type ActivityResponse struct {
	Activities []*Activity `json:"activities"`
}

type ActivityPost struct {
	Name string `json:"name"`
}

func main() {
	// Initialize database
	dsn := "postgresql://joshd:kEiF1hgBt3JdE3IMSqyk7g@free-tier11.gcp-us-east1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dpersonal-db-1796"
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
		_, err = conn.Exec(r.Context(), fmt.Sprintf("INSERT INTO activities (id, name) VALUES (DEFAULT, '%s')", strings.ToLower(ap.Name)))
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
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
