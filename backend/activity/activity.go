package activity

import (
	"encoding/json"
	"fmt"
	"github.com/jackc/pgx/v4"
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
	Action   string   `json:"action"` // either insert or delete
}

func GetHandler(conn *pgx.Conn) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

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
}

func PostHandler(conn *pgx.Conn) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var ap ActivityPost
		err := json.NewDecoder(r.Body).Decode(&ap)
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
}
