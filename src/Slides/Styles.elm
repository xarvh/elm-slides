module Slides.Styles
    exposing
        ( blackOnWhite
        , elmBlueOnWhite
        , elmMinimalist
        , whiteOnBlack
        )

{-| A few ready made styles to use as `Options.style`.


# Elm Minimalist

A terse, clean style.
You can customise it by using `elmMinimalist` with the colors and font size you want,
use one of the presets, or [check the source](https://github.com/xarvh/elm-slides/blob/master/src/Slides/Styles.elm)
and using as starting template.

@docs elmMinimalist, elmBlueOnWhite, blackOnWhite, whiteOnBlack

-}

import Css exposing (..)
import Css.Global exposing (..)
import Html.Styled exposing (..)


{-| Elm Minimalist, white text on black background
-}
whiteOnBlack : List Snippet
whiteOnBlack =
    elmMinimalist (rgb 0 0 0) (rgb 230 230 230) (px 30) (rgb 255 255 255)


{-| Elm Minimalist, black text on white background
-}
blackOnWhite : List Snippet
blackOnWhite =
    elmMinimalist (rgb 255 255 255) (rgb 230 230 230) (px 30) (rgb 0 0 0)


{-| Elm Minimalist, Elm blue on white background
-}
elmBlueOnWhite : List Snippet
elmBlueOnWhite =
    elmMinimalist (rgb 255 255 255) (rgb 230 230 230) (px 30) (hex "60B5CC")


{-| A minimalist, clean style.
You can customise it by specifying the background color, the background color for
code samples, the font size, and finally the foreground color.
-}
elmMinimalist : ColorValue a -> ColorValue b -> FontSize c -> ColorValue d -> List Snippet
elmMinimalist backgroundColorArg codeBackgroundColorArg fontSizeArg colorArg =
    [ Css.Global.body
        [ padding zero
        , margin zero
        , height (pct 100)
        , backgroundColor backgroundColorArg
        , color colorArg
        , fontFamilies [ "calibri", "sans-serif" ]
        , fontSize fontSizeArg
        , fontWeight (int 400)
        ]
    , Css.Global.h1
        [ fontWeight (int 400)
        , fontSize (px 70)
        ]
    , Css.Global.section
        [ height (pct 100)
        , width (pct 100)
        , backgroundColor backgroundColorArg
        , backgroundPosition center
        , backgroundSize cover
        , displayFlex
        , justifyContent center
        , alignItems center
        ]
    , Css.Global.class "slide-content"
        [ margin2 zero (pct 10)
        ]
    , Css.Global.code
        [ textAlign left
        , fontSize fontSizeArg
        , backgroundColor codeBackgroundColorArg
        ]
    , Css.Global.pre
        [ padding (pct 2)
        , fontSize fontSizeArg
        , backgroundColor codeBackgroundColorArg
        ]
    , Css.Global.img
        [ width (pct 100)
        ]
    , Css.Global.ul
        [ margin (Css.rem 0.5)
        ]
    ]
