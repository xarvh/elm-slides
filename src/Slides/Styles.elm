module Slides.Styles exposing (..)

{-| A few ready made styles to use as `Options.style`.

@docs whiteOnBlack
-}

import Css exposing (..)
import Css.Elements exposing (..)


{-| White centered text, black background
-}
whiteOnBlack : List Css.Snippet
whiteOnBlack =
    [ body
        [ padding zero
        , margin zero
        , height (pct 100)
        , backgroundColor (rgb 0 0 0)
        , color (hex "fafafb")
        , fontFamilies [ "Palatino Linotype" ]
        , textAlign center
        , fontSize (px 38)
          --             , fontWeight normal
        ]
    , h1
        [--         font-weight: normal;
        ]
    , section
        [ height (px 700)
          --         , backgroundPosition center
          --         , backgroundSize cover
        , displayFlex
          --         , justifyContent center
        , alignItems center
        ]
    , (.) "slide-content"
        [ margin2 zero (px 90)
        ]
    , code
        [ textAlign left
        , fontSize (px 18)
        , padding (px 12)
        ]
    , pre
        [ padding (px 20)
        ]
    , a
        [ textDecoration none
        , display block
        , color (hex "fafafb")
        ]
    ]
