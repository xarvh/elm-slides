module Slides
    exposing
        ( Message(..)
        , Model
        , program
        , app
        , Options
        , slidesDefaultOptions
        , md
        , mdFragments
        , html
        , htmlFragments
        )

{-|
# Main API
@docs app, html, htmlFragments, md, mdFragments

# Options
@docs Options, slidesDefaultOptions

# Elm Architecture
@docs Message, Model, program
-}

import AnimationFrame
import Array exposing (Array)
import Css exposing (px, pct)
import Ease
import Slides.FragmentAnimation as FragmentAnimation
import Html exposing (Html, div, section)
import Html.Attributes exposing (class)
import Html.App as App
import Keyboard
import Markdown
import Mouse
import Navigation
import Slides.SlideAnimation as SlideAnimation
import SmoothAnimator
import String
import StringUnindent
import Task
import Time
import Window


--
-- Model
--


{-|
The Slides model.
Contains all the state of the app, including the slides list itself, the current configuration options
and all the information needed for the slides and fragments animations.
-}
type alias Model =
    { slides : Array Slide
    , windowSize : Window.Size
    , isPaused : Bool
    , slideAnimation : SmoothAnimator.Model
    , fragmentAnimation : SmoothAnimator.Model
    }


{-|
Configuration options:

* `slideAnimator` &mdash; The function used to customize the slide animation.
  The Slides.SlideAnimation module contains some preset animators and the information for writing custom ones.

* `fragmentAnimator` &mdash; the function used to animate a fragment within a slide.
  The Slides.FragmentAnimation module contains some preset animators and the information for writing custom ones.

* `easingFunction` &mdash; Any f : [0, 1] -> [0, 1]
  The standard ones are available in Elm's [easing-functions](http://package.elm-lang.org/packages/elm-community/easing-functions/1.0.1/).

* `animationDuration` &mdash; the `Time` duration of a slide or fragment animation.

* `slidePixelSize` &mdash; `width` and `height` geometry of the slide area, in pixel.
   While the slide will be scaled to the window size, the internal coordinates of the slide will refer to these values.

* `keyCodesToMessage` &mdash; a map of all Messages and the key codes that can trigger them.
-}
type alias Options =
    { slideAnimator : SlideAnimation.Animator
    , fragmentAnimator : FragmentAnimation.Animator
    , easingFunction : Float -> Float
    , animationDuration : Time.Time
    , slidePixelSize : { height : Int, width : Int }
    , keyCodesToMessage : List { message : Message, keyCodes : List Int }
    }


type alias Slide =
    { fragments : List (Html Message)
    }



--
-- Messages
--


{-| The Elm-architecture Msgs.
-}
type Message
    = Noop
    | First
    | Last
    | Next
    | Prev
    | AnimationTick Time.Time
    | PauseAnimation
    | WindowResizes Window.Size



--
-- Defaults
--


{-| Default configuration options.

    ```
    ```
-}
slidesDefaultOptions : Options
slidesDefaultOptions =
    { slideAnimator =
        SlideAnimation.scroll
    , fragmentAnimator =
        FragmentAnimation.fade
    , easingFunction =
        Ease.inOutCubic
    , animationDuration =
        500 * Time.millisecond
    , slidePixelSize =
        { height = 700
        , width = 960
        }
    , keyCodesToMessage =
        [ { message = First
          , keyCodes =
                [ 36 ]
                -- Home
          }
        , { message = Last
          , keyCodes =
                [ 35 ]
                -- End
          }
        , { message = Next
          , keyCodes =
                [ 13, 32, 39, 76, 68 ]
                -- Enter, Spacebar, Arrow Right, l, d
          }
        , { message = Prev
          , keyCodes =
                [ 37, 72, 65 ]
                -- Arrow Left, h, a
          }
        , { message = PauseAnimation
          , keyCodes = [ 80 ]
          }
        ]
    }



--
-- API: Html slide constructor
--


{-|
Creates a single slide from a DOM node.

Can be used to create custom slides constructors (yes, it is used internally by `md` and `mdMarkdown`).
```
import Html exposing (..)

slide1 = html <|
     div
        []
        [ h1 [] [ text "Hello, I am the slide header" ]
        , div [] [ text "and I am some content" ]
        ]
```
-}
html : Html Message -> Slide
html htmlNode =
    htmlFragments [ htmlNode ]


