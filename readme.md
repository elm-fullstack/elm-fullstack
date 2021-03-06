# Elm Full-Stack

Full-stack web apps made simple - using the [Elm programming language](https://elm-lang.org).

Elm Fullstack supports:

+ Programming web servers using the Elm programming language.
+ Using the Elm Architecture on the backend by providing automatic persistence, replication, and migrations.
+ Sharing Elm modules with common functions and types between frontend and backend implementations.
+ Automating the generation of functions to serialize and deserialize Elm values.

## Getting Started

Use this command to run a server and deploy an example app:

```cmd
elm-fs  run-server  --public-urls="http://*:5000"  --deploy-app=https://github.com/elm-fullstack/elm-fullstack/tree/6d96fca86dc807208e923caffb94a449d6f4b22d/implement/example-apps/docker-image-default-app
```

For a guide on installation and configuration options, see [How to Configure and Deploy an Elm Fullstack App](guide/how-to-configure-and-deploy-an-elm-fullstack-app.md).

## Releases / Artifacts

### elm-fs Executable File

The `elm-fs` executable file contains all the functionality to build apps and operate backend processes. You can download the files from the [releases section](https://github.com/elm-fullstack/elm-fullstack/releases) on Github.

### Docker Image

If you prefer deploying using docker, use the `elmfullstack/elm-fullstack` image from [docker hub](https://hub.docker.com/r/elmfullstack/elm-fullstack/tags). The tags are aligned with the version IDs in the CLI executable file.

```cmd
docker  run  -p 5000:80  -p 4000:4000  --env "APPSETTING_adminPassword=test" elmfullstack/elm-fullstack
```

To learn more about these artifacts' interfaces, see [How to Configure and Deploy an Elm Fullstack App](guide/how-to-configure-and-deploy-an-elm-fullstack-app.md).

## Building from Source

The easiest way to test a change in the source code is to trigger the Github action workflow in [`.github/workflows/test-and-publish.yml`](./.github/workflows/test-and-publish.yml). This workflow gets you the results of automated tests and your version of the executable files. Push to your fork on Github to trigger this action.

As we can see in the [workflow file](./.github/workflows/test-and-publish.yml), the project uses .NET core 3.1 to run tests and build the executable file. You can download the `dotnet` tool from https://dotnet.microsoft.com/download/dotnet-core to build and test locally.

## Example Apps

### Rich Chat Room

The [rich chat room example app](https://github.com/elm-fullstack/elm-fullstack/tree/main/implement/example-apps/rich-chat-room) demonstrates features typically found in a chat app, such as user names, message rate-limiting, sound effects, etc.
For a detailed description of this app, see the readme file at https://github.com/elm-fullstack/elm-fullstack/blob/main/implement/example-apps/rich-chat-room/readme.md

### Elm Editor

[Elm Editor](https://github.com/elm-fullstack/elm-fullstack/tree/main/implement/example-apps/elm-editor) is an editor for developing Elm programs. It also provides tooling specifically for web frontend-apps to compile and view an app inline.

<a href="https://github.com/elm-fullstack/elm-fullstack/tree/main/implement/example-apps/elm-editor/readme.md">
<img src="./guide/image/2021-03-17-elm-editor-user-interface.png" width="500" />
</a>

To see Elm Editor in action, check out the public instance at https://elm-editor.com

To learn more about how it works, see https://github.com/elm-fullstack/elm-fullstack/tree/main/implement/example-apps/elm-editor/readme.md
