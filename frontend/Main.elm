import StartApp
import Html exposing (Html, Attribute, div, text, input, select, option)
import Html.Attributes exposing (class, type', value, selected)
import Html.Events exposing (on, targetValue)
import Json.Decode
import Task exposing (Task)
import Effects exposing (Effects, Never)
import Signal exposing (Address)
import String
import Http exposing (url)
import Maybe

-- START APP

main : Signal Html
main =
  app.html

app : StartApp.App Model
app =
  StartApp.start
    { init = (initModel, requestData initModel)
    , view = view
    , update = update
    , inputs = []
    }

port tasks : Signal (Task Never ())
port tasks =
  app.tasks

port data : Signal (List (String, Float))
port data =
  Signal.map .data app.model

-- MODEL

type alias Model =
  { stationId : Int
  , startDate : String
  , endDate : String
  , data : List (String, Float)
  }

initModel : Model
initModel = Model 4 "2015-01-01" "2015-12-31" []

-- UPDATE

type Action
    = SetStationId Int
    | ReceiveData (List (String, Float))
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetStationId id ->
      let model' = { model | stationId = id }
      in (model', requestData model')
    ReceiveData data ->
      ({ model | data = data }, Effects.none)
    NoOp ->
      (model, Effects.none)

-- TASKS

requestData : Model -> Effects Action
requestData model =
  Http.get dataDecoder (readingsUrl model)
    |> Task.toMaybe
    |> Task.map (Maybe.map ReceiveData >> Maybe.withDefault NoOp)
    |> Effects.task

readingsUrl : Model -> String
readingsUrl model =
  url "/readings/search"
    [ ("station_id", (toString model.stationId))
    ]

dataDecoder : Json.Decode.Decoder (List (String, Float))
dataDecoder =
  let
    point = Json.Decode.tuple2 (,) Json.Decode.string Json.Decode.float
  in
    Json.Decode.list point

-- HELPERS

onInput : Address a -> (String -> a) -> Attribute
onInput address contentToValue =
  on "input" targetValue (contentToValue >> Signal.message address)

targetValueInt : Json.Decode.Decoder Int
targetValueInt =
  Json.Decode.customDecoder targetValue String.toInt

onChangeInt : Address a -> (Int -> a) -> Attribute
onChangeInt address contentToValue =
  on "change" targetValueInt (contentToValue >> Signal.message address)

-- VIEW

view : Address Action -> Model -> Html
view address model =
  div [ class "container-fluid" ]
  [ div [ class "row" ]
    [ div [ class "col-lg-8" ]
      [ div []
        [ text ("Station ID: " ++ (toString model.stationId)) ]
      , div []
        [ text (toString model.data) ]
      ]
    , div [ class "col-lg-4" ]
      [ select
        [ onChangeInt address SetStationId
        , value (toString model.stationId)
        , class "form-control"
        ]
        [ dropDownOption "1" "Milwaukee" (model.stationId == 1)
        , dropDownOption "4" "Chicago" (model.stationId == 4)
        , dropDownOption "8" "South Haven" (model.stationId == 8)
        ]
      ]
    ]
  ]

dropDownOption : String -> String -> Bool -> Html
dropDownOption value' text' selected' =
  option [ value value', selected selected' ] [ text text' ]
