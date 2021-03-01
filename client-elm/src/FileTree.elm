module FileTree exposing (..)

import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Framework.Color as Color
import List


rootFolder =
    Folder "root" []


fromPaths : List String -> FileTree
fromPaths files =
    let
        insertNonEmpty : String -> List String -> FileTree -> FileTree
        insertNonEmpty segment rest tree =
            case tree of
                File name _ ->
                    -- convert file into folder
                    Folder name [ File segment Nothing ]

                Folder name paths ->
                    let
                        ( mExistingNode, others ) =
                            paths
                                |> List.partition (nodeName >> (==) segment)
                                |> Tuple.mapFirst List.head
                    in
                    case mExistingNode of
                        Just node ->
                            -- insert the rest of the segments in the found node
                            Folder name (others ++ [ insertSegments rest node ])

                        Nothing ->
                            -- create new file in the current folder
                            Folder name (paths ++ [ File segment Nothing ])

        insertSegments : List String -> FileTree -> FileTree
        insertSegments segments tree =
            case segments of
                [] ->
                    tree

                segment :: rest ->
                    insertNonEmpty segment rest tree
    in
    files
        |> List.sort
        |> List.map (String.split "/")
        |> List.foldl insertSegments rootFolder


nodeName : FileTree -> String
nodeName tree =
    case tree of
        File name _ ->
            name

        Folder name _ ->
            name


type FileTree
    = File String (Maybe String)
    | Folder String (List FileTree)


viewTree : FileTree -> Element msg
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
