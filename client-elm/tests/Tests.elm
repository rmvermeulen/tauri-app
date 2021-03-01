module Tests exposing (..)

import Expect
import FileTree exposing (FileTree(..), fromPaths)
import Test exposing (..)



-- Check out https://package.elm-lang.org/packages/elm-explorations/test/latest to learn more about testing in Elm!


all : Test
all =
    describe "FileTree"
        [ test "fromPaths" <|
            \_ ->
                let
                    result =
                        fromPaths [ "first", "second", "third" ]

                    expected =
                        Folder "root"
                            [ File "first" Nothing
                            , File "second" Nothing
                            , File "third" Nothing
                            ]
                in
                Expect.equal result expected
        , test "fromPaths 2" <|
            \_ ->
                let
                    result =
                        fromPaths [ "first", "first/second" ]

                    expected =
                        Folder "root"
                            [ Folder "first"
                                [ File "second" Nothing
                                ]
                            ]
                in
                Expect.equal result expected
        , test "fromPaths 3" <|
            \_ ->
                let
                    result =
                        fromPaths [ "first", "first/second", "first/second/third", "first/second/third/fourth", "first/fifth" ]

                    expected =
                        Folder "root"
                            [ Folder "first"
                                [ File "fifth" Nothing
                                , Folder "second" [ Folder "third" [ File "fourth" Nothing ] ]
                                ]
                            ]
                in
                Expect.equal result expected
        ]
