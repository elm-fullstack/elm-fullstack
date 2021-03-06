module Backend.Main exposing
    ( State
    , interfaceToHost_initState
    , interfaceToHost_processEvent
    )

import Backend.InterfaceToHost as InterfaceToHost
import Backend.Route
import Backend.VolatileHost as VolatileHost
import Base64
import Bytes.Encode
import Common
import CompilationInterface.ElmMake
import CompilationInterface.SourceFiles
import Dict
import Flate
import MonacoHtml
import Set
import Url


type alias State =
    { posixTimeMilli : Int
    , volatileHostsIds : Set.Set String
    , pendingHttpRequests : List InterfaceToHost.HttpRequestEventStructure
    , pendingTasksForRequestVolatileHost : Dict.Dict String { volatileHostId : String, startPosixTimeMilli : Int }
    }


parallelVolatileHostsCount : Int
parallelVolatileHostsCount =
    3


requestToVolatileHostTimeoutMilliseconds : Int
requestToVolatileHostTimeoutMilliseconds =
    1000 * 30


processEvent : InterfaceToHost.AppEvent -> State -> ( State, InterfaceToHost.AppEventResponse )
processEvent hostEvent stateBefore =
    let
        ( ( state, tasks ), responseBeforeTasks ) =
            processEventBeforeCreatingTasks hostEvent stateBefore
                |> Tuple.mapFirst processEventPartCreateTasks
    in
    ( state
    , responseBeforeTasks |> InterfaceToHost.withStartTasksAdded tasks
    )


processEventPartCreateTasks : State -> ( State, List InterfaceToHost.StartTaskStructure )
processEventPartCreateTasks stateBefore =
    let
        tasks =
            tasksFromState stateBefore

        newPendingTasksForRequestVolatileHost =
            tasks
                |> List.filterMap
                    (\task ->
                        case task.task of
                            InterfaceToHost.RequestToVolatileHost requestToVolatileHost ->
                                Just
                                    ( task.taskId
                                    , { startPosixTimeMilli = stateBefore.posixTimeMilli
                                      , volatileHostId = requestToVolatileHost.hostId
                                      }
                                    )

                            _ ->
                                Nothing
                    )
                |> Dict.fromList

        pendingTasksForRequestVolatileHost =
            stateBefore.pendingTasksForRequestVolatileHost
                |> Dict.union newPendingTasksForRequestVolatileHost
    in
    ( { stateBefore | pendingTasksForRequestVolatileHost = pendingTasksForRequestVolatileHost }
    , tasks
    )


