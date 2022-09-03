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
import Html exposing (..)
import Html.Attributes exposing (class, href, style, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Parser
import Html.Parser.Util
import Http
import ProjectEuler exposing (EulerProblem, eulerProblemDecoder, eulerProblemEncoder)
import Random exposing (..)
import Task
import Time


type alias Link =
    ( String, String )


type alias Model =
    { activities : Array Activity
    , index : Int
    , activityForm : String
    , links : List Link
    , zone : Time.Zone
    , time : Time.Posix
    , apiUrl : String
    , eulerProblem : EulerProblem
    }


init : ( String, Int ) -> ( Model, Cmd Msg )
init ( url, ep ) =
    ( { activities = Array.fromList []
      , index = 0
      , activityForm = ""
      , links =
            [ ( "Calendar", "https://calendar.google.com/calendar/u/2/r" )
            , ( "MyCourses", "https://mycourses2.mcgill.ca/d2l/home" )
            , ( "GitHub", "https://github.com" )
            ]
      , time = Time.millisToPosix 0
      , zone = Time.utc
      , apiUrl = url
      , eulerProblem = { id = 0, name = "", html = "" }
      }
    , Cmd.batch [ Task.perform AdjustTimeZone Time.here, getActivities url, getCurrentEulerProblem { id = ep, name = "", html = "" } url ]
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
            ( { model | activityForm = text }, Cmd.none )

        GetActivitiesRequest ->
            ( model, getActivities model.apiUrl )

        GetActivitiesResponse (Ok actResp) ->
            ( { model | activities = Array.fromList actResp.activities }, Cmd.none )

        GetActivitiesResponse (Err _) ->
            ( model, Cmd.none )

        InsertActivityRequest activity ->
            ( model, postActivityRequest activity "insert" model.apiUrl )

        PostActivityResponse (Ok _) ->
            ( { model | activityForm = "" }, getActivities model.apiUrl )

        PostActivityResponse (Err _) ->
            ( { model | activityForm = "" }, Cmd.none )

        DeleteActivityRequest activity ->
            ( model, postActivityRequest activity "delete" model.apiUrl )

        GetEulerProblem problem ->
            ( model, getCurrentEulerProblem problem model.apiUrl )

        GetEulerResponse (Ok newEp) ->
            ( { model | eulerProblem = newEp }, Cmd.none )

        GetEulerResponse (Err _) ->
            ( { model | eulerProblem = { id = 0, name = "err", html = "err" } }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1000 Tick


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "row", style "padding" "1ex", style "padding-top" "10ex" ]
            [ div [ class "col" ]
                [ displayLinks model.links
                ]
            , div [ class "col" ]
                [ activityCard model ]
            , div [ class "col text-center" ]
                [ timeCard model ]
            ]
        , div [ class "row", style "padding" "1ex" ]
            [ div [ class "col" ] []
            , div [ class "col" ] [ currentEulerProblem model ]
            ]
        ]


main : Program ( String, Int ) Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


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
    div [ class "card" ]
        [ div [ class "card-body text-center" ]
            [ p [ class "fs-5" ] [ getActivityByIndex model |> text ]
            , button [ class "btn btn-primary", onClick GenerateRandomNumber ] [ text "New Activity" ]
            , div [ class "input-group", style "padding" "0.5ex" ]
                [ input [ class "form-control", type_ "text", value model.activityForm, onInput UpdateForm ] []
                ]
            , button [ class "btn btn-primary", onClick (InsertActivityRequest { name = model.activityForm, id = "" }) ] [ text "Add Activity" ]
            , listActivities model
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
    div [ style "padding" "0.5ex" ]
        [ List.map listElement (Array.toList model.activities)
            |> ul [ class "list-group-flush text-start justify-content-between" ]
        ]


currentEulerProblem : Model -> Html Msg
currentEulerProblem model =
    let
        content =
            case Html.Parser.run model.eulerProblem.html of
                Ok nodeList ->
                    Html.Parser.Util.toVirtualDom nodeList

                Err _ ->
                    [ text "error parsing html from project euler" ]
    in
    div [ class "card" ]
        [ h4 [ class "card-title", style "padding-top" "1ex", style "padding-left" "1ex" ] [ text "Current Project Euler Problem" ]
        , h5 [ class "card-subtitle text-muted", style "padding-left" "2ex" ] [ text (model.eulerProblem.name ++ " (Problem " ++ String.fromInt model.eulerProblem.id ++ ")") ]
        , div [ class "card-body" ] content
        , div [ class "card-body" ]
            [ button [ class "btn btn-primary", onClick (GetEulerProblem { id = model.eulerProblem.id - 1, name = "", html = "" }) ] [ text "prev" ]
            , button [ class "btn btn-primary float-end", onClick (GetEulerProblem { id = model.eulerProblem.id + 1, name = "", html = "" }) ] [ text "next" ]
            ]
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


displayLinks : List Link -> Html Msg
displayLinks links =
    let
        createLi : Link -> Html Msg
        createLi link =
            li [ class "nav-item w-50", style "padding" "0.5ex" ]
                [ a [ class "nav-link active", Tuple.second link |> href, target "_blank" ] [ Tuple.first link |> text ]
                ]
    in
    List.map createLi links
        |> ul [ class "nav flex-column nav-pills" ]


getActivities : String -> Cmd Msg
getActivities url =
    Http.get
        { url = "http://" ++ url ++ "/activities/get"
        , expect = Http.expectJson GetActivitiesResponse activityResponseDecoder
        }


postActivityRequest : Activity -> String -> String -> Cmd Msg
postActivityRequest activity action url =
    Http.post
        { url = "http://" ++ url ++ "/activities/post"
        , body = Http.jsonBody (activityPostEncoder activity action)
        , expect = Http.expectString PostActivityResponse
        }


getCurrentEulerProblem : EulerProblem -> String -> Cmd Msg
getCurrentEulerProblem problem url =
    Http.post
        { url = "http://" ++ url ++ "/project-euler/get-problem"
        , body = Http.jsonBody (eulerProblemEncoder problem)
        , expect = Http.expectJson GetEulerResponse eulerProblemDecoder
        }
