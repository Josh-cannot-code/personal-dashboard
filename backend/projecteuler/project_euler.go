package projecteuler

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/gocolly/colly"
	"github.com/jackc/pgx/v4/pgxpool"
	"log"
	"net/http"
	"strconv"
)

type EulerProblem struct {
	Id     string `json:"id"`
	Number int    `json:"number"`
	Name   string `json:"name"`
	Html   string `json:"html"`
}

const ProblemId = "b11f93b9-1e7c-4bfa-909b-ce29234d8c05"

func EulerHandler(conn *pgxpool.Pool) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/project-euler/get-problem" {
			resp, err := getCurrentProjectEulerProblem(conn, r.Context())
			if err != nil {
				log.Println(fmt.Errorf("could not get current project euler problem: %w", err))
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			respJson, _ := json.Marshal(resp)
			_, err = w.Write(respJson)
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			return
		}
		var reqBody EulerProblem
		decoder := json.NewDecoder(r.Body)
		err := decoder.Decode(&reqBody)
		if err != nil {
			log.Println(fmt.Errorf("could not decode body of request in euler handler: %w", err))
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		switch r.URL.Path {
		case "/project-euler/next":
			err = changeEulerProblem(r.Context(), conn, reqBody.Number, "next")
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			return
		case "/project-euler/prev":
			err = changeEulerProblem(r.Context(), conn, reqBody.Number, "prev")
			if err != nil {
				log.Println(err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			return
		default:
			log.Println("unhandled request path on project euler endpoint")
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
	})
}

func getCurrentProjectEulerProblem(conn *pgxpool.Pool, ctx context.Context) (*EulerProblem, error) {
	var problem EulerProblem
	// Get current project euler problem from db
	rows, err := conn.Query(ctx, "SELECT number FROM project_euler")
	if err != nil {
		log.Fatal(fmt.Errorf("could not get euler problem: %w", err))
	}
	var currentProblem int
	_ = rows.Next()
	err = rows.Scan(&currentProblem)
	if err != nil {
		log.Fatal(fmt.Errorf("could not scan euler problem: %w", err))
	}
	rows.Close()
	problem.Number = currentProblem

	url := "https://projecteuler.net/problem=" + strconv.Itoa(problem.Number)

	c := colly.NewCollector()

	c.OnError(func(_ *colly.Response, err error) {
		log.Println("Something went wrong:", err)
	})

	c.OnHTML("div[id=content]", func(e *colly.HTMLElement) {
		problem.Name = e.DOM.Find("h2").Text()
		problemHtml, err := e.DOM.Find("div.problem_content").Html()
		if err != nil {
			log.Fatal(err)
		}
		problem.Html = problemHtml
	})

	err = c.Visit(url)
	if err != nil {
		return nil, err
	}
	problem.Id = ProblemId
	return &problem, nil
}

func changeEulerProblem(ctx context.Context, conn *pgxpool.Pool, problemNumber int, direction string) error {
	if direction == "next" {
		problemNumber += 1
	} else {
		problemNumber -= 1
	}
	_, err := conn.Exec(ctx, fmt.Sprintf("UPDATE project_euler SET number = %d WHERE id = '%s'", problemNumber, ProblemId))
	if err != nil {
		return fmt.Errorf("error updating euler problem: %w", err)
	}
	return nil
}
