module ProjectEuler exposing (..)

import Json.Decode as JD
import Json.Encode as JE


type alias EulerProblem =
    { id : String
    , number : Int
    , name : String
    , html : String
    }


eulerProblemEncoder : EulerProblem -> JE.Value
eulerProblemEncoder problem =
    JE.object
        [ ( "id", JE.string problem.id )
        , ( "number", JE.int problem.number )
        , ( "name", JE.string problem.name )
        , ( "html", JE.string problem.html )
        ]


eulerProblemDecoder : JD.Decoder EulerProblem
eulerProblemDecoder =
    JD.map4 EulerProblem
        (JD.field "id" JD.string)
        (JD.field "number" JD.int)
        (JD.field "name" JD.string)
        (JD.field "html" JD.string)
