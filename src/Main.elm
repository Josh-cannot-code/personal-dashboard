module Main exposing (..)

import Array exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (class, href, style, target)
import Html.Events exposing (onClick)
import Random exposing (..)


type alias Link =
    ( String, String )


type alias Model =
    { activities : Array String
    , index : Int
    , links : List Link
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( { activities = Array.fromList [ "Read", "Bonsai", "Workout", "Work on site", "Guitar" ]
      , index = 0
      , links =
            [ ( "Calendar", "https://calendar.google.com/calendar/u/2/r" )
            , ( "MyCourses", "https://mycourses2.mcgill.ca/d2l/home" )
            , ( "GitHub", "https://github.com" )
            ]
      }
    , Cmd.none
    )


generateActivityCard : Model -> Html Msg
generateActivityCard model =
    div [ class "card" ]
        [ div [ class "card-header" ]
            [ h2 [] [ text "Free Time" ]
            ]
        , div [ class "card-body" ]
            [ p [ class "fs-5" ] [ getActivityByIndex model |> text ]
            , button [ class "btn btn-primary", onClick GenerateRandomNumber ] [ text "New Activity" ]
            ]
        ]


displayLinks : List Link -> Html Msg
displayLinks links =
    let
        createLi : Link -> Html Msg
        createLi link =
            li [ class "nav-item", style "padding" "0.5vh" ]
                [ a [ class "nav-link active", Tuple.second link |> href, target "_blank" ] [ Tuple.first link |> text ]
                ]
    in
    List.map createLi links
        |> ul [ class "nav flex-column nav-pills" ]


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "row", style "padding" "1vh" ]
            [ div [ class "col" ]
                [ displayLinks model.links
                ]
            , div [ class "col text-center" ]
                [ generateActivityCard model
                ]
            , div [ class "col" ] []
            ]
        ]


type Msg
    = GenerateRandomNumber
    | NewRandomNumber Int


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
            ( { activities = model.activities, index = number, links = model.links }, Cmd.none )


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


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
