port module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)


port sendMessage : String -> Cmd msg


port receiveMessage : (String -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.batch [ sendMessage "Hello from elm!" ] )



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm+Rust App is working!" ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