processEventBeforeCreatingTasks : InterfaceToHost.AppEvent -> State -> ( State, InterfaceToHost.AppEventResponse )
processEventBeforeCreatingTasks hostEvent stateBefore =
    case hostEvent of
        InterfaceToHost.ArrivedAtTimeEvent { posixTimeMilli } ->
            ( { stateBefore | posixTimeMilli = posixTimeMilli }
            , InterfaceToHost.passiveAppEventResponse
            )

        InterfaceToHost.HttpRequestEvent httpRequestEvent ->
            let
                bodyFromString =
                    Bytes.Encode.string >> Bytes.Encode.encode >> Base64.fromBytes

                staticContentHttpHeaders contentType =
                    { cacheMaxAgeMinutes = Just (60 * 4)
                    , contentType = contentType
                    }

                httpResponseOkWithStringContent stringContent httpResponseHeaders =
                    httpResponseOkWithBodyAsBase64 (bodyFromString stringContent) httpResponseHeaders

                httpResponseOkWithBodyAsBase64 bodyAsBase64 { cacheMaxAgeMinutes, contentType } =
                    let
                        cacheHeaders =
                            case cacheMaxAgeMinutes of
                                Nothing ->
                                    []

                                Just maxAgeMinutes ->
                                    [ { name = "Cache-Control"
                                      , values = [ "public, max-age=" ++ String.fromInt (maxAgeMinutes * 60) ]
                                      }
                                    , { name = "Content-Type"
                                      , values = [ contentType ]
                                      }
                                    ]
                    in
                    { httpRequestId = httpRequestEvent.httpRequestId
                    , response =
                        { statusCode = 200
                        , bodyAsBase64 = bodyAsBase64
                        , headersToAdd = cacheHeaders
                        }
                    }

                frontendHtmlDocumentResponse frontendConfig =
                    InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded
                            [ httpResponseOkWithStringContent (frontendHtmlDocument frontendConfig)
                                (staticContentHttpHeaders "text/html")
                            ]
            in
            case httpRequestEvent.request.uri |> Url.fromString |> Maybe.andThen Backend.Route.routeFromUrl of
                Nothing ->
                    ( stateBefore
                    , frontendHtmlDocumentResponse { debug = False }
                    )

                Just (Backend.Route.StaticFileRoute (Backend.Route.FrontendHtmlDocumentRoute frontendConfig)) ->
                    ( stateBefore
                    , frontendHtmlDocumentResponse frontendConfig
                    )

                Just (Backend.Route.StaticFileRoute (Backend.Route.FrontendElmJavascriptRoute { debug })) ->
                    ( stateBefore
                    , InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded
                            [ httpResponseOkWithBodyAsBase64
                                (Just
                                    (if debug then
                                        CompilationInterface.ElmMake.elm_make__debug__javascript__base64____src_FrontendWeb_Main_elm

                                     else
                                        CompilationInterface.ElmMake.elm_make__javascript__base64____src_FrontendWeb_Main_elm
                                    )
                                )
                                (staticContentHttpHeaders "text/javascript")
                            ]
                    )

                Just (Backend.Route.StaticFileRoute Backend.Route.MonacoFrameDocumentRoute) ->
                    ( stateBefore
                    , InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded
                            [ httpResponseOkWithStringContent monacoHtmlDocument
                                (staticContentHttpHeaders "text/html")
                            ]
                    )

                Just (Backend.Route.StaticFileRoute Backend.Route.MonarchJavascriptRoute) ->
                    ( stateBefore
                    , InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded
                            [ httpResponseOkWithBodyAsBase64
                                (Just CompilationInterface.SourceFiles.file__base64____src_monarch_js)
                                (staticContentHttpHeaders "text/javascript")
                            ]
                    )

                Just (Backend.Route.StaticFileRoute Backend.Route.FaviconRoute) ->
                    ( stateBefore
                    , InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded
                            [ httpResponseOkWithBodyAsBase64
                                (Just CompilationInterface.SourceFiles.file__base64____static_favicon_svg)
                                (staticContentHttpHeaders "image/svg+xml")
                            ]
                    )

                Just Backend.Route.ApiRoute ->
                    ( { stateBefore | pendingHttpRequests = httpRequestEvent :: stateBefore.pendingHttpRequests |> List.take 10 }
                    , InterfaceToHost.passiveAppEventResponse
                    )

        InterfaceToHost.TaskCompleteEvent taskComplete ->
            let
                ( state, response ) =
                    processEventTaskComplete taskComplete stateBefore
            in
            ( { state
                | pendingTasksForRequestVolatileHost =
                    stateBefore.pendingTasksForRequestVolatileHost |> Dict.remove taskComplete.taskId
              }
            , response
            )


