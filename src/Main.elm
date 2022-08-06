module Main exposing (..)

import Array exposing (..)
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Browser exposing (sandbox)
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Random exposing (..)


type alias Model =
    { activities : Array String
    , index : Int
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( { activities = Array.fromList [ "Read", "Bonsai", "Workout", "Work on site" ]
      , index = 0
      }
    , Cmd.none
    )

generateActivityCard : Model -> Html Msg
generateActivityCard model =
    div [ class "card"] [
        div [class "card-header"] [
            h2 [] [text "Free Time"]
        ]
        , div [ class "card-body" ] [
            button [ class "btn btn-primary", onClick GenerateRandomNumber ] [ text "New Activity"]
            , getActivityByIndex model |> text
        ]
    ]


view : Model -> Html Msg
view model =
    div [class "container"] [
        div [class "row text-center", style "padding" "1vh"] [
            div [ class "col" ] [
                generateActivityCard model
            ]
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
            ( { activities = model.activities, index = number }, Cmd.none )


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
