module Slides.Styles exposing (..)

{-| A few ready made styles to use as `Options.style`.

# Elm Minimalist
A terse, clean style.
You can customise it by using `elmMinimalist` with the colors and font size you want,
use one of the presets, or [check the source](https://github.com/xarvh/elm-slides/blob/master/src/Slides/Styles.elm)
and using as starting template.

@docs elmMinimalist, elmBlueOnWhite, blackOnWhite, whiteOnBlack
-}

import Css exposing (..)
import Css.Elements exposing (..)


{-| Elm Minimalist, white text on black background
-}
whiteOnBlack : List Css.Snippet
whiteOnBlack =
    elmMinimalist (rgb 255 255 255) (rgb 230 230 230) (px 30) (hex "fafafb")


{-| Elm Minimalist, black text on white background
-}
blackOnWhite : List Css.Snippet
blackOnWhite =
    elmMinimalist (rgb 255 255 255) (rgb 230 230 230) (px 30) (hex "60B5CC")


{-| Elm Minimalist, Elm blue on white background
-}
elmBlueOnWhite : List Css.Snippet
elmBlueOnWhite =
    elmMinimalist (rgb 255 255 255) (rgb 230 230 230) (px 30) (hex "60B5CC")


{-| A minimalist, clean style.
    You can customise it by specifying colors and font size
-}
elmMinimalist : ColorValue a -> ColorValue b -> FontSize c -> ColorValue d -> List Css.Snippet
elmMinimalist backgroundColorArg codeBackgroundColorArg fontSizeArg colorArg =
    [ body
        [ padding zero
        , margin zero
        , height (pct 100)
        , backgroundColor backgroundColorArg
        , color colorArg
        , fontFamilies [ "calibri", "sans-serif" ]
        , fontSize fontSizeArg
        , fontWeight (int 400)
        ]
    , h1
        [ fontWeight (int 400)
        , fontSize (px 70)
        ]
    , section
        [ height (pct 100)
        , width (pct 100)
        , backgroundColor backgroundColorArg
        , backgroundPosition center
        , backgroundSize cover
        , displayFlex
        , justifyContent center
        , alignItems center
        ]
    , class "slide-content"
        [ margin2 zero (pct 10)
        ]
    , code
        [ textAlign left
        , fontSize fontSizeArg
        , backgroundColor codeBackgroundColorArg
        ]
    , pre
        [ padding (pct 2)
        , fontSize fontSizeArg
        , backgroundColor codeBackgroundColorArg
        ]
    , img
        [ width (pct 100)
        ]
    , ul
        [ margin (Css.rem 0.5)
        ]
    ]