processEventTaskComplete : InterfaceToHost.TaskCompleteEventStructure -> State -> ( State, InterfaceToHost.AppEventResponse )
processEventTaskComplete taskComplete stateBefore =
    case taskComplete.taskResult of
        InterfaceToHost.CreateVolatileHostResponse createVolatileHostResponse ->
            case createVolatileHostResponse of
                Err createVolatileHostError ->
                    let
                        bodyFromString =
                            Bytes.Encode.string >> Bytes.Encode.encode >> Base64.fromBytes

                        httpResponse =
                            { statusCode = 500
                            , bodyAsBase64 = bodyFromString ("Failed to create volatile host: " ++ createVolatileHostError.exceptionToString)
                            , headersToAdd = []
                            }

                        httpResponses =
                            stateBefore.pendingHttpRequests
                                |> List.map
                                    (\httpRequest ->
                                        { httpRequestId = httpRequest.httpRequestId
                                        , response = httpResponse
                                        }
                                    )
                    in
                    ( { stateBefore | pendingHttpRequests = [] }
                    , InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded httpResponses
                    )

                Ok { hostId } ->
                    ( { stateBefore
                        | volatileHostsIds = Set.insert hostId stateBefore.volatileHostsIds
                      }
                    , InterfaceToHost.passiveAppEventResponse
                    )

        InterfaceToHost.RequestToVolatileHostResponse requestToVolatileHostResponse ->
            case
                stateBefore.pendingHttpRequests
                    |> List.filter (taskIdForHttpRequest >> (==) taskComplete.taskId)
                    |> List.head
            of
                Nothing ->
                    ( stateBefore
                    , InterfaceToHost.passiveAppEventResponse
                    )

                Just httpRequestEvent ->
                    let
                        bodyFromString =
                            Bytes.Encode.string >> Bytes.Encode.encode >> Base64.fromBytes

                        httpResponseInternalServerError errorMessage =
                            { statusCode = 500
                            , bodyAsBase64 = bodyFromString errorMessage
                            , headersToAdd = []
                            }

                        ( httpResponse, maybeVolatileHostToRemoveId ) =
                            case stateBefore.pendingTasksForRequestVolatileHost |> Dict.get taskComplete.taskId of
                                Nothing ->
                                    ( httpResponseInternalServerError
                                        ("Error: Did not find entry for task ID '" ++ taskComplete.taskId ++ "'")
                                    , stateBefore.pendingTasksForRequestVolatileHost
                                        |> Dict.get taskComplete.taskId
                                        |> Maybe.map .volatileHostId
                                    )

                                Just pendingTask ->
                                    case requestToVolatileHostResponse of
                                        Err InterfaceToHost.HostNotFound ->
                                            ( httpResponseInternalServerError
                                                ("Error: Volatile host '"
                                                    ++ pendingTask.volatileHostId
                                                    ++ "' disappeared. Starting volatile host again... Please retry."
                                                )
                                            , Just pendingTask.volatileHostId
                                            )

                                        Ok requestToVolatileHostComplete ->
                                            case requestToVolatileHostComplete.exceptionToString of
                                                Just exceptionToString ->
                                                    ( { statusCode = 500
                                                      , bodyAsBase64 = bodyFromString ("Exception in volatile host:\n" ++ exceptionToString)
                                                      , headersToAdd = []
                                                      }
                                                    , Nothing
                                                    )

                                                Nothing ->
                                                    let
                                                        ( headersToAdd, bodyAsBase64 ) =
                                                            case requestToVolatileHostComplete.returnValueToString of
                                                                Nothing ->
                                                                    ( [], Nothing )

                                                                Just returnValueToString ->
                                                                    let
                                                                        deflateEncodedBody =
                                                                            returnValueToString
                                                                                |> Bytes.Encode.string
                                                                                |> Bytes.Encode.encode
                                                                                |> Flate.deflateGZip
                                                                    in
                                                                    ( [ { name = "Content-Encoding", values = [ "gzip" ] } ]
                                                                    , deflateEncodedBody |> Base64.fromBytes
                                                                    )
                                                    in
                                                    ( { statusCode = 200
                                                      , bodyAsBase64 = bodyAsBase64
                                                      , headersToAdd = headersToAdd
                                                      }
                                                    , Nothing
                                                    )

                        volatileHostsIds =
                            case maybeVolatileHostToRemoveId of
                                Nothing ->
                                    stateBefore.volatileHostsIds

                                Just volatileHostToRemoveId ->
                                    stateBefore.volatileHostsIds |> Set.remove volatileHostToRemoveId
                    in
                    ( { stateBefore
                        | pendingHttpRequests = stateBefore.pendingHttpRequests |> List.filter ((==) httpRequestEvent >> not)
                        , volatileHostsIds = volatileHostsIds
                      }
                    , InterfaceToHost.passiveAppEventResponse
                        |> InterfaceToHost.withCompleteHttpResponsesAdded
                            [ { httpRequestId = httpRequestEvent.httpRequestId
                              , response = httpResponse
                              }
                            ]
                    )

        InterfaceToHost.CompleteWithoutResult ->
            ( stateBefore
            , InterfaceToHost.passiveAppEventResponse
            )


