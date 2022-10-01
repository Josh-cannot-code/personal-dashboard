module Main exposing (..)

import Activity
    exposing
        ( Activity
        , ActivityResponse
        , activityPostEncoder
        , activityResponseDecoder
        )
import Array exposing (..)
import Browser
import DateFormat
import Google
    exposing
        ( Event
        , eventListDecoder
        )
import Html exposing (..)
import Html.Attributes exposing (class, href, style, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Parser
import Html.Parser.Util
import Http
import ProjectEuler
    exposing
        ( EulerProblem
        , eulerProblemDecoder
        , eulerProblemEncoder
        )
import Random exposing (..)
import Task
import Time


type alias Link =
    ( String, String )


type alias Visible =
    { activityList : Bool
    , eulerHtml : Bool
    }


type alias Model =
    { activities : Array Activity
    , eulerProblem : EulerProblem
    , events : List Event
    , index : Int
    , activityForum : String
    , links : List Link
    , zone : Time.Zone
    , time : Time.Posix
    , apiUrl : String
    , visible : Visible
    }


init : String -> ( Model, Cmd Msg )
init url =
    ( { activities = Array.fromList []
      , events = []
      , index = 0
      , activityForum = ""
      , links =
            [ ( "Calendar", "https://calendar.google.com/calendar/u/2/r" )
            , ( "MyCourses", "https://mycourses2.mcgill.ca/d2l/home" )
            , ( "GitHub", "https://github.com/Josh-cannot-code" )
            ]
      , time = Time.millisToPosix 0
      , zone = Time.utc
      , apiUrl = url
      , eulerProblem = { id = "", number = 0, name = "", html = "" }
      , visible = { activityList = False, eulerHtml = False }
      }
    , Cmd.batch
        [ Task.perform AdjustTimeZone Time.here
        , getActivities url
        , getCurrentEulerProblem url
        , getEvents url
        ]
    )


type Msg
    = GenerateRandomNumber
    | NewRandomNumber Int
    | AdjustTimeZone Time.Zone
    | Tick Time.Posix
    | GetActivitiesRequest
    | GetActivitiesResponse (Result Http.Error ActivityResponse)
    | InsertActivityRequest Activity
    | PostActivityResponse (Result Http.Error String)
    | UpdateForm String
    | DeleteActivityRequest Activity
    | GetEulerProblem EulerProblem
    | GetEulerResponse (Result Http.Error EulerProblem)
    | NextEulerProblem
    | PrevEulerProblem
    | ChangeEulerResponse (Result Http.Error String)
    | ToggleEulerVisibility
    | ToggleActivityList
    | GetEventsRequest
    | GetEventsResponse (Result Http.Error (List Event))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GenerateRandomNumber ->
            ( model
            , Array.length model.activities
                - 1
                |> Random.int 0
                |> Random.generate NewRandomNumber
            )

        NewRandomNumber number ->
            ( { model | index = number }
            , Cmd.none
            )

        Tick newTime ->
            ( { model | time = newTime }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )

        UpdateForm text ->
            ( { model | activityForum = text }, Cmd.none )

        GetActivitiesRequest ->
            ( model, getActivities model.apiUrl )

        GetActivitiesResponse (Ok actResp) ->
            ( { model | activities = Array.fromList actResp.activities }, Cmd.none )

        GetActivitiesResponse (Err _) ->
            ( model, Cmd.none )

        InsertActivityRequest activity ->
            ( model, postActivityRequest activity "insert" model.apiUrl )

        PostActivityResponse (Ok _) ->
            ( { model | activityForum = "" }, getActivities model.apiUrl )

        PostActivityResponse (Err _) ->
            ( { model | activityForum = "" }, Cmd.none )

        DeleteActivityRequest activity ->
            ( model, postActivityRequest activity "delete" model.apiUrl )

        GetEulerProblem problem ->
            ( model, getCurrentEulerProblem model.apiUrl )

        GetEulerResponse (Ok newEp) ->
            ( { model | eulerProblem = newEp }, Cmd.none )

        GetEulerResponse (Err _) ->
            ( { model | eulerProblem = { id = "err", number = 0, name = "err", html = "err" } }, Cmd.none )

        NextEulerProblem ->
            ( model, changeEulerProblem model.eulerProblem "next" model.apiUrl )

        PrevEulerProblem ->
            ( model, changeEulerProblem model.eulerProblem "prev" model.apiUrl )

        ChangeEulerResponse (Ok _) ->
            ( model, getCurrentEulerProblem model.apiUrl )

        ChangeEulerResponse (Err _) ->
            ( model, Cmd.none )

        ToggleEulerVisibility ->
            let
                curVisible =
                    model.visible
            in
            ( { model | visible = { curVisible | eulerHtml = not model.visible.eulerHtml } }, Cmd.none )

        ToggleActivityList ->
            let
                curVisible =
                    model.visible
            in
            ( { model | visible = { curVisible | activityList = not model.visible.activityList } }, Cmd.none )

        GetEventsRequest ->
            ( model, getEvents model.apiUrl )

        GetEventsResponse (Ok events) ->
            ( { model | events = events }, Cmd.none )

        GetEventsResponse (Err err) ->
            ( { model | activityForum = "err" }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1000 Tick


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "row mt-5" ]
            [ div [ class "col" ]
                [ linksCard model.links |> columnCard
                , currentEulerProblem model
                ]
            , div [ class "col" ]
                [ activityCard model |> columnCard
                , eventsCard model
                ]
            , div [ class "col text-center" ]
                [ timeCard model |> columnCard
                , lookingToHireCard
                ]
            ]
        ]


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


