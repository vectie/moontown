///|
priv struct AgendaState {
  events : Result[Array[@imported_output_contract.CalendarEvent], String]?
  occurrences : Result[Array[@imported_output_contract.CalendarEvent], String]?
  source_selected : Array[Int]
  window_from : String
  window_until : String
  query : String
  from : String
  until : String
  location : String
  selected : Array[Int]
  raw : Bool
} derive(Debug, Eq)

///|
priv enum AgendaMsg {
  WindowFrom(String)
  WindowUntil(String)
  Expand
  Sources
  Query(String)
  From(String)
  Until(String)
  Location(String)
  Toggle(Int)
  SelectMatching
  Clear
  Raw
  Export(Bool)
  ExportOverlaps
}

///|
fn initial_agenda() -> AgendaState {
  {
    events: None,
    occurrences: None,
    source_selected: [],
    window_from: "",
    window_until: "",
    query: "",
    from: "",
    until: "",
    location: "",
    selected: [],
    raw: false,
  }
}

///|
fn agenda_matches(
  a : AgendaState,
  events : Array[@imported_output_contract.CalendarEvent],
) -> Array[Int] {
  @imported_output_contract.calendar_matches(
    events,
    a.query,
    a.from,
    a.until,
    a.location,
  )
}

///|
fn agenda_transition(
  state : ImportedOutputsState,
  message : AgendaMsg,
) -> (ImportedOutputsState, ImportedOutputsRequest?) {
  guard state.open && state.agenda.events is Some(Ok(events)) else {
    return (state, None)
  }
  let a = state.agenda
  let events = match a.occurrences {
    Some(Ok(expanded)) => expanded
    _ => events
  }
  let next = match message {
    WindowFrom(window_from) =>
      {
        ..a,
        window_from,
        occurrences: None,
        selected: if a.occurrences is Some(Ok(_)) {
          a.source_selected
        } else {
          a.selected
        },
      }
    WindowUntil(window_until) =>
      {
        ..a,
        window_until,
        occurrences: None,
        selected: if a.occurrences is Some(Ok(_)) {
          a.source_selected
        } else {
          a.selected
        },
      }
    Sources =>
      {
        ..a,
        occurrences: None,
        selected: if a.occurrences is Some(Ok(_)) {
          a.source_selected
        } else {
          a.selected
        },
        from: "",
        until: "",
      }
    Expand => {
      guard state.text is TextReady(content) else { return (state, None) }
      let source_selected = if a.occurrences is Some(Ok(_)) {
        a.source_selected
      } else {
        a.selected
      }
      let expanded = @imported_output_contract.calendar_occurrences(
        content,
        a.window_from,
        a.window_until,
        source_selected,
      )
      {
        ..a,
        occurrences: Some(expanded),
        source_selected,
        selected: if expanded is Ok(_) {
          []
        } else {
          source_selected
        },
        from: "",
        until: "",
        raw: false,
      }
    }
    Query(query) => { ..a, query, }
    From(from) => { ..a, from, }
    Until(until) => { ..a, until, }
    Location(location) => { ..a, location, }
    Raw => { ..a, raw: !a.raw, }
    Clear => { ..a, selected: [], }
    SelectMatching => { ..a, selected: agenda_matches(a, events), }
    Toggle(index) => {
      if index < 0 || index >= events.length() {
        return (state, None)
      }
      let selected = if a.selected.contains(index) {
        a.selected.filter(i => i != index)
      } else {
        a.selected + [index]
      }
      selected.sort()
      { ..a, selected, }
    }
    ExportOverlaps => {
      if a.selected.is_empty() || !(a.occurrences is Some(Ok(_))) {
        return (state, None)
      }
      let report = @imported_output_contract.calendar_overlap_report(
        events,
        a.selected,
        a.window_from,
        a.window_until,
      )
      return (
        state,
        match report {
          Ok(text) =>
            Some(SaveFilteredTable(text, "selected-occurrence-overlaps.md"))
          Err(_) => None
        },
      )
    }
    Export(csv) => {
      if a.selected.is_empty() || a.occurrences is Some(Err(_)) {
        return (state, None)
      }
      return (
        state,
        Some(
          SaveFilteredTable(
            if csv {
              agenda_csv(a, events)
            } else {
              agenda_itinerary(a, events)
            },
            if csv {
              if a.occurrences is Some(Ok(_)) {
                "selected-occurrences.csv"
              } else {
                "selected-agenda.csv"
              }
            } else if a.occurrences is Some(Ok(_)) {
              "selected-occurrence-itinerary.md"
            } else {
              "selected-itinerary.md"
            },
          ),
        ),
      )
    }
  }
  ({ ..state, agenda: next, }, None)
}

