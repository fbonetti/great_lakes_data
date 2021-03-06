import StartApp
import Html exposing (Html, Attribute, div, text, input, select, option, button, span, label)
import Html.Attributes exposing (class, type', value, selected, id, step)
import Html.Events exposing (on, targetValue, onClick)
import Json.Decode exposing ((:=))
import Task exposing (Task)
import Effects exposing (Effects, Never)
import Signal exposing (Address)
import String
import Http exposing (url)
import Maybe
import Date
import Date.Format

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

port dailyAverageData : Signal (List Point)
port dailyAverageData =
  Signal.map .dailyAverageData app.model

port windRoseData : Signal (List WindRoseSeries)
port windRoseData =
  Signal.map .windRoseData app.model

port stations : List Station

-- MODEL

type alias Model =
  { stationId : Int
  , startDate : Int
  , endDate : Int
  , dailyAverageData : List Point
  , windRoseData : List WindRoseSeries
  , loading : Bool
  , errorMessage : Maybe String
  }

type alias Station =
  { id : Int
  , name : String
  , latitude : Float
  , longitude : Float
  , minTimestamp : Int
  , maxTimestamp : Int
  }

type alias Point = (Int, Float)
type alias WindRoseSeries = List Float

initModel : Model
initModel =
  { stationId = 4
  , startDate = 1422576000
  , endDate = 1435622400
  , dailyAverageData = []
  , windRoseData = []
  , loading = False
  , errorMessage = Nothing
  }

currentStation : Model -> Maybe Station
currentStation model =
  detect (\station -> station.id == model.stationId) stations

currentStationMinTimestamp : Model -> Int
currentStationMinTimestamp =
  currentStation >> Maybe.map .minTimestamp >> Maybe.withDefault 0

currentStationMaxTimestamp : Model -> Int
currentStationMaxTimestamp =
  currentStation >> Maybe.map .maxTimestamp >> Maybe.withDefault 0

-- UPDATE

type Action
    = SetStationId Int
    | SetStartDate Int
    | SetEndDate Int
    | ReceiveData (List Point, List WindRoseSeries)
    | CloseAlert
    | SetErrorMessage String
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetStationId id ->
      let
        model' = { model | stationId = id, loading = True }
      in
        (model', requestData model')
    SetStartDate date ->
      let
        date' = if date <= model.endDate then date else model.endDate
        model' = { model | startDate = date', loading = True }
      in
        (model', requestData model')
    SetEndDate date ->
      let
        date' = if date >= model.startDate then date else model.startDate
        model' = { model | endDate = date', loading = True }
      in
        (model', requestData model')
    ReceiveData (dailyAverageData, windRoseData) ->
      noEffects { model | dailyAverageData = dailyAverageData
                        , windRoseData = windRoseData
                        , loading = False }
    CloseAlert ->
      noEffects { model | errorMessage = Nothing}
    SetErrorMessage message ->
      noEffects { model | errorMessage = Just message}
    NoOp ->
      noEffects model

noEffects : Model -> (Model, Effects Action)
noEffects model =
  (model, Effects.none)

-- TASKS

requestData : Model -> Effects Action
requestData model =
  Http.get dataDecoder (readingsUrl model)
    |> Task.toResult
    |> Task.map dataToAction
    |> Effects.task

dataToAction : Result Http.Error (List Point, List WindRoseSeries) -> Action
dataToAction dataResult =
  case dataResult of
    Ok data -> ReceiveData data
    Err error -> SetErrorMessage (httpErrorToString error)

readingsUrl : Model -> String
readingsUrl model =
  url "/readings/station_data"
    [ ("station_id", (toString model.stationId))
    , ("start_date", (toString model.startDate))
    , ("end_date", (toString model.endDate))
    ]

dataDecoder : Json.Decode.Decoder (List Point, List WindRoseSeries)
dataDecoder =
  let
    point = Json.Decode.tuple2 (,) Json.Decode.int Json.Decode.float
    windRoseSeries = Json.Decode.list Json.Decode.float
  in
    Json.Decode.object2 (,)
      ("daily_average_data" := Json.Decode.list point)
      ("wind_rose_data" := Json.Decode.list windRoseSeries)

-- HELPERS

onInput : Address a -> (String -> a) -> Attribute
onInput address contentToValue =
  on "input" targetValue (contentToValue >> Signal.message address)

targetValueInt : Json.Decode.Decoder Int
targetValueInt =
  Json.Decode.customDecoder targetValue String.toInt

onChange : Address a -> (String -> a) -> Attribute
onChange address contentToValue =
  on "change" targetValue (contentToValue >> Signal.message address)

onChangeInt : Address a -> (Int -> a) -> Attribute
onChangeInt address contentToValue =
  on "change" targetValueInt (contentToValue >> Signal.message address)

httpErrorToString : Http.Error -> String
httpErrorToString error =
  case error of
    Http.Timeout -> "Request timed out"
    Http.NetworkError -> "Network error"
    Http.UnexpectedPayload message -> message
    Http.BadResponse status message -> message

detect : (a -> Bool) -> List a -> Maybe a
detect fn =
  List.filter fn >> List.head

-- VIEW

view : Address Action -> Model -> Html
view address model =
  div [ class "container-fluid" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-9" ]
      [ errorAlert address model
      , div [ class "row" ]
        [ div [ class "col-sm-7" ]
          [ div [ id "dailyAverageChart" ] []
          ]
        , div [ class "col-sm-5" ]
          [ div [ id "windRoseChart" ] []
          ]
        ]
      ]
    , div [ class "col-sm-3" ]
      [ div [ class "form-group" ]
        [ label [] [ text "Station" ]
        , select
          [ onChangeInt address SetStationId
          , value (toString model.stationId)
          , class "form-control"
          ]
          (List.map (stationOption model) stations)
        ]
      , div [ class "form-group" ]
        [ label [] [ text ("Start Date: " ++ (formatDate model.startDate)) ]
        , input
          [ type' "range"
          , Html.Attributes.min (currentStationMinTimestamp model |> toString)
          , Html.Attributes.max (currentStationMaxTimestamp model |> toString)
          , step "1000"
          , value (toString model.startDate)
          , onChangeInt address SetStartDate
          ]
          []
        ]
      , div [ class "form-group" ]
        [ label [] [ text ("End Date: " ++ (formatDate model.endDate)) ]
        , input
          [ type' "range"
          , Html.Attributes.min (currentStationMinTimestamp model |> toString)
          , Html.Attributes.max (currentStationMaxTimestamp model |> toString)
          , step "1000"
          , value (toString model.endDate)
          , onChangeInt address SetEndDate
          ]
          []
        ]
      , div [] [ text (if model.loading then "Loading..." else "") ]
      ]
    ]
  ]

formatDate : Int -> String
formatDate =
  toFloat >> ((*) 1000) >> Date.fromTime >> Date.Format.format "%A, %B %e, %Y"

stationOption : Model -> Station -> Html
stationOption model station =
  dropDownOption (toString station.id) station.name (model.stationId == station.id)

dropDownOption : String -> String -> Bool -> Html
dropDownOption value' text' selected' =
  option [ value value', selected selected' ] [ text text' ]

errorAlert : Address Action -> Model -> Html
errorAlert address model =
  case model.errorMessage of
    Just message -> bsAlert address (text message)
    Nothing -> div [] []

bsAlert : Address Action -> Html -> Html
bsAlert address body =
  div [ class "alert alert-danger alert-dismissible" ]
  [ button [ class "close" ]
    [ span [ onClick address CloseAlert ]
      [ text "x" ]
    ]
  , body
  ]
