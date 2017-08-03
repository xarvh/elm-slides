import Slides exposing (md, mdFragments, slidesDefaultOptions)
import Slides.Styles
import Slides.SlideAnimation
import List

import Css exposing (..)
import Css.Elements exposing (img)


main = Slides.app

    { slidesDefaultOptions
        | style = List.append
             [ img
                [ maxWidth (px 500)
                ]
             ]
             <| Slides.Styles.elmMinimalist (hex "#fff") (hex "#ccc") (px 16) (hex "#000")
        , slideAnimator = Slides.SlideAnimation.scroll
    }

    [ md
        """
        # Elm

        _Or: making functional programming accessible_

        by Francesco Orsenigo @xarvh

        """


    , mdFragments
        [   """
            I love the concepts behind functional programming.
            """

        ,   """
            So I tried to learn Haskell and Clojure.
            """

        ,   """
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
        $ elm-package install elm-lang/html
        ```

        And we're ready to go!

        """


    , md
        """

        # Single-step build

        ```elm
        $ elm-make HelloWorld.elm
        ```

        [➡]()

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
