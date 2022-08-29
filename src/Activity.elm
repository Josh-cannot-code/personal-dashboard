module Activity exposing (..)

import Json.Decode as JD
import Json.Encode as JE

type alias ActivityResponse =
    { activities : List Activity }

type alias Activity =
    { id : String
    , name : String
    }

activityStringEncoder : String -> JE.Value
activityStringEncoder activity =
    JE.object [("name", JE.string activity)]

activityResponseDecoder : JD.Decoder ActivityResponse
activityResponseDecoder =
    JD.map ActivityResponse
        (JD.field "activities" activityListDecoder)

activityDecoder : JD.Decoder Activity
activityDecoder =
    JD.map2 Activity
        (JD.field "id" JD.string)
        (JD.field "name" JD.string)

activityListDecoder : JD.Decoder (List Activity)
activityListDecoder =
    JD.list activityDecoder