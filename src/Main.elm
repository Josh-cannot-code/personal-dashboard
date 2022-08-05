module Main exposing (..)
import Html exposing (..)
import Html.Events exposing (onClick)
import Browser exposing (sandbox)
import Array exposing (..)
import Random exposing (..)

type alias Model =
    {
        activities : Array String,
        index : Int
    }

init : () -> (Model, Cmd msg)
init _ = 
    ({
        activities = Array.fromList["sport", "not sport"],
        index = 0
    }, Cmd.none)

view : Model -> Html Msg
view model = 
    div [] 
    [ button [onClick GenerateRandomNumber] [ text "rando" ]
    , getActivityByIndex model |> text 
    ]

type Msg
    = GenerateRandomNumber
    | NewRandomNumber Int

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    case msg of 
        GenerateRandomNumber ->
            ( model,
            (Array.length model.activities) - 1
            |> Random.int 0 
            |> Random.generate NewRandomNumber)
        
        NewRandomNumber number -> 
            ( {activities = model.activities, index = number}, Cmd.none)

getActivityByIndex : Model -> String
getActivityByIndex model  = 
    let activity = Array.get model.index model.activities in
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