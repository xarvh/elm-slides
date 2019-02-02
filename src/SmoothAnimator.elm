module SmoothAnimator exposing (..)


type alias Model =
    { initialPosition : Int
    , targetPosition : Int
    , currentPosition : Float
    }


init : Int -> Model
init position =
    Model position position (toFloat position)


type Msg
    = SelectExact Int
    | SelectFirst
    | SelectLast
    | SelectNext
    | SelectPrev
    | AnimationTick Float


newPosition : Float -> Model -> Float -> Float
newPosition duration m deltaTime =
    let
        totalDistance =
            abs <| m.initialPosition - m.targetPosition

        distance =
            toFloat m.targetPosition - m.currentPosition

        absDistance =
            abs distance

        ( direction, limitBetween ) =
            if distance > 0 then
                ( 1, min )
            else
                ( -1, max )

        velocity =
            toFloat (max 1 totalDistance) / duration

        deltaPosition =
            deltaTime * direction * velocity

        newUnclampedPosition =
            m.currentPosition + deltaPosition
    in
    -- either min or max, depending on the direction we're going
    limitBetween newUnclampedPosition (toFloat m.targetPosition)


update : Float -> Int -> Msg -> Model -> Model
update duration maximumPosition msg oldModel =
    let
        select unclampedTargetPosition =
            { oldModel | targetPosition = clamp 0 maximumPosition unclampedTargetPosition }
    in
    case msg of
        SelectExact index ->
            select index

        SelectFirst ->
            select 0

        SelectLast ->
            select 99999

        SelectPrev ->
            select <| oldModel.targetPosition - 1

        SelectNext ->
            select <| oldModel.targetPosition + 1

        AnimationTick deltaTime ->
            let
                currentPosition =
                    newPosition duration oldModel deltaTime

                initialPosition =
                    if currentPosition /= toFloat oldModel.targetPosition then
                        oldModel.initialPosition
                    else
                        oldModel.targetPosition
            in
            { oldModel | currentPosition = currentPosition, initialPosition = initialPosition }
