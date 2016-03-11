import StartApp
import Html exposing (Html, Attribute, div, text, input, select, option)
import Html.Attributes exposing (class, type', value)
import Html.Events exposing (on, targetValue)
import Json.Decode
import Task exposing (Task)
import Effects exposing (Effects, Never)
import Signal exposing (Address)
import String
import Http

-- START APP

main : Signal Html
main =
  app.html

app : StartApp.App Model
app =
  StartApp.start
    { init = (initModel, Effects.none)
    , view = view
    , update = update
    , inputs = []
    }

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks

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
    | ReceiveData (Maybe (List (String, Float)))

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetStationId id ->
      ({ model | stationId = id }, requestData model)
    ReceiveData data ->
      case data of
        Just a -> ({ model | data = a }, Effects.none)
        Nothing -> (model, Effects.none)

-- TASKS

requestData : Model -> Effects Action
requestData model =
  Http.get dataDecoder "/readings/search"
    |> Task.toMaybe
    |> Task.map ReceiveData
    |> Effects.task

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
      [ text ("Station ID: " ++ (toString model.stationId))
      , text (toString model.data)
      ]
    , div [ class "col-lg-4" ]
      [ select [ onChangeInt address SetStationId, value (toString model.stationId) ]
        [ option [ value "4" ] [ text "Chicago" ]
        , option [ value "6" ] [ text "Milwaukee" ]
        ]
      ]
    ]
  ]