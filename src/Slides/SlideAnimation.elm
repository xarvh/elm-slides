module Slides.SlideAnimation exposing (..)

{-|

This module contains the functions used to animate the change from one slide to another,
and the types to create your own function.

# Slide animators
@docs scroll, fade

# Types
@docs Animator, Status, MotionDirection, RelativeOrder

-}

import Css exposing (px, pct)


{-| This is used to tell the slideAttributes function whether it is running on
    the slide that's coming into view or the one that's going away.
-}
type MotionDirection
    = Incoming
    | Outgoing


{-|
 Usually during an animation there will be two visible slides:
 this tells you the relative position of the two slides within the normal
 slide sequence.

 If you navigate from one slide to the next, the Outgoing slide will be
 the slide with the SmallerIndex, and the Incoming slide will be the slide
 with the LargerIndex.

 If instead you navigate backwards, from one slide to the previous, it
 will be the opposite.
-}
type RelativeOrder
    = SmallerIndex
    | LargerIndex


{-| Tells you what a visible slide is doing.
    The `Float` used by the `Moving` constructor is for the animation completion that runs between 0 and 1,
    0 when the animation hasn't yet started and 1 when it is completed.
-}
type Status
    = Still
    | Moving MotionDirection RelativeOrder Float


{-| Shorthand for the function type used to animate the slides.
The first argument describes the slide state: whether it is still or moving, and if the latter
in which direction and how much movement.

```
fade : SlideAttributes
fade status =
    let
        opacity =
            case status of
                Still -> 1
                Moving direction order completion ->
                    case direction of
                        Incoming -> completion
                        Outgoing -> 1 - completion
    in
        Css.asPairs
            [ Css.opacity (Css.num opacity) ]
```
-}
type alias Animator =
    Status -> List ( String, String )


{-| Scrolls the slide horizontally, right to left
-}
scroll : Animator
scroll status =
    let
        position =
            case status of
                Still ->
                    0

                Moving direction order completion ->
                    let
                        offset =
                            case order of
                                SmallerIndex ->
                                    0

                                LargerIndex ->
                                    100
                    in
                        offset - completion * 100
    in
        Css.asPairs
            [ Css.position Css.absolute
            , Css.width (pct 100)
            , Css.transform <| Css.translate (pct position)
            ]


{-| Fade in
-}
fade : Animator
fade status =
    let
        opacity =
            case status of
                Still ->
                    1

                Moving direction order completion ->
                    case direction of
                        Incoming ->
                            completion

                        Outgoing ->
                            1 - completion
    in
        Css.asPairs
            [ Css.opacity (Css.num opacity) ]
