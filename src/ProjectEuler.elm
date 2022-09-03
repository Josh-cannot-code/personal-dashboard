module ProjectEuler exposing (..)

import Json.Decode as JD
import Json.Encode as JE


type alias EulerProblem =
    { id : Int
    , name : String
    , html : String
    }


eulerProblemEncoder : EulerProblem -> JE.Value
eulerProblemEncoder problem =
    JE.object
        [ ( "id", JE.int problem.id )
        , ( "name", JE.string problem.name )
        , ( "html", JE.string problem.html )
        ]


eulerProblemDecoder : JD.Decoder EulerProblem
eulerProblemDecoder =
    JD.map3 EulerProblem
        (JD.field "id" JD.int)
        (JD.field "name" JD.string)
        (JD.field "html" JD.string)