columnCard : Html Msg -> Html Msg
columnCard html =
    div [ class "mb-3" ] [ html ]


timeCard : Model -> Html Msg
timeCard model =
    let
        timeOfDay =
            DateFormat.format
                [ DateFormat.hourMilitaryFixed
                , DateFormat.text ":"
                , DateFormat.minuteFixed
                ]
                model.zone
                model.time

        date =
            DateFormat.format
                [ DateFormat.monthNameFull
                , DateFormat.text " "
                , DateFormat.dayOfMonthSuffix
                , DateFormat.text ", "
                , DateFormat.yearNumber
                ]
                model.zone
                model.time
    in
    div [ class "card" ]
        [ div [ class "card-body" ]
            [ p [ class "fs-5" ] [ text timeOfDay ]
            , p [ class "fs-5" ] [ text date ]
            ]
        ]


activityCard : Model -> Html Msg
activityCard model =
    let
        activityList =
            if model.visible.activityList then
                div []
                    [ listActivities model
                    , button [ class "btn btn-sm btn-primary float-start", onClick ToggleActivityList ] [ text "hide activities" ]
                    ]

            else
                div []
                    [ button [ class "btn btn-sm btn-primary float-start", onClick ToggleActivityList ] [ text "show activities" ] ]
    in
    div [ class "card" ]
        [ div [ class "card-title text-center pt-3" ] [ h5 [] [ text "Activity Generator" ] ]
        , div [ class "card-body text-center" ]
            [ div []
                [ p [ class "fs-5 fw-bolder" ] [ getActivityByIndex model |> text ]
                , button [ class "btn btn-sm btn-primary", onClick GenerateRandomNumber ] [ text "New Activity" ]
                ]
            , div [ class "input-group m-2" ]
                [ input [ class "form-control me-2", type_ "text", value model.activityForum, onInput UpdateForm ] []
                , button
                    [ class "btn btn-sm btn-primary"
                    , onClick (InsertActivityRequest { name = model.activityForum, id = "" })
                    ]
                    [ text "Add Activity" ]
                ]
            , activityList
            ]
        ]


listActivities : Model -> Html Msg
listActivities model =
    let
        listElement : Activity -> Html Msg
        listElement a =
            li [ class "list-group-item" ]
                [ text a.name
                , button [ class "btn btn-sm btn-danger float-end", onClick (DeleteActivityRequest a) ] [ text "Delete" ]
                ]
    in
    div [ class "p-1" ]
        [ List.map listElement (Array.toList model.activities)
            |> ul [ class "list-group-flush text-start justify-content-between" ]
        ]


currentEulerProblem : Model -> Html Msg
currentEulerProblem model =
    let
        html =
            case Html.Parser.run model.eulerProblem.html of
                Ok nodeList ->
                    Html.Parser.Util.toVirtualDom nodeList

                Err _ ->
                    [ text "error parsing html from project euler" ]

        content =
            if model.visible.eulerHtml then
                html
                    ++ [ button [ class "btn-sm btn btn-primary", onClick ToggleEulerVisibility ] [ text "hide problem" ] ]

            else
                [ button [ class "btn btn-sm btn-primary", onClick ToggleEulerVisibility ] [ text "view problem" ] ]
    in
    div [ class "card" ]
        [ h4 [ class "card-title pt-3 ps-3" ] [ text "Current Project Euler Problem" ]
        , h5 [ class "card-subtitle text-muted ps-3" ] [ text (model.eulerProblem.name ++ " (Problem " ++ String.fromInt model.eulerProblem.number ++ ")") ]
        , div [ class "card-body" ] content
        , div [ class "card-body" ]
            [ button [ class "btn btn-primary", onClick PrevEulerProblem ] [ text "prev" ]
            , button [ class "btn btn-primary float-end", onClick NextEulerProblem ] [ text "next" ]
            ]
        ]


