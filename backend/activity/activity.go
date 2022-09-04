package activity

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/jackc/pgx/v4/pgxpool"
	"log"
	"net/http"
	"strings"
)

type Activity struct {
	Id   string `json:"id"`
	Name string `json:"name"`
}

type ActivityResponse struct {
	Activities []*Activity `json:"activities"`
}

type ActivityPost struct {
	Activity Activity `json:"activity"`
}

func ActivityHandler(conn *pgxpool.Pool) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/activities/get":
			actResp, err := getActivities(r.Context(), conn)
			if err != nil {
				log.Println(fmt.Errorf("could not get activities: %w", err))
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			actJson, err := json.Marshal(actResp)
			_, err = w.Write(actJson)
			if err != nil {
				log.Println(fmt.Errorf("could not write activity to response body: %w", err))
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			return
		case "/activities/insert":
			var ap ActivityPost
			err := json.NewDecoder(r.Body).Decode(&ap)
			_, err = conn.Exec(r.Context(), fmt.Sprintf("INSERT INTO activities (id, name) VALUES (DEFAULT, '%s')", strings.ToLower(ap.Activity.Name)))
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			return
		case "/activities/delete":
			var ap ActivityPost
			err := json.NewDecoder(r.Body).Decode(&ap)
			_, err = conn.Exec(r.Context(), fmt.Sprintf("DELETE FROM activities WHERE id = '%s'", ap.Activity.Id))
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
		}
	})
}

func getActivities(ctx context.Context, conn *pgxpool.Pool) (*ActivityResponse, error) {
	actResp := &ActivityResponse{}

	rows, err := conn.Query(ctx, "SELECT * FROM activities")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var (
			id   string
			name string
		)
		if err := rows.Scan(&id, &name); err != nil {
			return nil, err
		}
		actResp.Activities = append(actResp.Activities, &Activity{
			Id:   id,
			Name: name,
		})
	}
	return actResp, nil
}
