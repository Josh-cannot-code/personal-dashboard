package google

import (
	"context"
	"fmt"
	"github.com/samber/lo"
	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/googleapi"
	"google.golang.org/api/option"
	"os"
	"sort"
	"strings"
	"time"
)

const calendarId = "j.dallacqua1@gmail.com"

var dayMap = map[string]string{
	"MO": "Mon",
	"TU": "Tue",
	"WE": "Wed",
	"TH": "Thu",
	"FR": "Fri",
	"SA": "Sat",
	"SU": "Sun",
}

func getOauth(ctx context.Context) (*oauth2.Config, *oauth2.Token, error) {
	token := new(oauth2.Token)
	token.AccessToken = ""
	token.RefreshToken = os.Getenv("OAUTH_REFRESH_TOKEN")
	config := oauth2.Config{
		ClientID:     os.Getenv("OAUTH_CLIENT_ID"),
		ClientSecret: os.Getenv("OAUTH_CLIENT_SECRET"),
		Endpoint: oauth2.Endpoint{
			AuthURL:  "https://accounts.google.com/o/oauth2/v2/auth",
			TokenURL: "https://oauth2.googleapis.com/token",
		},
		RedirectURL: "",
		Scopes:      []string{},
	}
	tokenSource := config.TokenSource(ctx, token)
	newToken, err := tokenSource.Token()
	if err != nil {
		return nil, nil, err
	}
	return &config, newToken, nil
}

type calendarEvent struct {
	Name      string `json:"name"`
	Date      int    `json:"date"`
	StartTime int    `json:"startTime"`
	EndTime   int    `json:"endTime"`
	Frequency string `json:"frequency"`
}

func getUpcomingCalendarEvents(ctx context.Context) ([]*calendarEvent, error) {
	config, token, err := getOauth(ctx)
	if err != nil {
		return nil, err
	}
	calendarService, err := calendar.NewService(ctx, option.WithTokenSource(config.TokenSource(ctx, token)))
	if err != nil {
		return nil, err
	}

	events, err := calendarService.Events.List(calendarId).Do(googleapi.QueryParameter("timeMin", time.Now().Format(time.RFC3339)))
	if err != nil {
		return nil, err
	}

	fmt.Println(len(events.Items))
	var calendarEvents []*calendarEvent
	for i, item := range events.Items {
		if i > 5 {
			break
		} else if item.Status == "cancelled" {
			continue
		}

		var date, start, end int
		if item.Start.Date != "" {
			dateDate, err := time.Parse("2006-01-02", item.Start.Date)
			if err != nil {
				return nil, err
			}
			date = int(dateDate.UTC().UnixMilli())
			start = 0
			end = 0
		} else {
			startDate, err := time.Parse(time.RFC3339, item.Start.DateTime)
			if err != nil {
				return nil, err
			}
			endDate, err := time.Parse(time.RFC3339, item.End.DateTime)
			if err != nil {
				return nil, err
			}
			start = int(startDate.UTC().UnixMilli())
			end = int(endDate.UTC().UnixMilli())
			date = 0
		}

		var frequency string
		if item.Recurrence != nil {
			frequency = item.Recurrence[0]
			freqList := strings.Split(frequency, ";")
			freqList = lo.Filter(freqList, func(s string, _ int) bool {
				return strings.HasPrefix(s, "BYDAY") || strings.HasPrefix(s, "RRULE")
			})
			frequency = strings.Split(lo.Reverse(freqList)[0], "=")[1]
			if len(freqList) == 1 {
				frequency = strings.ToLower(frequency)
			} else {
				days := strings.Split(frequency, ",")
				frequency = lo.Reduce(days, func(acc string, s string, _ int) string {
					return acc + " " + dayMap[s]
				}, "")
			}
		}
		if date == 0 {
			date = start
		}
		calendarEvents = append(calendarEvents, &calendarEvent{
			Name:      item.Summary,
			Date:      date,
			StartTime: start,
			EndTime:   end,
			Frequency: frequency,
		})
	}
	now := int(time.Now().UnixMilli())
	calendarEvents = lo.Filter(calendarEvents, func(event *calendarEvent, _ int) bool {
		return event.Date > now
	})
	sort.Slice(calendarEvents, func(i, j int) bool {
		return calendarEvents[i].Date < calendarEvents[j].Date
	})
	return calendarEvents, nil
}
