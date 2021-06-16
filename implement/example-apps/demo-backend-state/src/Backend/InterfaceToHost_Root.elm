module Backend.InterfaceToHost_Root exposing
    ( State
    , interfaceToHost_deserializeState
    , interfaceToHost_initState
    , interfaceToHost_processEvent
    , interfaceToHost_serializeState
    , main
    )

import Backend.Main
import Backend.InterfaceToHost_Root.Generated_29573d99
import Base64
import Dict
import Set
import Json.Decode
import Json.Encode
import Bytes
import Bytes.Decode
import Bytes.Encode
import Backend.State
import ListDict
import Platform

type alias DeserializedState =
    ({ httpRequestsCount : Int, lastHttpRequests : ( List { httpRequestId : String, posixTimeMilli : Int, requestContext : { clientAddress : ( Maybe String ) }, request : { method : String, uri : String, bodyAsBase64 : ( Maybe String ), headers : ( List { name : String, values : ( List String ) } ) } } ), tuple2 : (Int, String), tuple3 : (Int, String, Int), list_custom_type : ( List Backend.State.CustomType ), opaque_custom_type : Backend.State.OpaqueCustomType, recursive_type : Backend.State.RecursiveType, bool : Bool, maybe : ( Maybe String ), result : ( Result String Int ), set : ( Set.Set Int ), dict : ( Dict.Dict Int String ), empty_record : {  }, empty_tuple : (), customTypeInstance : ( Backend.State.CustomTypeWithTypeParameter Int ), listDict : ( ListDict.Dict { orig : Int, dest : Int } String ), bytes : Bytes.Bytes })


type State
    = DeserializeFailed String
    | DeserializeSuccessful DeserializedState


interfaceToHost_initState = Backend.Main.interfaceToHost_initState |> DeserializeSuccessful


interfaceToHost_processEvent hostEvent stateBefore =
    case stateBefore of
        DeserializeFailed _ ->
            ( stateBefore, "[]" )

        DeserializeSuccessful deserializedState ->
            deserializedState
                |> Backend.Main.interfaceToHost_processEvent hostEvent
                |> Tuple.mapFirst DeserializeSuccessful


interfaceToHost_serializeState = jsonEncodeState >> Json.Encode.encode 0


interfaceToHost_deserializeState = deserializeState


-- Support function-level dead code elimination (https://elm-lang.org/blog/small-assets-without-the-headache) Elm code needed to inform the Elm compiler about our entry points.


main : Program Int State String
main =
    Platform.worker
        { init = \_ -> ( interfaceToHost_initState, Cmd.none )
        , update =
            \event stateBefore ->
                interfaceToHost_processEvent event (stateBefore |> interfaceToHost_serializeState |> interfaceToHost_deserializeState) |> Tuple.mapSecond (always Cmd.none)
        , subscriptions = \_ -> Sub.none
        }


-- Inlined helpers -->


{-| Turn a `Result e a` to an `a`, by applying the conversion
function specified to the `e`.
-}
result_Extra_Extract : (e -> a) -> Result e a -> a
result_Extra_Extract f x =
    case x of
        Ok a ->
            a

        Err e ->
            f e


-- Remember and communicate errors from state deserialization -->


jsonEncodeState : State -> Json.Encode.Value
jsonEncodeState state =
    case state of
        DeserializeFailed error ->
            [ ( "Interface_DeserializeFailed", [ ( "error", error |> Json.Encode.string ) ] |> Json.Encode.object ) ] |> Json.Encode.object

        DeserializeSuccessful deserializedState ->
            deserializedState |> jsonEncodeDeserializedState


deserializeState : String -> State
deserializeState serializedState =
    serializedState
        |> Json.Decode.decodeString jsonDecodeState
        |> Result.mapError Json.Decode.errorToString
        |> result_Extra_Extract DeserializeFailed


jsonDecodeState : Json.Decode.Decoder State
jsonDecodeState =
    Json.Decode.oneOf
        [ Json.Decode.field "Interface_DeserializeFailed" (Json.Decode.field "error" Json.Decode.string |> Json.Decode.map DeserializeFailed)
        , jsonDecodeDeserializedState |> Json.Decode.map DeserializeSuccessful
        ]

jsonEncodeDeserializedState =
    Backend.InterfaceToHost_Root.Generated_29573d99.jsonEncode_747f613313

jsonDecodeDeserializedState =
    Backend.InterfaceToHost_Root.Generated_29573d99.jsonDecode_747f613313