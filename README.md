Slides
======

Slides is an awesome Elm presentation framework, inspired by [reveal.js](http://lab.hakim.se/reveal-js/).

[See it running](http://xarvh.github.io/talk-elm/).

```elm
import Slides exposing (..)


main = Slides.app

    slidesDefaultOptions

    [ md
        """
        # A markdown slide
        _stuff follows..._
        """

    , mdFragments
        [ "Another slide with three fragments"
        , "This appears later"
        , "And this even later"
        ]
    ]
```

Slides is customizable and, since it follows the [Elm Architecture](http://guide.elm-lang.org/architecture/index.html),
can be used like any other Elm component.


## Controls
By default, a Slides app will respond to these controls:

- Click on window bottom or right: Next slide
- Click on window top or left: Previous slide

- D, L, Arrow Right, Enter and Spacebar: Next slide/fragment
- A, H, Arrow Left: Previous slide/fragment
- Home: First slide
- End: Last slide
- P: pause animation (useful for debugging custom animations)


## Style customisation
This is the DOM structure for your custom CSS:
```css
    body
        .slides
            section /* one per slide */
                .slide-content /* useful for padding */
                    .fragment-content
```


## TODO

Add more built-in slide and fragment animations.

Add more ready-to-use CSS themes.

Add support for touch/gestures.