///|
fn agenda_button(
  dispatch : Dispatch[Msg],
  message : AgendaMsg,
  label : String,
) -> @rabbita.Html {
  @html.button(
    class="square-action",
    on_click=dispatch(ImportedOutputsEvent(AgendaEvent(message))),
    label,
  )
}

///|
fn agenda_input(
  dispatch : Dispatch[Msg],
  id : String,
  label : String,
  value : String,
  message : (String) -> AgendaMsg,
) -> @rabbita.Html {
  @html.div([
    @html.label(for_=id, label),
    @html.input(
      id~,
      input_type=if id == "agenda-from" ||
        id == "agenda-until" ||
        id == "occurrence-from" ||
        id == "occurrence-until" {
        @html.Date
      } else {
        @html.Text
      },
      class="request-input",
      value~,
      on_input=value => {
        dispatch(ImportedOutputsEvent(AgendaEvent(message(value))))
      },
    ),
  ])
}

///|
fn render_imported_agenda(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
  content : String,
) -> @rabbita.Html {
  let a = state.agenda
  guard a.events is Some(Ok(events)) else {
    let reason = match a.events {
      Some(Err(reason)) => reason
      _ => "Unavailable"
    }
    return @html.div([
      imported_output_status("Agenda unavailable: " + reason),
      @html.pre(class="imported-outputs-text", content),
    ])
  }
  let expanded = a.occurrences is Some(Ok(_))
  let events = match a.occurrences {
    Some(Ok(found)) => found
    _ => events
  }
  let matching = agenda_matches(a, events)
  let cards : Array[@rabbita.Html] = []
  let mut day = ""
  for i in matching {
    let event = events[i]
    if event.date != day {
      day = event.date
      cards.push(@html.h3(day))
    }
    cards.push(
      @html.article(
        style=[
          "padding:12px", "border:1px solid #ccd5dc", "border-radius:8px", "margin-bottom:8px",
        ],
        [
          @html.button(
            class="square-action",
            attrs=@html.Attrs::build().aria_pressed(
              if a.selected.contains(i) {
                "true"
              } else {
                "false"
              },
            ),
            on_click=dispatch(ImportedOutputsEvent(AgendaEvent(Toggle(i)))),
            (if a.selected.contains(i) { "Selected · " } else { "Select · " }) +
            event.summary,
          ),
          @html.p(event.start + " · " + event.zone + " → " + event.end),
          @html.p("Location: " + event.location),
          @html.p(style=["white-space:pre-wrap"], event.description),
          @html.p("UID: " + event.uid),
          @html.p("URL (source text): " + event.url),
          if event.recurrence.is_empty() {
            @html.nothing
          } else {
            imported_output_status(
              (if expanded {
                "Occurrence provenance: "
              } else {
                "Recurrence not expanded: "
              }) +
              event.recurrence,
            )
          },
        ],
      ),
    )
  }
  @html.section(class="imported-calendar-agenda", [
    @html.h3(
      if expanded {
        "Dated occurrence itinerary"
      } else {
        "Calendar agenda"
      },
    ),
    @html.p(
      "To build a dated plan, select source entries, choose a finite window and expand. Only selected entries are included. DAILY/WEEKLY UTC/all-day, INTERVAL, COUNT/UNTIL and EXDATE are supported; named zones/DST, floating times, BYDAY and overrides are unsupported.",
    ),
    agenda_input(
      dispatch,
      "occurrence-from",
      "Occurrence window from (inclusive)",
      a.window_from,
      s => WindowFrom(s),
    ),
    agenda_input(
      dispatch,
      "occurrence-until",
      "Occurrence window through (inclusive, at most 366 dates)",
      a.window_until,
      s => WindowUntil(s),
    ),
    @html.div(class="imported-outputs-actions", [
      agenda_button(
        dispatch,
        Expand,
        if expanded {
          "Regenerate occurrences (clears selection)"
        } else {
          "Expand selected source entries"
        },
      ),
      agenda_button(dispatch, Sources, "Back to source events"),
    ]),
    match a.occurrences {
      Some(Err(reason)) =>
        imported_output_status(
          "Occurrence expansion unavailable: " +
          reason +
          ". No partial occurrence itinerary was created. Deselect unsupported entries, or return to source events for source-only export.",
        )
      Some(Ok(_)) =>
        imported_output_status(
          "Window " +
          a.window_from +
          " through " +
          a.window_until +
          " · " +
          a.source_selected.length().to_string() +
          " explicitly selected source entries. Changing the occurrence window returns to sources and clears occurrence selection.",
        )
      None => @html.nothing
    },
    @html.p(
      if expanded {
        "Dated occurrences from selected sources only, grouped by occurrence start date. UTC and all-day only. All-day end dates are exclusive. No scheduling or RSVP actions."
      } else {
        "Source events grouped by written start date. UTC is labeled; TZID and floating times are unconverted. Recurrences are not expanded. All-day end dates are exclusive. No scheduling or RSVP actions."
      },
    ),
    agenda_input(
      dispatch,
      "agenda-query",
      "Search title, notes, UID and location",
      a.query,
      s => Query(s),
    ),
    agenda_input(
      dispatch,
      "agenda-from",
      "Start date from (YYYY-MM-DD, inclusive)",
      a.from,
      s => From(s),
    ),
    agenda_input(
      dispatch,
      "agenda-until",
      "Start date through (YYYY-MM-DD, inclusive)",
      a.until,
      s => Until(s),
    ),
    agenda_input(dispatch, "agenda-location", "Location contains", a.location, s => {
      Location(s)
    }),
    imported_output_status(
      matching.length().to_string() +
      " of " +
      events.length().to_string() +
      (if expanded { " dated occurrences · " } else { " source events · " }) +
      a.selected.length().to_string() +
      " selected (selection stays across filters)",
    ),
    @html.div(class="imported-outputs-actions", [
      agenda_button(dispatch, SelectMatching, "Select all matching"),
      agenda_button(dispatch, Clear, "Clear selection"),
      agenda_button(
        dispatch,
        Raw,
        if a.raw {
          "Agenda view"
        } else {
          "Raw ICS"
        },
      ),
    ]),
    if a.raw {
      @html.pre(class="imported-outputs-text", content)
    } else if matching.is_empty() {
      imported_output_status(
        if expanded {
          "No dated occurrences match these filters."
        } else {
          "No source events match these filters."
        },
      )
    } else {
      @html.div(style=["max-height:28rem", "overflow:auto"], cards)
    },
    @html.h3("Selected itinerary"),
    if expanded && !a.selected.is_empty() {
      match
        @imported_output_contract.calendar_overlap_report(
          events,
          a.selected,
          a.window_from,
          a.window_until,
        ) {
        Ok(report) =>
          @html.div([
            @html.h3("Selected occurrence overlap review"),
            @html.p(
              "Review follows the selected occurrences, including selections hidden by filters. UTC intervals only; all-day markers and missing durations remain unassessed.",
            ),
            agenda_button(
              dispatch,
              ExportOverlaps,
              "Download overlap review (.md)",
            ),
            @html.pre(
              class="imported-outputs-text",
              style=["max-height:20rem", "overflow:auto"],
              report,
            ),
          ])
        Err(reason) =>
          imported_output_status("Overlap review unavailable: " + reason)
      }
    } else {
      @html.nothing
    },
    if a.selected.is_empty() || a.occurrences is Some(Err(_)) {
      imported_output_status(
        "Select events after a successful expansion, or return to source events for source-only export.",
      )
    } else {
      @html.div([
        @html.div(class="imported-outputs-actions", [
          agenda_button(dispatch, Export(false), "Download itinerary (.md)"),
          agenda_button(
            dispatch,
            Export(true),
            "Download selected events (.csv)",
          ),
        ]),
        @html.p(
          "Derived CSV quotes every field and prefixes formula-leading cells for spreadsheet safety. The exact original download is unchanged.",
        ),
        @html.pre(class="imported-outputs-text", agenda_itinerary(a, events)),
      ])
    },
  ])
}

///|
fn agenda_itinerary(
  a : AgendaState,
  events : Array[@imported_output_contract.CalendarEvent],
) -> String {
  if a.occurrences is Some(Ok(_)) {
    @imported_output_contract.calendar_occurrence_itinerary(
      events,
      a.selected,
      a.window_from,
      a.window_until,
    )
  } else {
    @imported_output_contract.calendar_itinerary(events, a.selected)
  }
}

///|
fn agenda_csv(
  a : AgendaState,
  events : Array[@imported_output_contract.CalendarEvent],
) -> String {
  if a.occurrences is Some(Ok(_)) {
    @imported_output_contract.calendar_occurrence_csv(
      events,
      a.selected,
      a.window_from,
      a.window_until,
    )
  } else {
    @imported_output_contract.calendar_csv(events, a.selected)
  }
}
