module Google exposing (..)

import Json.Decode as JD


type alias Event =
    { name : String
    , date : Int
    , startTime : Int
    , endTime : Int
    , frequency : String
    }


eventListDecoder : JD.Decoder (List Event)
eventListDecoder =
    JD.list eventDecoder


eventDecoder : JD.Decoder Event
eventDecoder =
    JD.map5 Event
        (JD.field "name" JD.string)
        (JD.field "date" JD.int)
        (JD.field "startTime" JD.int)
        (JD.field "endTime" JD.int)
        (JD.field "frequency" JD.string)
