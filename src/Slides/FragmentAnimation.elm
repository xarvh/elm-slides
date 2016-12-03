module Slides.FragmentAnimation exposing (..)

{-|

This module contains the functions used to animate the appearance
of a new slide fragment (or the hiding of an old one, if going backwards).

# Fragment animators
@docs fade

# Shorthand type
@docs Animator
-}

import Css


{-| Shorthand for the function type used to animate the fragments.

```
fade : Animator
fade completion =
    [ ( "opacity", toString completion ) ]
```
-}
type alias Animator =
    Float -> List ( String, String )


{-| Fade in
-}
fade : Animator
fade completion =
    let
        blur completion =
            "blur(" ++ (toString <| Basics.round <| (1 - completion) * 20) ++ "px)"
    in
        Css.asPairs
            [ Css.opacity (Css.num completion)
            , Css.property "filter" (blur completion)
            , Css.property "-webkit-filter" (blur completion)
            ]
