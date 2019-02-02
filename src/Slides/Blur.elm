module Slides.Blur exposing (blur)


blur : Float -> String
blur completion =
    String.join ""
        [ "blur("
        , (1 - completion)
            * 20
            |> Basics.round
            |> String.fromInt
        , "px)"
        ]
