module FileTree exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Framework.Color as Color


type Tree
    = File String (Maybe String)
    | Folder String (List Tree)


viewTree : Tree -> Element msg
viewTree tree =
    let
        maxLength =
            32
    in
    case tree of
        File name Nothing ->
            text <| name ++ " ()"

        File name (Just content) ->
            row [ spacing 10 ]
                [ text name
                , el [ padding 4, Background.color Color.yellow, Border.rounded 4 ] <|
                    if String.length content > maxLength then
                        content
                            |> String.left maxLength
                            |> (\s -> s ++ "...")
                            |> text
                            |> el [ Font.italic ]

                    else
                        content
                            |> text
                            |> el [ Font.italic ]
                ]

        Folder name [] ->
            text <| name ++ " []"

        Folder name children ->
            let
                header =
                    [ text <| "folder: " ++ name ++ " [" ]

                body =
                    List.map viewTree children

                footer =
                    [ text "]" ]
            in
            column [ paddingXY 10 0 ] (header ++ body ++ footer)