lookingToHireCard : Html Msg
lookingToHireCard =
    div [ class "card" ]
        [ h5 [ class "card-title p-3" ] [ text "Looking to Hire Me?" ]
        , div [ class "card-body" ]
            [ button [ class "btn btn-primary" ] [ text "Click Here!" ]
            ]
        ]


linksCard : List Link -> Html Msg
linksCard links =
    let
        createLi : Link -> Html Msg
        createLi link =
            li [ class "nav-item w-80 p-1" ]
                [ a [ class "nav-link active text-dark", Tuple.second link |> href, target "_blank" ] [ Tuple.first link |> text ]
                ]
    in
    div [ class "card text-center" ]
        [ div [ class "card-title pt-3" ] [ h5 [] [ text "Links" ] ]
        , div [ class "card-body" ]
            [ List.map createLi links
                |> ul [ class "nav flex-column nav-pills" ]
            ]
        ]


eventItem : Time.Zone -> Event -> Html Msg
eventItem zone event =
    let
        eventDateProcessor : Int -> Int -> Int -> Html Msg
        eventDateProcessor date start end =
            if date /= 0 then
                div []
                    [ DateFormat.format
                        [ DateFormat.monthNameAbbreviated
                        , DateFormat.text " "
                        , DateFormat.dayOfMonthSuffix
                        , DateFormat.text ", "
                        , DateFormat.yearNumber
                        ]
                        zone
                        (Time.millisToPosix date)
                        |> text
                    ]

            else
                div []
                    [ DateFormat.format
                        [ DateFormat.monthNameAbbreviated
                        , DateFormat.text " "
                        , DateFormat.dayOfMonthSuffix
                        , DateFormat.text ", "
                        , DateFormat.yearNumber
                        ]
                        zone
                        (Time.millisToPosix start)
                        |> text
                    , br [] []
                    , DateFormat.format
                        [ DateFormat.hourMilitaryFixed
                        , DateFormat.text ":"
                        , DateFormat.minuteFixed
                        ]
                        zone
                        (Time.millisToPosix start)
                        |> text
                    , text " - "
                    , DateFormat.format
                        [ DateFormat.hourMilitaryFixed
                        , DateFormat.text ":"
                        , DateFormat.minuteFixed
                        ]
                        zone
                        (Time.millisToPosix end)
                        |> text
                    ]

        frequency : Html Msg
        frequency =
            if event.frequency /= "" then
                text event.frequency

            else
                text ""
    in
    li [ class "list-group-item" ]
        [ div []
            [ h6 [] [ text event.name ]
            , div [ class "text-end" ]
                [ eventDateProcessor event.date event.startTime event.endTime
                , frequency
                ]
            ]
        ]


eventsCard : Model -> Html Msg
eventsCard model =
    div [ class "card" ]
        [ div [ class "card-title pt-3 ps-3" ] [ h5 [] [ text "Upcoming Events" ] ]
        , div [ class "card-body" ]
            [ List.map (eventItem model.zone) model.events |> ul [ class "list-group" ] ]
        ]


getActivityByIndex : Model -> String
getActivityByIndex model =
    let
        activity =
            Array.get model.index model.activities
    in
    case activity of
        Just a ->
            a.name

        Nothing ->
            ""


getActivities : String -> Cmd Msg
getActivities url =
    Http.get
        { url = "http://" ++ url ++ "/activities/get"
        , expect = Http.expectJson GetActivitiesResponse activityResponseDecoder
        }


postActivityRequest : Activity -> String -> String -> Cmd Msg
postActivityRequest activity action url =
    Http.post
        { url = "http://" ++ url ++ "/activities/" ++ action
        , body = Http.jsonBody (activityPostEncoder activity)
        , expect = Http.expectString PostActivityResponse
        }


getCurrentEulerProblem : String -> Cmd Msg
getCurrentEulerProblem url =
    Http.get
        { url = "http://" ++ url ++ "/project-euler/get-problem"
        , expect = Http.expectJson GetEulerResponse eulerProblemDecoder
        }


changeEulerProblem : EulerProblem -> String -> String -> Cmd Msg
changeEulerProblem problem direction url =
    Http.post
        { url = "http://" ++ url ++ "/project-euler/" ++ direction
        , body = Http.jsonBody (eulerProblemEncoder problem)
        , expect = Http.expectString ChangeEulerResponse
        }


getEvents : String -> Cmd Msg
getEvents url =
    Http.get
        { url = "http://" ++ url ++ "/google/calendar"
        , expect = Http.expectJson GetEventsResponse eventListDecoder
        }
