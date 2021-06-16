module Backend.MigrateState_Root exposing (decodeMigrateAndEncodeAndSerializeResult, main)

import Backend.MigrateState
import Backend.MigrateState_Root.Generated_29573d99
import Backend.MigrateState_Root.Generated_29573d99
import Backend.State
import Base64
import Bytes
import Bytes.Decode
import Bytes.Encode
import Dict
import Json.Decode
import Json.Encode
import ListDict
import Set
import Json.Decode
import Json.Encode


decodeMigrateAndEncode : String -> Result String String
decodeMigrateAndEncode =
    Json.Decode.decodeString Backend.MigrateState_Root.Generated_29573d99.jsonDecode_747f613313
        >> Result.map (Backend.MigrateState.migrate >>  Backend.MigrateState_Root.Generated_29573d99.jsonEncode_747f613313 >> Json.Encode.encode 0)
        >> Result.mapError Json.Decode.errorToString


decodeMigrateAndEncodeAndSerializeResult : String -> String
decodeMigrateAndEncodeAndSerializeResult =
    decodeMigrateAndEncode
        >> jsonEncodeResult Json.Encode.string Json.Encode.string
        >> Json.Encode.encode 0


jsonEncodeResult : (err -> Json.Encode.Value) -> (ok -> Json.Encode.Value) -> Result err ok -> Json.Encode.Value
jsonEncodeResult encodeErr encodeOk valueToEncode =
    case valueToEncode of
        Err valueToEncodeError ->
            [ ( "Err", [ valueToEncodeError ] |> Json.Encode.list encodeErr ) ] |> Json.Encode.object

        Ok valueToEncodeOk ->
            [ ( "Ok", [ valueToEncodeOk ] |> Json.Encode.list encodeOk ) ] |> Json.Encode.object


main : Program Int {} String
main =
    Platform.worker
        { init = \_ -> ( {}, Cmd.none )
        , update =
            \_ _ ->
                ( decodeMigrateAndEncodeAndSerializeResult |> always {}, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
