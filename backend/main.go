package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/jackc/pgx/v4"
)

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

	rows, err := conn.Query(ctx, "SELECT * FROM activities")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		var name string
		if err := rows.Scan(&id, &name); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("\nid: %s, name: %s,\n", id, name)
	}

	fs := http.FileServer(http.Dir("../"))
	http.Handle("/", fs)

	log.Print("Listening on http://localhost:3001")
	err = http.ListenAndServe(":3001", nil)
	if err != nil {
		log.Fatal(err)
	}
}
