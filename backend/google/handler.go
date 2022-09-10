package google

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

func EndpointHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		events, err := getUpcomingCalendarEvents(r.Context())
		if err != nil {
			log.Println(fmt.Errorf("could not get events from google: %w", err).Error())
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		eventsJson, err := json.Marshal(events)
		if err != nil {
			log.Println(fmt.Errorf("could not marshal events to json: %w", err).Error())
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		_, err = w.Write(eventsJson)
		if err != nil {
			log.Println(fmt.Errorf("could not write to response body: %w", err).Error())
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
	})
}
