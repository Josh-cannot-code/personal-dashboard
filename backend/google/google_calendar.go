package google

import (
	"context"
	"fmt"
	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/googleapi"
	"google.golang.org/api/option"
	"os"
	"time"
)

const calendarId = "j.dallacqua1@gmail.com"

func getOauth(ctx context.Context) (*oauth2.Config, *oauth2.Token, error) {
	accessToken := os.Getenv("OAUTH_ACCESS_TOKEN")
	refreshToken := os.Getenv("OAUTH_REFRESH_TOKEN")

	token := new(oauth2.Token)
	token.AccessToken = accessToken
	token.RefreshToken = refreshToken
	config := oauth2.Config{
		ClientID:     os.Getenv("OAUTH_CLIENT_ID"),
		ClientSecret: os.Getenv("OAUTH_CLIENT_SECRET"),
		Endpoint:     oauth2.Endpoint{},
		RedirectURL:  "",
		Scopes:       []string{refreshToken},
	}
	tokenSource := config.TokenSource(ctx, token)
	newToken, err := tokenSource.Token()
	if err != nil {
		return nil, nil, err
	}
	if newToken.AccessToken != token.AccessToken {
		// Save Token
	}
	return &config, token, nil
}

type calendarEvent struct {
	Name      string   `json:"name"`
	Date      string   `json:"date"`
	StartTime string   `json:"startTime"`
	EndTime   string   `json:"endTime"`
	Frequency []string `json:"frequency"`
}

func GetUpcomingCalendarEvents(ctx context.Context) error {
	config, token, err := getOauth(ctx)
	if err != nil {
		return err
	}
	calendarService, err := calendar.NewService(ctx, option.WithTokenSource(config.TokenSource(ctx, token)))
	if err != nil {
		return err
	}

	/*
		calendarList, err := calendarService.CalendarList.List().Do()
		if err != nil {
			return err
		}
		for _, cal := range calendarList.Items {
			fmt.Println(cal.Id)
		}
		myCalendar, err := calendarService.Calendars.Get(calendarId).Do()
		if err != nil {
			return err
		}
		// TODO: check status code
		fmt.Println(myCalendar.Summary)
	*/
	events, err := calendarService.Events.List(calendarId).Do(googleapi.QueryParameter("timeMin", time.Now().Format(time.RFC3339)))
	if err != nil {
		return err
	}

	fmt.Println(len(events.Items))
	var calendarEvents []*calendarEvent
	for i, item := range events.Items {
		if i > 6 {
			break
		} else if item.Status == "cancelled" {
			continue
		}
		startDay := item.Start.Date
		calendarEvents = append(calendarEvents, &calendarEvent{
			Name:      item.Summary,
			Date:      startDay,
			StartTime: item.Start.DateTime,
			EndTime:   item.End.DateTime,
			Frequency: item.Recurrence,
		})
		fmt.Println(item.Summary)
	}
	for _, evt := range calendarEvents {
		fmt.Println(*evt)
	}

	return nil
}
