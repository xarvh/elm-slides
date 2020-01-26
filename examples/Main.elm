module Main exposing (main)

import Css exposing (..)
import Css.Global exposing (img)
import List
import Slides exposing (md, mdFragments, slidesDefaultOptions)
import Slides.SlideAnimation
import Slides.Styles


main =
    Slides.app
        { slidesDefaultOptions
            | slideAnimator =
                Slides.SlideAnimation.scroll
            , style =
                let
                    imgWidthSnippet =
                        img [ maxWidth (px 500) ]

                    baseStyleSnippets =
                        Slides.Styles.elmMinimalist (hex "#fff") (hex "#ccc") (px 16) (hex "#000")
                in
                imgWidthSnippet :: baseStyleSnippets
        }
        [ md
            """
            # Elm

            _Or: making functional programming accessible_

            by Francesco Orsenigo @xarvh

            """
        , mdFragments
            [ """
              I love the concepts behind functional programming.
              """
            , """
              So I tried to learn Haskell and Clojure.
              """
            , """
              They are great languages, but I struggled every time
              I wanted to go past a tutorial.
              """
            ]
        , md
            """
            I tried Elm and I was happily reimplementing my own projects
            in Elm shortly afterwards.
            """
        , md
            """
            How can we improve other FP languages?

            What is Elm doing right?
            """
        , md
            """

            # Easy app setup

            ```elm
            $ elm install elm-lang/html
            ```

            And we're ready to go!

            """
        , md
            """

            # Single-step build

            ```elm
            $ elm make HelloWorld.elm
            ```

            ➡

            ```elm
            index.html
            ```
            """
        , md
            """
            # Accessible docs

            Inline docs are displayed on http://package.elm-lang.org/

            elm-package will refuse to publish anything without docs!
            """
        , md
            """
            # Official libraries for most common tasks

            * Virtual DOM
            * SVG rendering
            * Markdown
            * Http
            * Geolocation
            * Websockets
            """
        , md
            """

            @xarvh

            """
        ]
