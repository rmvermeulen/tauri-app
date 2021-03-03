port module Main exposing (..)

import Browser
import Debounce exposing (Debounce)
import Delay exposing (TimeUnit(..))
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import FileTree exposing (FileTree(..), viewTree)
import Framework.Color as Color
import Framework.Spinner exposing (Spinner(..), spinner)


port searchGlob : String -> Cmd msg


port loadResource : ResourceRequest -> Cmd msg


port receiveFiles : (ResourceResponse FileInfo -> msg) -> Sub msg


port receiveResourceId : (String -> msg) -> Sub msg


port handleError : (String -> msg) -> Sub msg



---- MODEL ----


batchSize : Int
batchSize =
    16


type alias FileInfo =
    { path : String
    , name : String
    , tags : List String
    }


type Files
    = None
    | Searching
    | Loading (ResourceResponse FileInfo) FileTree
    | Loaded (List FileInfo) FileTree


type alias Model =
    { globDebouncer : Debounce String
    , mMessage : Maybe String
    , searchTerm : String
    , files : Files
    , mError : Maybe String
    }



-- This defines how the debouncer should work.
-- Choose the strategy for your use case.


debounceConfig : Debounce.Config Msg
debounceConfig =
    { strategy = Debounce.later 250
    , transform = DebounceMsg
    }



---- setters ----


setMessage : Maybe String -> Model -> Model
setMessage mMessage model =
    { model | mMessage = mMessage }


setSearchTerm : String -> Model -> Model
setSearchTerm searchTerm model =
    { model | searchTerm = searchTerm }


setGlobDebouncer : Debounce String -> Model -> Model
setGlobDebouncer globDebouncer model =
    { model | globDebouncer = globDebouncer }


setFiles : Files -> Model -> Model
setFiles files model =
    { model | files = files }


delayCmd : msg -> Cmd msg
delayCmd =
    Delay.after 500 Millisecond


init : ( Model, Cmd Msg )
init =
    let
        empty =
            { globDebouncer = Debounce.init
            , mMessage = Nothing
            , searchTerm = ""
            , files = None
            , mError = Nothing
            }
    in
    update (SetSearchTerm "*") empty



---- UPDATE ----


type alias RID =
    String


type alias ResourceRequest =
    { rid : RID
    , amount : Int
    , resPort : String
    }


type alias ResourceResponse item =
    { rid : RID
    , amount : Int
    , items : List item
    , done : Bool
    }


type Msg
    = ReceiveMessage String
    | SetSearchTerm String
    | ReceiveResourceId RID
    | ReceiveResourceResponse (ResourceResponse FileInfo)
    | SendResourceRequest ResourceRequest
    | HandleError String
    | DebounceMsg Debounce.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateDebouncer : Debounce.Msg -> Debounce String -> ( Debounce String, Cmd Msg )
        updateDebouncer =
            Debounce.update debounceConfig (Debounce.takeLast searchGlob)

        simply m =
            ( m, Cmd.none )
    in
    case msg of
        ReceiveMessage message ->
            simply
                { model | mMessage = Just message }

        SetSearchTerm term ->
            let
                ( globDebouncer, cmd ) =
                    Debounce.push debounceConfig term model.globDebouncer
            in
            ( model
                |> setSearchTerm term
                |> setGlobDebouncer globDebouncer
                |> setFiles Searching
            , cmd
            )

        ReceiveResourceId rid ->
            let
                files =
                    Loading
                        { rid = rid
                        , items = []
                        , amount = -1
                        , done = False
                        }
                        FileTree.empty
            in
            ( model |> setFiles files
            , delayCmd <|
                SendResourceRequest <|
                    ResourceRequest rid batchSize "receiveFiles"
            )

        ReceiveResourceResponse res ->
            let
                files =
                    case model.files of
                        Loading { rid, items, amount } tree ->
                            let
                                paths =
                                    res.items |> List.map .path

                                updatedTree =
                                    FileTree.extend paths tree
                            in
                            if rid == res.rid then
                                if res.done then
                                    let
                                        total =
                                            items ++ res.items
                                    in
                                    Loaded total updatedTree

                                else
                                    Loading
                                        { rid = rid
                                        , items = items ++ res.items
                                        , amount = amount
                                        , done = res.done
                                        }
                                        updatedTree

                            else
                                Loading res updatedTree

                        _ ->
                            model.files
            in
            ( model |> setFiles files
            , Delay.after 100 Millisecond <|
                SendResourceRequest
                    { rid = res.rid
                    , amount = res.amount
                    , resPort = "receiveFiles"
                    }
            )

        SendResourceRequest req ->
            let
                isValid =
                    case model.files of
                        Loading { rid } _ ->
                            req.rid == rid

                        _ ->
                            False
            in
            ( model
            , if isValid then
                loadResource req

              else
                Cmd.none
            )

        HandleError string ->
            simply { model | mError = Just string }

        DebounceMsg dMsg ->
            let
                ( globDebouncer, cmd ) =
                    updateDebouncer dMsg model.globDebouncer
            in
            ( model
                |> setGlobDebouncer globDebouncer
            , cmd
            )



---- VIEW ----


view : Model -> Element Msg
view model =
    column []
        [ case model.mMessage of
            Just message ->
                text <| "Received @message: '" ++ message ++ "'"

            Nothing ->
                text "No messages yet"
        , Input.text [ width (fill |> maximum 250) ]
            { label = Input.labelLeft [] <| text "search"
            , onChange = SetSearchTerm
            , text = model.searchTerm
            , placeholder = Nothing
            }
        , viewFiles model.files
        , model.mError
            |> Maybe.map text
            |> Maybe.withDefault none
        ]


viewFiles : Files -> Element Msg
viewFiles fileData =
    let
        scrollView =
            el [ width fill, height (fill |> maximum 500) ]
                << column
                    [ width fill
                    , height (fill |> maximum 500)
                    , clipY
                    , scrollbarY
                    ]

        resultsLabel items =
            let
                amount =
                    List.length items

                rc =
                    String.fromInt amount
            in
            if amount == 1 then
                rc ++ " result"

            else
                rc ++ " results"
    in
    case fileData of
        None ->
            none

        Searching ->
            spinner ThreeCircles 24 Color.black

        Loading { items } tree ->
            column []
                [ row [ spacing 10 ]
                    [ spinner ThreeCircles 24 Color.green
                    , text <| resultsLabel items
                    ]
                , items
                    |> List.map Debug.toString
                    |> List.map text
                    |> scrollView
                , tree
                    |> viewTree
                    |> el [ padding 16, Background.color Color.muted ]
                ]

        Loaded files tree ->
            if List.isEmpty files then
                el [ Font.italic ] <| text "no results."

            else
                column [ Font.family [ Font.monospace ] ]
                    [ text <| resultsLabel files
                    , files
                        |> List.map .path
                        |> List.sortBy String.length
                        |> List.map text
                        |> scrollView
                    , tree
                        |> viewTree
                        |> el [ padding 16, Background.color Color.muted ]
                    ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveResourceId ReceiveResourceId
        , receiveFiles ReceiveResourceResponse
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
