module Slides
    exposing
        ( app
        , Options
        , slidesDefaultOptions
        , md
        , mdFragments
        , html
        , htmlFragments
          -- TEA
        , Msg(..)
        , Model
        , init
        , update
        , view
        , subscriptions
        )

{-|
# Main API
@docs app, md, mdFragments, html, htmlFragments

# Options
@docs Options, slidesDefaultOptions

# Elm Architecture
Normally used with [Navigation.program](http://package.elm-lang.org/packages/elm-lang/navigation/1.0.0/Navigation#program)
@docs Msg, Model, init, update, view, subscriptions
-}

import AnimationFrame
import Array exposing (Array)
import Css exposing (px, pct)
import Ease
import Slides.FragmentAnimation as FragmentAnimation
import Html exposing (Html, div, section)
import Html.Attributes exposing (class)
import Keyboard
import Markdown
import Mouse
import Navigation
import Slides.SlideAnimation as SlideAnimation
import Slides.Styles
import SmoothAnimator
import String
import StringUnindent
import Task
import Time
import Window


--
-- Model
--


{-| -}
type alias Model =
    { slides : Array Slide
    , windowSize : Window.Size
    , isPaused : Bool
    , slideAnimation : SmoothAnimator.Model
    , fragmentAnimation : SmoothAnimator.Model
    }


{-|
Configuration options:

* `style` &mdash; A list of [elm-css](http://package.elm-lang.org/packages/rtfeldman/elm-css/latest) `Snippets` to apply.
  Use [] if you want to use an external CSS.
  The `Slides.Style` module contains some preset styles ready to use.

* `slideAnimator` &mdash; The function used to customize the slide animation.
  The `Slides.SlideAnimation` module contains some preset animators and the information for writing custom ones.

* `fragmentAnimator` &mdash; the function used to animate a fragment within a slide.
  The `Slides.FragmentAnimation` module contains some preset animators and the information for writing custom ones.

* `easingFunction` &mdash; Any f : [0, 1] -> [0, 1]
  The standard ones are available in Elm's [easing-functions](http://package.elm-lang.org/packages/elm-community/easing-functions/1.0.1/).

* `animationDuration` &mdash; the `Time` duration of a slide or fragment animation.

* `slidePixelSize` &mdash; `width` and `height` geometry of the slide area, in pixel.
   While the slide will be scaled to the window size, the internal coordinates of the slide will refer to these values.

* `keyCodesToMsg` &mdash; a map of all Msg and the key codes that can trigger them.
-}
type alias Options =
    { style : List Css.Snippet
    , slideAnimator : SlideAnimation.Animator
    , fragmentAnimator : FragmentAnimation.Animator
    , easingFunction : Float -> Float
    , animationDuration : Time.Time
    , slidePixelSize : { height : Int, width : Int }
    , keyCodesToMsg : List { msg : Msg, keyCodes : List Int }
    }


type alias Slide =
    { fragments : List (Html Msg)
    }



--
-- Msg
--


{-| -}
type Msg
    = Noop
    | First
    | Last
    | Next
    | Prev
    | AnimationTick Time.Time
    | PauseAnimation
    | WindowResizes Window.Size
    | NewLocation Navigation.Location



--
-- Defaults
--


{-|

Default configuration options.

```
slidesDefaultOptions =
    { style =
        Slides.Styles.elmBlueOnWhite
    , slideAnimator =
        SlideAnimation.verticalDeck
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
    , keyCodesToMsg =
        [ { msg = First
          , keyCodes =
                [ 36 ]
                -- Home
          }
        , { msg = Last
          , keyCodes =
                [ 35 ]
                -- End
          }
        , { msg = Next
          , keyCodes =
                [ 13, 32, 39, 76, 68 ]
                -- Enter, Spacebar, Arrow Right, l, d
          }
        , { msg = Prev
          , keyCodes =
                [ 37, 72, 65 ]
                -- Arrow Left, h, a
          }
        , { msg = PauseAnimation
          , keyCodes = [ 80 ]
          }
        ]
    }
```
-}
slidesDefaultOptions : Options
slidesDefaultOptions =
    { style =
        Slides.Styles.elmBlueOnWhite
    , slideAnimator =
        SlideAnimation.verticalDeck
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
    , keyCodesToMsg =
        [ { msg = First
          , keyCodes =
                [ 36 ]
                -- Home
          }
        , { msg = Last
          , keyCodes =
                [ 35 ]
                -- End
          }
        , { msg = Next
          , keyCodes =
                [ 13, 32, 39, 76, 68 ]
                -- Enter, Spacebar, Arrow Right, l, d
          }
        , { msg = Prev
          , keyCodes =
                [ 37, 72, 65 ]
                -- Arrow Left, h, a
          }
        , { msg = PauseAnimation
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

slide1 = Slides.html <|
     div
        []
        [ h1 [] [ text "Hello, I am the slide header" ]
        , div [] [ text "and I am some content" ]
        ]
```
-}
html : Html Msg -> Slide
html htmlNode =
    htmlFragments [ htmlNode ]


{-|
Creates a single slide made by several fragments, which are displayed in sequence, one after the other.
```
slide2 = Slides.htmlFragments
    [ div [] [ text "I am always visible when the slide is visible" ]
    , div [] [ text "Then I appear"
    , div [] [ text "and then I appear!"
    ]
```
-}
htmlFragments : List (Html Msg) -> Slide
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
slide3 = Slides.md
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
slide4 = Slides.mdFragments
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


slideAnimatorUpdate : Options -> Model -> SmoothAnimator.Msg -> ( Model, Cmd Msg )
slideAnimatorUpdate options oldParentModel childMsg =
    let
        duration =
            options.animationDuration

        maximumPosition =
            Array.length oldParentModel.slides - 1

        newChildModel =
            SmoothAnimator.update duration maximumPosition childMsg oldParentModel.slideAnimation

        newParentModel =
            { oldParentModel | slideAnimation = newChildModel }

        currentIndexInUrl =
            case childMsg of
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


fragmentAnimatorUpdate : Int -> Options -> Model -> SmoothAnimator.Msg -> ( Model, Cmd Msg )
fragmentAnimatorUpdate maximumPosition options oldParentModel msg =
    let
        newChildModel =
            SmoothAnimator.update options.animationDuration maximumPosition msg oldParentModel.fragmentAnimation

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


{-| -}
update : Options -> Msg -> Model -> ( Model, Cmd Msg )
update options msg oldModel =
    let
        noCmd m =
            ( m, Cmd.none )

        maximumPosition =
            List.length (slideByIndex oldModel oldModel.slideAnimation.targetPosition).fragments - 1

        isAlreadyChangingSlides =
            slideDistance oldModel /= 0

        mixedUpdater isAboutToChangeSlides msg =
            if isAlreadyChangingSlides || isAboutToChangeSlides then
                slideAnimatorUpdate options oldModel msg
            else
                fragmentAnimatorUpdate maximumPosition options oldModel msg
    in
        case msg of
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

            NewLocation location ->
                case locationToSlideIndex location of
                    -- User entered an url we can't parse as index
                    Nothing ->
                        ( oldModel, Navigation.modifyUrl <| modelToHashUrl oldModel )

                    Just index ->
                        slideAnimatorUpdate options oldModel <| SmoothAnimator.SelectExact index


--
-- Init
--


{-| -}
init : Options -> List Slide -> Navigation.Location -> ( Model, Cmd Msg )
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
            update options (NewLocation location) model0

        slidePosition0 =
            model.slideAnimation.targetPosition

        slideAnimation =
            SmoothAnimator.init slidePosition0

        cmdWindow =
            Task.perform WindowResizes Window.size
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
        [ slideSection (slideAnimator <| SlideAnimation.Moving smallerDirection SlideAnimation.EarlierSlide completion) (fragByPos smallerIndex 9999)
        , slideSection (slideAnimator <| SlideAnimation.Moving largerDirection SlideAnimation.LaterSlide completion) (fragByPos largerIndex 0)
        ]


slideViewStill options model =
    [ slideSection (options.slideAnimator SlideAnimation.Still) <|
        fragmentsByPosition options model model.slideAnimation.targetPosition model.fragmentAnimation.currentPosition
    ]


{-| -}
view : Options -> Model -> Html Msg
view options model =
    let
        slideView =
            if slideDistance model == 0 then
                slideViewStill
            else
                slideViewMotion

        css =
            options.style
                |> Css.stylesheet
                |> flip (::) []
                |> Css.compile
                |> .css
    in
        div
            []
            [ Html.node "style"
                []
                [ Html.text css ]
            , div
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
            ]



--
-- Subscriptions
--


keyPressDispatcher keyCodeMap keyCode =
    case keyCodeMap of
        x :: xs ->
            if List.member keyCode x.keyCodes then
                x.msg
            else
                keyPressDispatcher xs keyCode

        _ ->
            Noop


mouseClickDispatcher : Options -> Model -> Mouse.Position -> Msg
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


{-| -}
subscriptions : Options -> Model -> Sub Msg
subscriptions options model =
    Sub.batch
        -- TODO: switch to Keyboard.presses once https://github.com/elm-lang/keyboard/issues/3 is fixed
        [ Keyboard.ups (keyPressDispatcher options.keyCodesToMsg)
        , Mouse.clicks <| mouseClickDispatcher options model
        , Window.resizes WindowResizes
        , AnimationFrame.diffs AnimationTick
        ]



--
-- `main` helper
--


{-|
Does all the wiring for you, returning a `Program` ready to run.
```
main = Slides.app
    Slides.slidesDefaultOptions
    [ slide1
    , slide2
    , ...
    ]
```
-}
app : Options -> List Slide -> Program Never Model Msg
app options slides =
    Navigation.program
        NewLocation
        { init = init options slides
        , update = update options
        , view = view options
        , subscriptions = subscriptions options
        }