tasksFromState : State -> List InterfaceToHost.StartTaskStructure
tasksFromState state =
    let
        tasksToEnsureEnoughVolatileHostsCreated =
            if Set.size state.volatileHostsIds < parallelVolatileHostsCount then
                [ { taskId = "create-vhost"
                  , task = InterfaceToHost.CreateVolatileHost { script = VolatileHost.volatileHostScript }
                  }
                ]

            else
                []

        pendingHttpRequestsWithTaskId =
            state.pendingHttpRequests
                |> List.map (\httpRequest -> ( taskIdForHttpRequest httpRequest, httpRequest ))

        pendingTasksForRequestVolatileHost =
            state.pendingTasksForRequestVolatileHost
                |> Dict.filter
                    (\_ pendingTask ->
                        state.posixTimeMilli < pendingTask.startPosixTimeMilli + requestToVolatileHostTimeoutMilliseconds
                    )

        pendingHttpRequestsWithoutPendingRequestToVolatileHost =
            pendingHttpRequestsWithTaskId
                |> List.filter
                    (\( taskId, _ ) -> pendingTasksForRequestVolatileHost |> Dict.member taskId |> not)

        freeVolatileHostsIds =
            state.volatileHostsIds
                |> Set.filter
                    (\volatileHostId ->
                        pendingTasksForRequestVolatileHost
                            |> Dict.values
                            |> List.any (.volatileHostId >> (==) volatileHostId)
                            |> not
                    )
    in
    case pendingHttpRequestsWithoutPendingRequestToVolatileHost |> List.head of
        Nothing ->
            tasksToEnsureEnoughVolatileHostsCreated

        Just ( taskId, httpRequestEvent ) ->
            case List.head (Set.toList freeVolatileHostsIds) of
                Nothing ->
                    tasksToEnsureEnoughVolatileHostsCreated

                Just volatileHostId ->
                    let
                        task =
                            { hostId = volatileHostId
                            , request =
                                httpRequestEvent.request.bodyAsBase64
                                    |> Maybe.andThen Common.decodeBase64ToString
                                    |> Maybe.withDefault "Error decoding base64"
                            }
                                |> InterfaceToHost.RequestToVolatileHost
                    in
                    [ { taskId = taskId
                      , task = task
                      }
                    ]


taskIdForHttpRequest : InterfaceToHost.HttpRequestEventStructure -> String
taskIdForHttpRequest httpRequestEvent =
    "http-request-api-" ++ httpRequestEvent.httpRequestId


interfaceToHost_initState : State
interfaceToHost_initState =
    { posixTimeMilli = 0
    , volatileHostsIds = Set.empty
    , pendingHttpRequests = []
    , pendingTasksForRequestVolatileHost = Dict.empty
    }


interfaceToHost_processEvent : String -> State -> ( State, String )
interfaceToHost_processEvent =
    InterfaceToHost.wrapForSerialInterface_processEvent processEvent


frontendHtmlDocument : { debug : Bool } -> String
frontendHtmlDocument { debug } =
    let
        elmMadeScriptFileName =
            if debug then
                Backend.Route.elmMadeScriptFileNameDebug

            else
                Backend.Route.elmMadeScriptFileNameDefault
    in
    """
<!DOCTYPE HTML>
<html>

<head>
  <meta charset="UTF-8">
  <title>Elm Editor</title>
  <link rel="icon" href="/"""
        ++ Common.faviconPath
        ++ """" type="image/x-icon">
  <script type="text/javascript" src="""
        ++ elmMadeScriptFileName
        ++ """></script>
</head>

<body>
    <div id="elm-app-container"></div>
</body>

<script type="text/javascript">

var app = Elm.FrontendWeb.Main.init({
    node: document.getElementById('elm-app-container')
});

app.ports.sendMessageToMonacoFrame.subscribe(function(message) {
    document.getElementById('monaco-iframe')?.contentWindow?.dispatchMessage?.(message);
});

function messageFromMonacoFrame(message) {
    app.ports.receiveMessageFromMonacoFrame?.send(message);
}

</script>

</html>
"""


monacoHtmlDocument : String
monacoHtmlDocument =
    MonacoHtml.monacoHtmlDocumentFromCdnUrl (monacoCdnURLs |> List.head |> Maybe.withDefault "Missing URL to CDN")


{-| <https://github.com/microsoft/monaco-editor/issues/583>
-}
monacoCdnURLs : List String
monacoCdnURLs =
    [ "https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.22.3/min"
    , "https://unpkg.com/monaco-editor@0.22.3/min"
    , "https://cdn.jsdelivr.net/npm/monaco-editor@0.22.3/min"
    ]
