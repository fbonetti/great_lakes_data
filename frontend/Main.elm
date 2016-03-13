import StartApp
import Html exposing (Html, Attribute, div, text, input, select, option, button, span, label)
import Html.Attributes exposing (class, type', value, selected, id, step)
import Html.Events exposing (on, targetValue, onClick)
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

port data : Signal (List Point)
port data =
  Signal.map .data app.model

port stations : List Station

-- MODEL

type alias Model =
  { stationId : Int
  , startDate : Int
  , endDate : Int
  , data : List Point
  , loading : Bool
  , errorMessage : Maybe String
  }

type alias Point = (Int, Float)

type alias Station =
  { id : Int
  , name : String
  , latitude : Float
  , longitude : Float
  }

initModel : Model
initModel =
  { stationId = 4
  , startDate = 1422576000
  , endDate = 1435622400
  , data = []
  , loading = False
  , errorMessage = Nothing
  }

-- UPDATE

type Action
    = SetStationId Int
    | SetStartDate Int
    | SetEndDate Int
    | ReceiveData (List Point)
    | CloseAlert
    | SetErrorMessage String
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetStationId id ->
      let model' = { model | stationId = id, loading = True }
      in (model', requestData model')
    SetStartDate date ->
      let model' = { model | startDate = date }
      in (model', requestData model')
    SetEndDate date ->
      let model' = { model | endDate = date }
      in (model', requestData model')
    ReceiveData data ->
      noEffects { model | data = data, loading = False }
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

dataToAction : Result Http.Error (List Point) -> Action
dataToAction dataResult =
  case dataResult of
    Ok data -> ReceiveData data
    Err error -> SetErrorMessage (httpErrorToString error)

readingsUrl : Model -> String
readingsUrl model =
  url "/readings/daily_average"
    [ ("station_id", (toString model.stationId))
    , ("start_date", (toString model.startDate))
    , ("end_date", (toString model.endDate))
    ]

dataDecoder : Json.Decode.Decoder (List Point)
dataDecoder =
  let
    point = Json.Decode.tuple2 (,) Json.Decode.int Json.Decode.float
  in
    Json.Decode.list point

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

-- VIEW

view : Address Action -> Model -> Html
view address model =
  div [ class "container-fluid" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-8" ]
      [ errorAlert address model
      , div [ id "chart" ] []
      ]
    , div [ class "col-sm-4" ]
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
        [ label [] [ text "Start Date" ]
        , input
          [ type' "range"
          , Html.Attributes.min "1422576000"
          , Html.Attributes.max "1435622400"
          , step "1000"
          , onChangeInt address SetStartDate
          ]
          []
        ]
      , div [ class "form-group" ]
        [ label [] [ text "End Date" ]
        , input [ type' "range" ] []
        ]
      ]
    ]
  ]

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
