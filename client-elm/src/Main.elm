port module Main exposing (..)

import Browser
import Delay exposing (TimeUnit(..))
import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
import FileTree exposing (Tree(..), viewTree)
import Framework.Color as Color


port sendMessage : String -> Cmd msg


port getFileList : String -> Cmd msg


port receiveMessage : (String -> msg) -> Sub msg


port receiveFileList : (List String -> msg) -> Sub msg


port handleError : (String -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    { mMessage : Maybe String
    , searchTerm : String
    , files : List String
    , mError : Maybe String
    }


setMessage : Maybe String -> Model -> Model
setMessage mMessage model =
    { model | mMessage = mMessage }


setSearchTerm : String -> Model -> Model
setSearchTerm searchTerm model =
    { model | searchTerm = searchTerm }



-- delayCmd :


delayCmd =
    Delay.after 500 Millisecond


init : ( Model, Cmd Msg )
init =
    ( { mMessage = Nothing
      , searchTerm = ""
      , files = []
      , mError = Nothing
      }
    , Cmd.batch
        [ sendMessage "Elm::init()"
        ]
    )



---- UPDATE ----


type Msg
    = ReceiveMessage String
    | SetSearchTerm String
    | ReceiveFileList (List String)
    | HandleError String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        simply m =
            ( m, Cmd.none )
    in
    case msg of
        ReceiveMessage message ->
            simply
                { model | mMessage = Just message }

        SetSearchTerm term ->
            let
                _ =
                    Debug.log "scheduled" term
            in
            ( model |> setSearchTerm term
            , getFileList term
            )

        ReceiveFileList files ->
            simply { model | files = files }

        HandleError string ->
            simply { model | mError = Just string }



---- VIEW ----


exampleFileTree : Tree
exampleFileTree =
    Folder "Root"
        [ Folder "Nested"
            [ File "foo" (Just "lorem ipsum etc")
            , File "foo"
                (Just """
exampleFileTree : Tree
exampleFileTree =
    Folder "Root"
        [ Folder "Nested" [
            File "foo" (Just "lorem ipsum etc"),
            File "foo" (Just "lorem ipsum etc"),
        ]
        , File ".gitignore" (Just "node_modules")
        ]
""")
            ]
        , File ".gitignore" (Just "node_modules")
        ]


view : Model -> Element Msg
view model =
    column []
        [ case model.mMessage of
            Just message ->
                text <| "Received @message: '" ++ message ++ "'"

            Nothing ->
                text "No messages yet"
        , Input.text []
            { label = Input.labelLeft [] <| text "search"
            , onChange = SetSearchTerm
            , text = model.searchTerm
            , placeholder = Nothing
            }
        , model.files |> Debug.toString |> text |> List.singleton |> paragraph []
        , model.mError |> Maybe.withDefault "No error!" |> text
        , exampleFileTree
            |> viewTree
            |> el [ padding 16, Background.color Color.muted ]
        ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveMessage ReceiveMessage
        , receiveFileList ReceiveFileList
        , handleError HandleError
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = \model -> layout [] <| view model
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
