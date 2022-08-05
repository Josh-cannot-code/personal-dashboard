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
import Html.Attributes exposing (class)
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
    Card.config []
        |> Card.header [ class "text-center" ]
            [ h2 [] [ text "Free Time" ]
            ]
        |> Card.block []
            [ Block.custom <| Button.button [ Button.primary, Button.onClick GenerateRandomNumber ] [ text "New Activity" ]
            , Block.text [] [ getActivityByIndex model |> text ]
            ]
        |> Card.view


view : Model -> Html Msg
view model =
    Grid.container []
        [ CDN.stylesheet
        , Grid.row
            [ Row.attrs [ Spacing.p4 ] ]
            [ Grid.col
                [ Col.textAlign Text.alignLgCenter ]
                [ generateActivityCard model ]
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
