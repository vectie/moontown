///|
priv struct PlacesState {
  columns : Array[Int32]
  show : Bool
  error : String
} derive(Debug, Eq)

///|
priv enum PlacesMsg {
  Column(Int32, String)
  Explore
}

///|
fn initial_places() -> PlacesState {
  { columns: [-1, -1, -1, -1], show: false, error: "", }
}

///|
fn places_transition(
  state : ImportedOutputsState,
  message : PlacesMsg,
) -> (ImportedOutputsState, ImportedOutputsRequest?) {
  guard state.open &&
    state.selection is Some(_) &&
    state.text is TextReady(_) &&
    state.table is Some(Ok(table)) else {
    return (state, None)
  }
  match message {
    Column(role, value) => {
      if role < 0 || role >= 4 {
        return (state, None)
      }
      let choices = table.headers
        .mapi((i, _) => i)
        .filter(i => i.to_string() == value)
      let column = match choices {
        [i] => i
        _ if value == "" => -1
        _ => return (state, None)
      }
      let columns = state.places.columns.copy()
      columns[role] = column
      (
        {
          ..state,
          places: { columns, show: false, error: "", },
          geo: initial_geo(),
        },
        None,
      )
    }
    Explore => {
      let c = state.places.columns
      match
        table.places(latitude=c[0], longitude=c[1], name=c[2], category=c[3]) {
        Ok(features) =>
          (
            {
              ..state,
              places: { ..state.places, show: true, error: "", },
              geo: { ..initial_geo(), features: Some(Ok(features)), },
            },
            None,
          )
        Err(reason) =>
          (
            {
              ..state,
              places: { ..state.places, show: false, error: reason, },
              geo: initial_geo(),
            },
            None,
          )
      }
    }
  }
}

///|
fn render_places_mapping(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
  table : @imported_output_contract.DataTable,
) -> @rabbita.Html {
  @html.section(class="imported-places-intake", [
    @html.h3("Explore table as places"),
    @html.p(
      "Choose four distinct columns explicitly. Coordinates must be WGS84 decimal degrees. Every row becomes a Point; invalid rows stop intake with a source data-row number. No coordinate guessing or geocoding.",
    ),
    @html.div(
      ["Latitude", "Longitude", "Name", "Category"].mapi((role, label) => {
        let id = "places-column-" + role.to_string()
        @html.div([
          @html.label(for_=id, label + " column"),
          @html.select(
            id~,
            class="request-input",
            on_change=value => {
              dispatch(ImportedOutputsEvent(PlacesEvent(Column(role, value))))
            },
            [
              @html.option(
                value="",
                selected=state.places.columns[role] == -1,
                "Choose column…",
              ),
            ] +
            table.headers.mapi((index, header) => {
              @html.option(
                value=index.to_string(),
                selected=state.places.columns[role] == index,
                (index + 1).to_string() +
                ": " +
                (if header.is_empty() { "(empty header)" } else { header }),
              )
            }),
          ),
        ])
      }),
    ),
    @html.button(
      class="square-action",
      on_click=dispatch(ImportedOutputsEvent(PlacesEvent(Explore))),
      "Explore places",
    ),
    if state.places.error.is_empty() {
      @html.nothing
    } else {
      imported_output_status("Places intake unavailable: " + state.places.error)
    },
    @html.p(
      "Original columns stay in each feature's source_table headers/cells, preserving duplicate labels and text values. Changing a mapping or exploring again clears previous filters and selection. Up to 2,000 places; the derived collection must fit 1 MiB.",
    ),
  ])
}
