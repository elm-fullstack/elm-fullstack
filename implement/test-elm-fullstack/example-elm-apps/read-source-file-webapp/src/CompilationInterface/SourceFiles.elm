module CompilationInterface.SourceFiles exposing (..)

import Bytes
import Bytes.Encode


file____static_content_demo_file_mp3 : Bytes.Bytes
file____static_content_demo_file_mp3 =
    "The compiler replaces this value."
        |> Bytes.Encode.string
        |> Bytes.Encode.encode


file__utf8____readme_md : String
file__utf8____readme_md =
    "The compiler replaces this value."
