module Tests exposing (..)

import Expect
import FileTree exposing (FileTree(..), create, extend)
import Test exposing (..)



-- Check out https://package.elm-lang.org/packages/elm-explorations/test/latest to learn more about testing in Elm!


all : Test
all =
    describe "FileTree"
        [ test "create" <|
            \_ ->
                let
                    result =
                        create [ "first", "second", "third" ]

                    expected =
                        Folder "root"
                            [ File "first" Nothing
                            , File "second" Nothing
                            , File "third" Nothing
                            ]
                in
                Expect.equal result expected
        , test "create nested" <|
            \_ ->
                let
                    result =
                        create [ "first", "first/second" ]

                    expected =
                        Folder "root"
                            [ Folder "first"
                                [ File "second" Nothing
                                ]
                            ]
                in
                Expect.equal result expected
        , test "create nested deeper" <|
            \_ ->
                let
                    result =
                        create [ "first", "first/second", "first/second/third", "first/second/third/fourth", "first/fifth" ]

                    expected =
                        Folder "root"
                            [ Folder "first"
                                [ File "fifth" Nothing
                                , Folder "second" [ Folder "third" [ File "fourth" Nothing ] ]
                                ]
                            ]
                in
                Expect.equal result expected
        , test "extend" <|
            \_ ->
                let
                    tree =
                        create [ "first" ]

                    result =
                        extend [ "first/second" ] tree

                    expected =
                        Folder "root" [ Folder "first" [ File "second" Nothing ] ]
                in
                Expect.equal result expected
        ]
