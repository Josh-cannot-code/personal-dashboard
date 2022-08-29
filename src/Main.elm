module Main exposing (..)

import Array exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (class, href, style, target, value, type_)
import Html.Events exposing (onClick, onInput)
import Random exposing (..)
import Time
import Task
import Http
import Activity exposing
    ( Activity
    , ActivityResponse
    , activityResponseDecoder
    , activityPostEncoder)


type alias Link =
    ( String, String )


type alias Model =
    { activities : Array Activity
    , index : Int
    , activityForm : String
    , links : List Link
    , zone : Time.Zone
    , time : Time.Posix
    }


init : () -> ( Model, Cmd Msg )
init _ =
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
      }
    , Cmd.batch [Task.perform AdjustTimeZone Time.here, getActivities]
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
            ( {model | time = newTime}
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )

        UpdateForm text ->
            ( {model | activityForm = text} , Cmd.none )

        GetActivitiesRequest ->
            (model, getActivities)
        GetActivitiesResponse (Ok actResp) ->
           ({ model | activities = Array.fromList actResp.activities } , Cmd.none)
        GetActivitiesResponse (Err _) ->
           (model, Cmd.none)
        InsertActivityRequest activity ->
            (model, postActivityRequest activity "insert")
        PostActivityResponse (Ok _) ->
            ({ model | activityForm = ""}, getActivities)
        PostActivityResponse (Err _) ->
            ({ model | activityForm = ""}, Cmd.none)
        DeleteActivityRequest activity ->
            (model, postActivityRequest activity "delete")

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

        ]

main : Program () Model Msg
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
        hour = String.fromInt (Time.toHour model.zone model.time)
        minute = String.fromInt (Time.toMinute model.zone model.time)
    in
    div [ class "card"]
        [
            div [ class "card-body" ]
                [p [ class "fs-5" ] [text (hour ++ ":" ++ minute) ]]
        ]

activityCard : Model -> Html Msg
activityCard model =
    div [ class "card" ]
        [
         div [ class "card-body text-center" ]
            [ p [ class "fs-5" ] [ getActivityByIndex model |> text ]
            , button [ class "btn btn-primary", onClick GenerateRandomNumber ] [ text "New Activity" ]
            , div [class "input-group", style "padding" "0.5ex"] [
             input [class "form-control", type_ "text", value model.activityForm, onInput UpdateForm] []
             ]
            , button [ class "btn btn-primary", onClick (InsertActivityRequest { name = model.activityForm, id = ""}) ] [text "Add Activity"]
            , listActivities model
            ]
        ]

listActivities : Model -> Html Msg
listActivities model =
    let
        listElement : Activity -> Html Msg
        listElement a =
            li [class "list-group-item"] [
                text a.name
                , button [ class "btn btn-sm btn-danger float-end", onClick (DeleteActivityRequest a) ] [text "Delete"]
             ]
    in
    div [style "padding" "0.5ex"] [
        List.map listElement (Array.toList model.activities)
        |> ul [class "list-group-flush text-start justify-content-between"]
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



getActivities : Cmd Msg
getActivities =
    Http.get
        { url = "http://localhost:3001/activities/get"
        , expect = Http.expectJson GetActivitiesResponse activityResponseDecoder
        }

postActivityRequest : Activity -> String -> Cmd Msg
postActivityRequest activity action =
    Http.post
        { url = "http://localhost:3001/activities/post"
        , body = Http.jsonBody (activityPostEncoder activity action)
        , expect = Http.expectString PostActivityResponse
        }
