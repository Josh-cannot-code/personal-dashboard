package projecteuler

import (
	"encoding/json"
	"fmt"
	"github.com/gocolly/colly"
	"log"
	"net/http"
	"strconv"
)

type EulerProblem struct {
	Id   int    `json:"id"`
	Name string `json:"name"`
	Html string `json:"html"`
}

func EulerHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var reqBody EulerProblem
		decoder := json.NewDecoder(r.Body)
		err := decoder.Decode(&reqBody)
		if err != nil {
			log.Println(fmt.Errorf("could not decode body of request in euler handler: %w", err))
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		resp, err := GetCurrentProjectEulerProblem(reqBody.Id)
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
	})
}

func GetCurrentProjectEulerProblem(problemNumber int) (*EulerProblem, error) {
	var problem EulerProblem
	problem.Id = problemNumber

	url := "https://projecteuler.net/problem=" + strconv.Itoa(problemNumber)

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

	err := c.Visit(url)
	if err != nil {
		return nil, err
	}

	return &problem, nil
}
