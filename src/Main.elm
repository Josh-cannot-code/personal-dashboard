module Main exposing (..)

import Array exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (class, href, style, target)
import Html.Events exposing (onClick)
import Random exposing (..)
import Time
import Task


type alias Link =
    ( String, String )


type alias Model =
    { activities : Array String
    , index : Int
    , links : List Link
    , zone : Time.Zone
    , time : Time.Posix
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { activities = Array.fromList
    [ "Read"
    , "Bonsai"
    , "Workout"
    , "Work on site"
    , "Guitar"
    , "Plant watering system" ]
      , index = 0
      , links =
            [ ( "Calendar", "https://calendar.google.com/calendar/u/2/r" )
            , ( "MyCourses", "https://mycourses2.mcgill.ca/d2l/home" )
            , ( "GitHub", "https://github.com" )
            ]
      , time = Time.millisToPosix 0
      , zone = Time.utc
      }
    , Task.perform AdjustTimeZone Time.here
    )


type Msg
    = GenerateRandomNumber
    | NewRandomNumber Int
    | AdjustTimeZone Time.Zone
    | Tick Time.Posix


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

subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1000 Tick

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

generateActivityCard : Model -> Html Msg
generateActivityCard model =
    div [ class "card" ]
        [
         div [ class "card-body" ]
            [ p [ class "fs-5" ] [ getActivityByIndex model |> text ]
            , button [ class "btn btn-primary", onClick GenerateRandomNumber ] [ text "New Activity" ]
            ]
        ]


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

getActivityByIndex : Model -> String
getActivityByIndex model =
    let
        activity =
            Array.get model.index model.activities
    in
    case activity of
        Just a ->
            a

        Nothing ->
            ""

view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "row", style "padding" "1ex", style "padding-top" "10ex" ]
            [ div [ class "col" ]
                [ displayLinks model.links
                ]
            , div [ class "col text-center" ]
                [ generateActivityCard model ]
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