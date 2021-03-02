module FileTree exposing (FileTree(..), create, empty, extend, viewTree)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Framework.Color as Color
import List


empty : FileTree
empty =
    Folder "root" []


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


insertPath : String -> FileTree -> FileTree
insertPath path tree =
    insertSegments (String.split "/" path) tree


extend : List String -> FileTree -> FileTree
extend files tree =
    files
        |> List.sort
        |> List.foldl insertPath tree


create : List String -> FileTree
create files =
    extend files empty


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

        indent =
            paddingXY 10 0

        indented =
            el [ indent ]
    in
    case tree of
        File name Nothing ->
            indented <| text <| name ++ " ()"

        File name (Just content) ->
            indented <|
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
            indented <| text <| name ++ " []"

        Folder name children ->
            let
                header =
                    [ text <| name ++ " [" ]

                body =
                    List.map viewTree children

                footer =
                    [ text "]" ]
            in
            column [ indent ] (header ++ body ++ footer)
