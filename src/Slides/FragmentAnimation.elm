module Slides.FragmentAnimation
    exposing
        ( Animator
        , fade
        )

{-| This module contains the functions used to animate the appearance
of a new slide fragment (or the hiding of an old one, if going backwards).


# Fragment animators

@docs fade


# Shorthand type

@docs Animator

-}

import Css exposing (Style)
import Slides.Blur


{-| Shorthand for the function type used to animate the fragments.

    fade : Animator
    fade completion =
        Css.batch
            [ Css.opacity (Css.num completion)
            , Css.property "filter" (Slides.Blur.blur completion)
            , Css.property "-webkit-filter" (Slides.Blur.blur completion)
            ]

-}
type alias Animator =
    Float -> Style


{-| Fade in
-}
fade : Animator
fade completion =
    Css.batch
        [ Css.opacity (Css.num completion)
        , Css.property "filter" (Slides.Blur.blur completion)
        , Css.property "-webkit-filter" (Slides.Blur.blur completion)
        ]
