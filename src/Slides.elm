module Slides
    exposing
        ( Action
        , Model
        , Msg
        , Options
        , Slide
        , actionToMsg
        , app
        , html
        , htmlFragments
        , init
        , md
        , mdFragments
        , slidesDefaultOptions
        , subscriptions
        , update
        , view
        )

{-|


# Main API

@docs app, Slide, md, mdFragments, html, htmlFragments


# Options

@docs Options, slidesDefaultOptions, Action


# Elm Architecture

Normally used with [Navigation.program](http://package.elm-lang.org/packages/elm-lang/navigation/1.0.0/Navigation#program)
@docs Msg, actionToMsg, Model, init, update, view, subscriptions

-}

import Array exposing (Array)
import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation exposing (Key)
import Css exposing (Style, pct, px)
import Css.Global
import Ease
import Html.Styled as Html exposing (Html, div, section)
import Html.Styled.Attributes exposing (class, css)
import Json.Decode exposing (Decoder)
import Markdown
import Slides.FragmentAnimation as FragmentAnimation
import Slides.SlideAnimation as SlideAnimation
import Slides.Styles
import SmoothAnimator
import String
import StringUnindent
import Task
import Url exposing (Url)


-- types


type alias PrivateSlide =
    { fragments : List (Html Msg)
    }


type alias Size =
    { width : Int
    , height : Int
    }


{-| -}
type Slide
    = Slide PrivateSlide


{-| The available actions, in case you want to remap the keys
-}
type Action
    = GotoFirst
    | GotoLast
    | GotoNext
    | GotoPrev
    | PauseAnimation


{-| This is in case you want to try something weird with the update function
-}
actionToMsg : Action -> Msg
actionToMsg =
    OnAction


{-| The TEA Msg
-}
type Msg
    = Noop
    | OnAction Action
    | AnimationTick Float
    | WindowResizes Size
    | OnUrlChange Url
    | OnClickLink Browser.UrlRequest



-- model


{-| -}
type Model
    = Model PrivateModel


type alias PrivateModel =
    { slides : Array PrivateSlide
    , windowSize : Size
    , isPaused : Bool
    , slideAnimation : SmoothAnimator.Model
    , fragmentAnimation : SmoothAnimator.Model
    , key : Key
    }


{-| Configuration options:

  - `style` &mdash; A list of [elm-css](http://package.elm-lang.org/packages/rtfeldman/elm-css/latest) `Snippets` to apply.
    Use [] if you want to use an external CSS.
    The `Slides.Style` module contains some preset styles ready to use.

  - `slideAnimator` &mdash; The function used to customize the slide animation.
    The `Slides.SlideAnimation` module contains some preset animators and the information for writing custom ones.

  - `fragmentAnimator` &mdash; the function used to animate a fragment within a slide.
    The `Slides.FragmentAnimation` module contains some preset animators and the information for writing custom ones.

  - `easingFunction` &mdash; Any f : [0, 1] -> [0, 1]
    The standard ones are available in Elm's [easing-functions](http://package.elm-lang.org/packages/elm-community/easing-functions/1.0.1/).

  - `animationDuration` &mdash; the duration in milliseconds of a slide or fragment animation.

  - `slidePixelSize` &mdash; `width` and `height` geometry of the slide area, in pixel.
    While the slide will be scaled to the window size, the internal coordinates of the slide will refer to these values.

  - `keysToActions` &mdash; a map of all Msg and the key codes that can trigger them.

-}
type alias Options =
    { title : String
    , style : List Css.Global.Snippet
    , slideAnimator : SlideAnimation.Animator
    , fragmentAnimator : FragmentAnimation.Animator
    , easingFunction : Ease.Easing
    , animationDuration : Float
    , slidePixelSize : { height : Int, width : Int }
    , keysToActions : List { action : Action, keys : List String }
    }



-- defaults


{-| Default configuration options.

    slidesDefaultOptions : Options
    slidesDefaultOptions =
        { title =
            "Presentation"
        , style =
            Slides.Styles.elmBlueOnWhite
        , slideAnimator =
            SlideAnimation.verticalDeck
        , fragmentAnimator =
            FragmentAnimation.fade
        , easingFunction =
            Ease.inOutCubic
        , animationDuration =
            500
        , slidePixelSize =
            { height = 700
            , width = 960
            }
        , keysToActions =
            [ { action = GotoFirst
              , keys = [ "Home" ]
              }
            , { action = GotoLast
              , keys = [ "End" ]
              }
            , { action = GotoNext
              , keys = [ "Enter", " ", "ArrowRight", "l", "d" ]
              }
            , { action = GotoPrev
              , keys = [ "Backspace", "ArrowLeft", "h", "a" ]
              }
            , { action = PauseAnimation
              , keys = [ "p" ]
              }
            ]
        }

-}
slidesDefaultOptions : Options
slidesDefaultOptions =
    { title =
        "Presentation"
    , style =
        Slides.Styles.elmBlueOnWhite
    , slideAnimator =
        SlideAnimation.verticalDeck
    , fragmentAnimator =
        FragmentAnimation.fade
    , easingFunction =
        Ease.inOutCubic
    , animationDuration =
        500
    , slidePixelSize =
        { height = 700
        , width = 960
        }
    , keysToActions =
        [ { action = GotoFirst
          , keys = [ "Home" ]
          }
        , { action = GotoLast
          , keys = [ "End" ]
          }
        , { action = GotoNext
          , keys = [ "Enter", " ", "ArrowRight", "l", "d" ]
          }
        , { action = GotoPrev
          , keys = [ "Backspace", "ArrowLeft", "h", "a" ]
          }
        , { action = PauseAnimation
          , keys = [ "p" ]
          }
        ]
    }



-- slide constructors


{-| Creates a single slide from a DOM node.

Can be used to create custom slides constructors (yes, it is used internally by `md` and `mdMarkdown`).

Note: `Html.Styled` is provided by [elm-css](https://package.elm-lang.org/packages/rtfeldman/elm-css/latest)

    import Html.Styled as Html exposing (..)

    slide1 =
        Slides.html <|
            div
                []
                [ h1 [] [ text "Hello, I am the slide header" ]
                , div [] [ text "and I am some content" ]
                ]

-}
html : Html Msg -> Slide
html htmlNode =
    htmlFragments [ htmlNode ]


{-| Creates a single slide made by several fragments, which are displayed in sequence, one after the other.

    slide2 =
        Slides.htmlFragments
            [ div [] [ text "I am always visible when the slide is visible" ]
            , div [] [ text "Then I appear" ]
            , div [] [ text "and then I appear!" ]
            ]

-}
htmlFragments : List (Html Msg) -> Slide
htmlFragments htmlNodes =
    Slide { fragments = htmlNodes }


{-| Creates a slide from a Markdown string.

It uses [elm-markdown](http://package.elm-lang.org/packages/evancz/elm-markdown/3.0.0/)
so you can enable syntax highlightning by including [highlight.js](https://highlightjs.org/).

It automatically removes indentation from multi-line strings.

    slide3 =
        Slides.md
            """
            # Hello! I am a header
            *and I am emph!*
            """

-}
md : String -> Slide
md markdownContent =
    mdFragments [ markdownContent ]


{-| Turns several Markdown strings into a single slide made by several fragments,
which will appear one after another:

    slide4 =
        Slides.mdFragments
            [ "I am always visible"
            , "Then I appear"
            , "and Then I"
            ]

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

        stringToMarkdown =
            StringUnindent.unindent
                >> Markdown.toHtmlWith options []
                >> Html.fromUnstyled

        htmlNodes =
            List.map stringToMarkdown markdownFragments
    in
    htmlFragments htmlNodes



-- helpers


scale : Options -> PrivateModel -> Float
scale options model =
    min
        (toFloat model.windowSize.width / toFloat options.slidePixelSize.width)
        (toFloat model.windowSize.height / toFloat options.slidePixelSize.height)


slideByIndex : PrivateModel -> Int -> PrivateSlide
slideByIndex model index =
    Array.get index model.slides |> Maybe.withDefault (PrivateSlide [])


slideDistance : PrivateModel -> Float
slideDistance model =
    toFloat model.slideAnimation.targetPosition - model.slideAnimation.currentPosition



-- update


noCmd : model -> ( model, Cmd a )
noCmd m =
    ( m, Cmd.none )


slideAnimatorUpdate : Options -> PrivateModel -> SmoothAnimator.Msg -> ( PrivateModel, Cmd Msg )
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
                cmdReplaceUrlWithCurrentSlideIndex newParentModel
    in
    ( newParentModel, cmd )


fragmentAnimatorUpdate : Int -> Options -> PrivateModel -> SmoothAnimator.Msg -> ( PrivateModel, Cmd Msg )
fragmentAnimatorUpdate maximumPosition options oldParentModel msg =
    let
        newChildModel =
            SmoothAnimator.update options.animationDuration maximumPosition msg oldParentModel.fragmentAnimation

        newParentModel =
            { oldParentModel | fragmentAnimation = newChildModel }
    in
    noCmd newParentModel


resetFragments : Float -> PrivateModel -> PrivateModel
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
update options msg (Model oldModel) =
    Tuple.mapFirst Model <|
        case msg of
            Noop ->
                noCmd oldModel

            OnAction action ->
                updateOnAction options action oldModel

            WindowResizes size ->
                noCmd <| { oldModel | windowSize = size }

            AnimationTick deltaTime ->
                if oldModel.isPaused then
                    noCmd oldModel
                else
                    let
                        distance =
                            slideDistance oldModel

                        ( m, cmd ) =
                            updateSlideOrFragmentAnimator options
                                { isAboutToChangeSlides = False }
                                (SmoothAnimator.AnimationTick deltaTime)
                                oldModel

                        newModel =
                            (if distance /= 0 then
                                resetFragments distance
                             else
                                identity
                            )
                                m
                    in
                    ( newModel, cmd )

            OnClickLink (Browser.Internal url) ->
                ( oldModel
                , Browser.Navigation.pushUrl oldModel.key (Url.toString url)
                )

            OnClickLink (Browser.External urlString) ->
                ( oldModel
                , Browser.Navigation.load urlString
                )

            OnUrlChange url ->
                updateOnUrl options url oldModel


updateSlideOrFragmentAnimator : Options -> { isAboutToChangeSlides : Bool } -> SmoothAnimator.Msg -> PrivateModel -> ( PrivateModel, Cmd Msg )
updateSlideOrFragmentAnimator options { isAboutToChangeSlides } animatorMsg model =
    let
        isAlreadyChangingSlides =
            slideDistance model /= 0
    in
    if isAlreadyChangingSlides || isAboutToChangeSlides then
        slideAnimatorUpdate options model animatorMsg
    else
        fragmentAnimatorUpdate (maximumSlidePosition model) options model animatorMsg


maximumSlidePosition : PrivateModel -> Int
maximumSlidePosition model =
    slideByIndex model model.slideAnimation.targetPosition
        |> .fragments
        |> List.length
        |> (+) -1


updateOnAction : Options -> Action -> PrivateModel -> ( PrivateModel, Cmd Msg )
updateOnAction options action model =
    case action of
        GotoFirst ->
            updateSlideOrFragmentAnimator options { isAboutToChangeSlides = True } SmoothAnimator.SelectFirst model

        GotoLast ->
            updateSlideOrFragmentAnimator options
                { isAboutToChangeSlides = True }
                SmoothAnimator.SelectLast
                model

        GotoPrev ->
            updateSlideOrFragmentAnimator options
                { isAboutToChangeSlides = model.fragmentAnimation.targetPosition - 1 < 0 }
                SmoothAnimator.SelectPrev
                model

        GotoNext ->
            updateSlideOrFragmentAnimator options
                { isAboutToChangeSlides = model.fragmentAnimation.targetPosition + 1 > maximumSlidePosition model }
                SmoothAnimator.SelectNext
                model

        PauseAnimation ->
            updateOnTogglePause model


updateOnTogglePause : PrivateModel -> ( PrivateModel, Cmd a )
updateOnTogglePause model =
    noCmd { model | isPaused = not model.isPaused }


updateOnUrl : Options -> Url -> PrivateModel -> ( PrivateModel, Cmd Msg )
updateOnUrl options url model =
    case url.fragment |> Maybe.andThen String.toInt of
        -- User entered an url we can't parse as index
        Nothing ->
            ( model
            , cmdReplaceUrlWithCurrentSlideIndex model
            )

        Just index ->
            slideAnimatorUpdate options model <| SmoothAnimator.SelectExact index


cmdReplaceUrlWithCurrentSlideIndex : PrivateModel -> Cmd a
cmdReplaceUrlWithCurrentSlideIndex model =
    ("#" ++ String.fromInt model.slideAnimation.targetPosition)
        |> Browser.Navigation.replaceUrl model.key



-- init


{-| -}
init : Options -> List Slide -> () -> Url -> Key -> ( Model, Cmd Msg )
init options wrappedSlides flags url key =
    let
        unwrapSlide (Slide privateSlide) =
            privateSlide

        ( model, urlCmd ) =
            updateOnUrl
                options
                url
                { slides = wrappedSlides |> List.map unwrapSlide |> Array.fromList
                , windowSize = options.slidePixelSize
                , isPaused = False
                , slideAnimation = SmoothAnimator.init 0
                , fragmentAnimation = SmoothAnimator.init 0
                , key = key
                }

        slidePosition0 =
            model.slideAnimation.targetPosition

        slideAnimation =
            SmoothAnimator.init slidePosition0

        cmdWindow =
            Task.perform (viewportToWindowSize >> WindowResizes) Browser.Dom.getViewport
    in
    ( Model { model | slideAnimation = slideAnimation }
    , Cmd.batch [ cmdWindow, urlCmd ]
    )


viewportToWindowSize : Browser.Dom.Viewport -> Size
viewportToWindowSize { viewport } =
    { width = round viewport.width
    , height = round viewport.height
    }



-- view


slideSection : Style -> List (Html msg) -> Html msg
slideSection style fragments =
    section
        [ css [ style ] ]
        [ div
            [ class "slide-content" ]
            fragments
        ]


fragmentsByPosition : Options -> PrivateModel -> Int -> Float -> List (Html Msg)
fragmentsByPosition options model slideIndex fragmentPosition =
    let
        slide =
            slideByIndex model slideIndex

        completionByIndex fragmentIndex =
            clamp 0 1 <| 1 + fragmentPosition - toFloat fragmentIndex

        styleFrag fragmentIndex frag =
            div
                [ class "fragment-content" ]
                [ div
                    [ css [ options.fragmentAnimator <| completionByIndex fragmentIndex ] ]
                    [ frag ]
                ]
    in
    List.indexedMap styleFrag slide.fragments


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


slideViewStill : Options -> PrivateModel -> List (Html Msg)
slideViewStill options model =
    [ slideSection (options.slideAnimator SlideAnimation.Still) <|
        fragmentsByPosition options model model.slideAnimation.targetPosition model.fragmentAnimation.currentPosition
    ]


{-| -}
view : Options -> Model -> Browser.Document Msg
view options (Model model) =
    let
        slideView =
            if slideDistance model == 0 then
                slideViewStill
            else
                slideViewMotion
    in
    { title = options.title
    , body =
        [ Css.Global.global options.style
        , div
            [ class "slides"
            , css
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
            |> List.map Html.toUnstyled
    }



-- subscriptions


mousePositionDecoder : ({ x : Int, y : Int } -> msg) -> Decoder msg
mousePositionDecoder msg =
    Json.Decode.map2 (\x y -> msg { x = x, y = y })
        (Json.Decode.field "clientX" Json.Decode.int)
        (Json.Decode.field "clientY" Json.Decode.int)


mouseClickDispatcher : Options -> PrivateModel -> { x : Int, y : Int } -> Action
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
        GotoPrev
    else
        GotoNext



-- TODO: Add support for touch/swipe


{-| -}
subscriptions : Options -> Model -> Sub Msg
subscriptions options (Model model) =
    Sub.batch
        [ Browser.Events.onKeyUp (keyboardDecoder (keyNameToMsgDecoder options.keysToActions))
        , Browser.Events.onClick (mousePositionDecoder (mouseClickDispatcher options model >> OnAction))
        , Browser.Events.onResize (\w h -> WindowResizes { width = w, height = h })
        , Browser.Events.onAnimationFrameDelta AnimationTick
        ]


keyboardDecoder : (String -> Decoder msg) -> Decoder msg
keyboardDecoder stringToMsgDecoder =
    Json.Decode.string
        |> Json.Decode.field "key"
        |> Json.Decode.andThen stringToMsgDecoder


keyNameToMsgDecoder : List { action : Action, keys : List String } -> String -> Decoder Msg
keyNameToMsgDecoder keyMap keyName =
    case keyMap of
        [] ->
            Json.Decode.fail ""

        keyMapEntry :: km ->
            if List.member (String.toLower keyName) (List.map String.toLower keyMapEntry.keys) then
                Json.Decode.succeed (OnAction keyMapEntry.action)
            else
                keyNameToMsgDecoder km keyName


singleToUpper : String -> String
singleToUpper s =
    if String.length s /= 1 then
        s
    else
        String.toUpper s



-- `main` helper


{-| Does all the wiring for you, returning a `Program` ready to run.

    main =
        Slides.app
            Slides.slidesDefaultOptions
            [ slide1
            , slide2
            , ...
            ]

-}
app : Options -> List Slide -> Program () Model Msg
app options slides =
    Browser.application
        { init = init options slides
        , update = update options
        , view = view options
        , subscriptions = subscriptions options
        , onUrlRequest = OnClickLink
        , onUrlChange = OnUrlChange
        }