{-|
Creates a single slide made by several fragments, which are displayed in sequence, one after the other.
```
slide2 = htmlFragments
    [ div [] [ text "I am always visible when the slide is visible" ]
    , div [] [ text "Then I appear"
    , div [] [ text "and then I appear!"
    ]
```
-}
htmlFragments : List (Html Message) -> Slide
htmlFragments htmlNodes =
    { fragments = htmlNodes }



--
-- API: Markdown slide constructor
--


{-|
Creates a slide from a Markdown string.

It uses [elm-markdown](http://package.elm-lang.org/packages/evancz/elm-markdown/3.0.0/)
so you can enable syntax highlightning by including [highlight.js](https://highlightjs.org/).

It automatically removes indentation from multi-line strings.

```
slide3 = md
    """
    # Hello! I am a header
    *and I am emph!*
    """
```
-}
md : String -> Slide
md markdownContent =
    mdFragments [ markdownContent ]


{-|
Turns several Markdown strings into a single slide made by several fragments,
which will appear one after another:
```
slide4 = mdFragments
    [ "I am always visible"
    , "Then I appear"
    , "and Then I"
    ]
```
-}
mdFragments : List String -> Slide
mdFragments markdownFragments =
    let
        markdownDefaultOptions =
            Markdown.defaultOptions

        options =
            { markdownDefaultOptions
                | githubFlavored = Just { tables = True, breaks = False }
                , defaultHighlighting = Nothing
                , smartypants = True
            }

        htmlNodes =
            List.map (Markdown.toHtmlWith options [] << StringUnindent.unindent) markdownFragments
    in
        htmlFragments htmlNodes



--
-- Helpers
--


scale : Options -> Model -> Float
scale options model =
    min
        (toFloat model.windowSize.width / toFloat options.slidePixelSize.width)
        (toFloat model.windowSize.height / toFloat options.slidePixelSize.height)


locationToSlideIndex : Navigation.Location -> Maybe Int
locationToSlideIndex location =
    String.dropLeft 1 location.hash |> String.toInt |> Result.toMaybe


modelToHashUrl : Model -> String
modelToHashUrl model =
    "#" ++ toString model.slideAnimation.targetPosition


slideByIndex : Model -> Int -> Slide
slideByIndex model index =
    Maybe.withDefault (md "") <| Array.get index model.slides


slideDistance : Model -> Float
slideDistance model =
    toFloat model.slideAnimation.targetPosition - model.slideAnimation.currentPosition



--
-- Update
--


slideAnimatorUpdate : Options -> Model -> SmoothAnimator.Message -> ( Model, Cmd Message )
slideAnimatorUpdate options oldParentModel childMessage =
    let
        duration =
            options.animationDuration

        maximumPosition =
            Array.length oldParentModel.slides - 1

        newChildModel =
            SmoothAnimator.update duration maximumPosition childMessage oldParentModel.slideAnimation

        newParentModel =
            { oldParentModel | slideAnimation = newChildModel }

        currentIndexInUrl =
            case childMessage of
                -- user entered a new url manually, which may be out of bounds
                SmoothAnimator.SelectExact indexFromUrl ->
                    indexFromUrl

                -- url reflects old index
                _ ->
                    oldParentModel.slideAnimation.targetPosition

        cmd =
            if newChildModel.targetPosition == currentIndexInUrl then
                Cmd.none
            else
                Navigation.newUrl <| modelToHashUrl newParentModel
    in
        ( newParentModel, cmd )


fragmentAnimatorUpdate : Int -> Options -> Model -> SmoothAnimator.Message -> ( Model, Cmd Message )
fragmentAnimatorUpdate maximumPosition options oldParentModel message =
    let
        newChildModel =
            SmoothAnimator.update options.animationDuration maximumPosition message oldParentModel.fragmentAnimation

        newParentModel =
            { oldParentModel | fragmentAnimation = newChildModel }
    in
        ( newParentModel, Cmd.none )


resetFragments : Float -> Model -> Model
resetFragments distance oldModel =
    let
        newPosition =
            if distance > 0 then
                0
            else
                List.length (slideByIndex oldModel oldModel.slideAnimation.targetPosition).fragments - 1
    in
        { oldModel | fragmentAnimation = SmoothAnimator.init newPosition }


update : Options -> Message -> Model -> ( Model, Cmd Message )
update options message oldModel =
    let
        noCmd m =
            ( m, Cmd.none )

        maximumPosition =
            List.length (slideByIndex oldModel oldModel.slideAnimation.targetPosition).fragments - 1

        isAlreadyChangingSlides =
            slideDistance oldModel /= 0

        mixedUpdater isAboutToChangeSlides message =
            if isAlreadyChangingSlides || isAboutToChangeSlides then
                slideAnimatorUpdate options oldModel message
            else
                fragmentAnimatorUpdate maximumPosition options oldModel message
    in
        case message of
            Noop ->
                noCmd oldModel

            First ->
                mixedUpdater True SmoothAnimator.SelectFirst

            Last ->
                mixedUpdater True SmoothAnimator.SelectLast

            Prev ->
                mixedUpdater (oldModel.fragmentAnimation.targetPosition - 1 < 0) SmoothAnimator.SelectPrev

            Next ->
                mixedUpdater (oldModel.fragmentAnimation.targetPosition + 1 > maximumPosition) SmoothAnimator.SelectNext

            WindowResizes size ->
                noCmd <| { oldModel | windowSize = size }

            PauseAnimation ->
                noCmd { oldModel | isPaused = not oldModel.isPaused }

            AnimationTick deltaTime ->
                if oldModel.isPaused then
                    noCmd oldModel
                else
                    let
                        distance =
                            slideDistance oldModel

                        ( m, cmd ) =
                            mixedUpdater False (SmoothAnimator.AnimationTick deltaTime)

                        newModel =
                            (if distance /= 0 then
                                resetFragments distance
                             else
                                identity
                            )
                                m
                    in
                        ( newModel, cmd )


urlUpdate : Options -> Navigation.Location -> Model -> ( Model, Cmd Message )
urlUpdate options location model =
    case locationToSlideIndex location of
        -- User entered an url we can't parse as index
        Nothing ->
            ( model, Navigation.modifyUrl <| modelToHashUrl model )

        Just index ->
            slideAnimatorUpdate options model <| SmoothAnimator.SelectExact index



--
-- Init
--


init : Options -> List Slide -> Navigation.Location -> ( Model, Cmd Message )
init options slides location =
    let
        model0 =
            { slides = Array.fromList slides
            , windowSize = options.slidePixelSize
            , isPaused = False
            , slideAnimation = SmoothAnimator.init 0
            , fragmentAnimation = SmoothAnimator.init 0
            }

        ( model, urlCmd ) =
            urlUpdate options location model0

        slidePosition0 =
            model.slideAnimation.targetPosition

        slideAnimation =
            SmoothAnimator.init slidePosition0

        cmdWindow =
            Task.perform (\_ -> Noop) WindowResizes Window.size
    in
        ( { model | slideAnimation = slideAnimation }, Cmd.batch [ cmdWindow, urlCmd ] )



--
-- View
--


slideSection styleAttributes fragments =
    section
        [ Html.Attributes.style styleAttributes ]
        [ div
            [ class "slide-content" ]
            fragments
        ]


fragmentsByPosition options model index fragmentPosition =
    let
        slide =
            slideByIndex model index

        completionByIndex index =
            (clamp 0 1 <| 1 + fragmentPosition - toFloat index)

        styleFrag index frag =
            div
                [ class "fragment-content" ]
                [ div
                    [ Html.Attributes.style (options.fragmentAnimator <| completionByIndex index) ]
                    [ frag ]
                ]

        styledFragments =
            List.indexedMap styleFrag slide.fragments
    in
        styledFragments


slideViewMotion options model =
    let
        distance =
            slideDistance model

        easing =
            if abs distance > 1 then
                identity
            else if distance >= 0 then
                options.easingFunction
            else
                Ease.flip options.easingFunction

        smallerIndex =
            -- HACK: When Prev has *just* been called, currentPosition will be
            -- an integer and floor() will return it verbatim.
            floor <|
                model.slideAnimation.currentPosition
                    - (if distance > 0 then
                        0
                       else
                        0.000001
                      )

        largerIndex =
            smallerIndex + 1

        -- directions for the slide with the smaller index and the slide with the larger index
        ( smallerDirection, largerDirection ) =
            if distance > 0 then
                ( SlideAnimation.Outgoing, SlideAnimation.Incoming )
            else
                ( SlideAnimation.Incoming, SlideAnimation.Outgoing )

        completion =
            easing <| model.slideAnimation.currentPosition - toFloat smallerIndex

        slideAnimator =
            options.slideAnimator

        fragByPos =
            fragmentsByPosition options model
    in
        [ slideSection (slideAnimator <| SlideAnimation.Moving smallerDirection SlideAnimation.SmallerIndex completion) (fragByPos smallerIndex 9999)
        , slideSection (slideAnimator <| SlideAnimation.Moving largerDirection SlideAnimation.LargerIndex completion) (fragByPos largerIndex 0)
        ]


slideViewStill options model =
    [ slideSection (options.slideAnimator SlideAnimation.Still) <|
        fragmentsByPosition options model model.slideAnimation.targetPosition model.fragmentAnimation.currentPosition
    ]


view : Options -> Model -> Html Message
view options model =
    let
        slideView =
            if slideDistance model == 0 then
                slideViewStill
            else
                slideViewMotion
    in
        div
            [ class "slides"
            , (Html.Attributes.style << Css.asPairs)
                [ Css.width (px <| toFloat options.slidePixelSize.width)
                , Css.height (px <| toFloat options.slidePixelSize.height)
                , Css.transforms [ Css.translate2 (pct -50) (pct -50), Css.scale (scale options model) ]
                , Css.left (pct 50)
                , Css.top (pct 50)
                , Css.bottom Css.auto
                , Css.right Css.auto
                , Css.position Css.absolute
                , Css.overflow Css.hidden
                ]
            ]
            (slideView options model)



--
-- Subscriptions
--


keyPressDispatcher keyCodeMap keyCode =
    case keyCodeMap of
        x :: xs ->
            if List.member keyCode x.keyCodes then
                x.message
            else
                keyPressDispatcher xs keyCode

        _ ->
            Noop


mouseClickDispatcher : Options -> Model -> Mouse.Position -> Message
mouseClickDispatcher options model position =
    let
        s =
            scale options model

        slide component =
            s * toFloat (component options.slidePixelSize)

        window component =
            toFloat <| component model.windowSize

        h =
            slide .height

        w =
            slide .width

        hh =
            window .height

        ww =
            window .width

        {-
           Equation of the straigh line that passes through the slide's bottom left corner and top right corner.

           +------------>
           |       /
           |   +--/
           |   | /|
           |   |/ |
           |   /--+
           v  /
        -}
        y x =
            (-x / w + (ww - w) / (2 * w) + (hh + h) / (2 * h)) * h

        isAbove =
            toFloat position.y < y (toFloat position.x)
    in
        if isAbove then
            Prev
        else
            Next



-- TODO: Add support for touch/swipe


subscriptions options model =
    Sub.batch
        -- TODO: switch to Keyboard.presses once https://github.com/elm-lang/keyboard/issues/3 is fixed
        [ Keyboard.ups (keyPressDispatcher options.keyCodesToMessage)
        , Mouse.clicks <| mouseClickDispatcher options model
        , Window.resizes WindowResizes
        , AnimationFrame.diffs AnimationTick
        ]



--
-- `main` helper
--


{-|
This provides you with all the standard functions used in the Elm architecture (`init`, `update`, `view`, `subscriptions`)
plus the one used for URL navigation (`urlUpdate`).

This allows you to embed a Slides app inside another Elm app or, more importantly, to have full control of how the app behaves.
-}
program :
    Options
    -> List Slide
    -> { init : Navigation.Location -> ( Model, Cmd Message )
       , update : Message -> Model -> ( Model, Cmd Message )
       , urlUpdate : Navigation.Location -> Model -> ( Model, Cmd Message )
       , view : Model -> Html Message
       , subscriptions : Model -> Sub Message
       }
program options slides =
    { init = init options slides
    , update = update options
    , urlUpdate = urlUpdate options
    , view = view options
    , subscriptions = subscriptions options
    }


{-|
Does all the wiring for you, returning a `Program` ready to run.
```
main = app
    slidesDefaultOptions
    [ slide1
    , slide2
    , ...
    ]
```
-}
app : Options -> List Slide -> Program Never
app options slides =
    Navigation.program (Navigation.makeParser identity) (program options slides)
