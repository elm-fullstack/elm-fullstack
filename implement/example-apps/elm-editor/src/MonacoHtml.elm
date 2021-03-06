module MonacoHtml exposing (..)

{-| -}


{-| Combine from samples:

  - <https://github.com/microsoft/monaco-editor/blob/1396f98763b08e4b8dc3d9e16e23ceb67d8456e9/docs/integrate-amd.md>
  - <https://github.com/microsoft/monaco-editor/blob/1396f98763b08e4b8dc3d9e16e23ceb67d8456e9/docs/integrate-amd-cross.md>

-}
monacoHtmlDocumentFromCdnUrl : String -> String
monacoHtmlDocumentFromCdnUrl cdnUrlToMin =
    """
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
    <script type="text/javascript" src="monarch.js"></script>
</head>
<body style="margin:0;height:93vh;">

<div id="container" style="height:100%;width:100%;"></div>

<script type="text/javascript" src=\""""
        ++ cdnUrlToMin
        ++ """/vs/loader.js"></script>

<script>

    function getEditorModel() {
        if(typeof monaco != "object")
            return null;

        return monaco?.editor?.getModels()[0];
    }

    function monacoEditorSetValue(newValue) {
        getEditorModel()?.setValue(newValue);
    }

    function monacoEditorSetModelMarkers(markers) {
        if (typeof monaco === 'undefined')
            return;

        monaco?.editor?.setModelMarkers(getEditorModel(), "", markers.map(monacoMarkerFromElmMonacoMarker));
    }

    function monacoEditorRevealPositionInCenter(position) {
        if (typeof theEditor === 'undefined')
            return;

        theEditor?.revealPositionInCenter(position);
    }

    function monacoMarkerFromElmMonacoMarker(elmMonacoMarker) {
        return {
            message : elmMonacoMarker.message,
            startLineNumber : elmMonacoMarker.startLineNumber,
            startColumn : elmMonacoMarker.startColumn,
            endLineNumber : elmMonacoMarker.endLineNumber,
            endColumn : elmMonacoMarker.endColumn,
            severity : monacoMarkerSeverityFromElmMonacoMarkerSeverity(elmMonacoMarker.severity),
        };
    }

    function monacoMarkerSeverityFromElmMonacoMarkerSeverity(elmMonacoMarkerSeverity) {
        if (typeof monaco === 'undefined')
            return -1;

        if (elmMonacoMarkerSeverity.ErrorSeverity != null)
            return monaco?.MarkerSeverity.Error;

        if (elmMonacoMarkerSeverity.WarningSeverity != null)
            return monaco?.MarkerSeverity.Warning;

        if (elmMonacoMarkerSeverity.InfoSeverity != null)
            return monaco?.MarkerSeverity.Info;

        if (elmMonacoMarkerSeverity.HintSeverity != null)
            return monaco?.MarkerSeverity.Hint;
    }

    function dispatchMessage(message) {
        if(message.SetValue)
            monacoEditorSetValue(message.SetValue[0]);

        if(message.SetModelMarkers)
            monacoEditorSetModelMarkers(message.SetModelMarkers[0]);

        if(message.RevealPositionInCenter)
            monacoEditorRevealPositionInCenter(message.RevealPositionInCenter[0]);
    }

    function tryCompleteSetup() {
        var editorModel = getEditorModel();

        if(editorModel == null) {
            setTimeout(tryCompleteSetup, 500);
        }
        else {
            editorModel.onDidChangeContent(function() {
                var content = getEditorModel().getValue();

                // console.log("onDidChangeContent:\\n" + content);

                parent?.messageFromMonacoFrame?.({"DidChangeContentEvent":[content]});
            });

            parent?.messageFromMonacoFrame?.({"CompletedSetupEvent":[]});
        }
    }

    function editorActionCloseEditor() {
        parent?.messageFromMonacoFrame?.({"EditorActionCloseEditorEvent":[]});
    }

    function editorActionFormatDocument() {
        parent?.messageFromMonacoFrame?.({"EditorActionFormatDocumentEvent":[]});
    }

    function editorActionCompile() {
        parent?.messageFromMonacoFrame?.({"EditorActionCompileEvent":[]});
    }


</script>

<script>
  require.config({ paths: { 'vs': '"""
        ++ cdnUrlToMin
        ++ """/vs' }});

  // Before loading vs/editor/editor.main, define a global MonacoEnvironment that overwrites
  // the default worker url location (used when creating WebWorkers). The problem here is that
  // HTML5 does not allow cross-domain web workers, so we need to proxy the instantiation of
  // a web worker through a same-domain script
  window.MonacoEnvironment = {
    getWorkerUrl: function(workerId, label) {
      return `data:text/javascript;charset=utf-8,${encodeURIComponent(`
        self.MonacoEnvironment = {
          baseUrl: '"""
        ++ cdnUrlToMin
        ++ """/'
        };
        importScripts('"""
        ++ cdnUrlToMin
        ++ """/vs/base/worker/workerMain.js');`
      )}`;
    }
  };
    require(['vs/editor/editor.main'], function() {

        monaco.languages.register({ id: 'Elm' });

        monaco.languages.setMonarchTokensProvider('Elm', window.elm_monarch);

        monaco.editor.defineTheme('dark-plus', {
            base: 'vs-dark',
            inherit: true,
            rules: [
                { token: 'keyword', foreground: '#C586C0' },
                { token: 'type', foreground: '#569CD6' },
                { token: 'function.name', foreground: '#DCDCAA' },
            ]
        });

        var editor = monaco.editor.create(document.getElementById('container'), {
            value: "Initialization of editor is not complete yet",
            language: 'Elm',
            automaticLayout: true,
            scrollBeyondLastLine: false,
            theme: "dark-plus"
        });

        editor.addAction({
            id: 'close-editor-action',
            label: 'Close Editor',
            keybindings: [],
            precondition: null,
            keybindingContext: null,

            contextMenuGroupId: 'z-other',
            contextMenuOrder: 99,

            run: function(ed) {
                editorActionCloseEditor();
                return null;
            }
        });

        editor.addAction({
            id: 'format-document-action',
            label: 'Format Document',
            keybindings: [
                monaco.KeyMod.Shift | monaco.KeyMod.Alt | monaco.KeyCode.KEY_F
            ],
            precondition: null,
            keybindingContext: null,

            run: function(ed) {
                editorActionFormatDocument();
                return null;
            }
        });

        editor.addAction({
            id: 'compile-action',
            label: 'Compile',
            keybindings: [
                monaco.KeyMod.Shift | monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter
            ],
            precondition: null,
            keybindingContext: null,

            run: function(ed) {
                editorActionCompile();
                return null;
            }
        });

        window.theEditor = editor;

        tryCompleteSetup();
    });
</script>

</body>
</html>
"""
