///|
priv struct GeoState {
  features : Result[Array[@imported_output_contract.GeoFeature], String]?
  query : String
  kind : String
  zone : Int32?
  selected : Array[Int32]
  page : Int32
  raw : Bool
} derive(Debug, Eq)

///|
priv enum GeoMsg {
  Query(String)
  Kind(String)
  Zone(String)
  Toggle(Int32)
  SelectMatching
  Clear
  Page(Int32)
  Raw
  Export(Bool)
}

///|
fn initial_geo() -> GeoState {
  {
    features: None,
    query: "",
    kind: "",
    zone: None,
    selected: [],
    page: 0,
    raw: false,
  }
}

///|
fn geo_matches(
  geo : GeoState,
  features : Array[@imported_output_contract.GeoFeature],
) -> Array[Int32] {
  let matching = @imported_output_contract.geo_matches(
    features,
    geo.query,
    geo.kind,
  )
  match geo.zone {
    None => matching
    Some(zone) => {
      let contained = @imported_output_contract.geo_places_in_zone(
        features, zone,
      )
      matching.filter(i => contained.contains(i))
    }
  }
}

///|
fn geo_transition(
  state : ImportedOutputsState,
  message : GeoMsg,
) -> (ImportedOutputsState, ImportedOutputsRequest?) {
  guard state.open &&
    state.selection is Some(_) &&
    state.text is TextReady(_) &&
    state.geo.features is Some(Ok(features)) else {
    return (state, None)
  }
  let geo = state.geo
  let next = match message {
    Query(query) => { ..geo, query, page: 0, }
    Kind(kind) => {
      if kind != "" &&
        kind != "Point" &&
        kind != "LineString" &&
        kind != "Polygon" {
        return (state, None)
      }
      { ..geo, kind, zone: None, page: 0, }
    }
    Zone(value) =>
      if value.is_empty() {
        { ..geo, zone: None, kind: "", page: 0, }
      } else {
        let zones : Array[Int32] = []
        for i, f in features {
          if f.kind == "Polygon" && i.to_string() == value {
            zones.push(i)
          }
        }
        guard zones is [zone] else { return (state, None) }
        { ..geo, zone: Some(zone), kind: "Point", page: 0, }
      }
    Clear => { ..geo, selected: [], }
    SelectMatching => { ..geo, selected: geo_matches(geo, features), }
    Raw => { ..geo, raw: !geo.raw, }
    Page(page) => {
      if page < 0 || page >= (geo_matches(geo, features).length() + 24) / 25 {
        return (state, None)
      }
      { ..geo, page, }
    }
    Toggle(index) => {
      if index < 0 || index >= features.length() {
        return (state, None)
      }
      let selected = if geo.selected.contains(index) {
        geo.selected.filter(i => i != index)
      } else {
        geo.selected + [index]
      }
      selected.sort()
      { ..geo, selected, }
    }
    Export(csv) => {
      if geo.selected.is_empty() {
        return (state, None)
      }
      return (
        state,
        Some(
          SaveFilteredTable(
            if csv {
              match state.table {
                Some(Ok(table)) => table.selection_csv(geo.selected)
                _ => @imported_output_contract.geo_csv(features, geo.selected)
              }
            } else {
              @imported_output_contract.geojson_selection(
                features,
                geo.selected,
              )
            },
            if csv {
              "selected-places.csv"
            } else {
              "selected-places.geojson"
            },
          ),
        ),
      )
    }
  }
  ({ ..state, geo: next, }, None)
}

///|
fn geo_button(
  dispatch : Dispatch[Msg],
  message : GeoMsg,
  label : String,
  disabled~ : Bool = false,
) -> @rabbita.Html {
  @html.button(
    class="square-action",
    disabled~,
    on_click=dispatch(ImportedOutputsEvent(GeoEvent(message))),
    label,
  )
}

///|
/// Whole features only: a long line is omitted rather than partially drawn.
fn geo_schematic_indices(
  features : Array[@imported_output_contract.GeoFeature],
  matching : Array[Int32],
) -> Array[Int32] {
  let plotted : Array[Int32] = []
  let mut positions = 0
  for index in matching {
    if plotted.length() >= 100 {
      break
    }
    if positions + features[index].points.length() <= 2000 {
      plotted.push(index)
      positions += features[index].points.length()
    }
  }
  plotted
}

///|
fn render_geo_schematic(
  features : Array[@imported_output_contract.GeoFeature],
  matching : Array[Int32],
  selected : Array[Int32],
  zone? : Int32,
) -> @rabbita.Html {
  let candidates = match zone {
    Some(i) => [i] + matching.filter(j => j != i)
    None => matching
  }
  let plotted = geo_schematic_indices(features, candidates)
  if plotted.is_empty() {
    return imported_output_status(
      "No complete features fit the schematic display limit. Source details and exports remain available.",
    )
  }
  let first = features[plotted[0]].points[0]
  let mut west = first.longitude
  let mut east = first.longitude
  let mut south = first.latitude
  let mut north = first.latitude
  for index in plotted {
    for point in features[index].points {
      west = west.min(point.longitude)
      east = east.max(point.longitude)
      south = south.min(point.latitude)
      north = north.max(point.latitude)
    }
  }
  let shapes : Array[@svg.Svg] = []
  for index in plotted {
    let feature = features[index]
    let project = (point : @imported_output_contract.GeoPoint) => {
      let x = if east == west {
        220
      } else {
        (20.0 + (point.longitude - west) / (east - west) * 400.0).to_int()
      }
      let y = if north == south {
        140
      } else {
        (20.0 + (north - point.latitude) / (north - south) * 240.0).to_int()
      }
      (x, y)
    }
    let points = feature.points.map(project)
    let color = if selected.contains(index) { "#b45309" } else { "#0369a1" }
    if feature.kind == "Point" {
      shapes.push(@svg.circle(cx=points[0].0, cy=points[0].1, r=6, fill=color))
    } else if feature.kind == "Polygon" {
      let paths = @imported_output_contract.geo_rings(feature).map(ring => {
        let coords = ring.map(project)
        "M " +
        coords.map(p => p.0.to_string() + " " + p.1.to_string()).join(" L ") +
        " Z"
      })
      shapes.push(
        @svg.path(
          d=paths.join(" "),
          fill=color,
          stroke=color,
          stroke_width=2,
          attrs=@svg.Attrs::build().fill_rule("evenodd").fill_opacity("0.12"),
        ),
      )
    } else {
      shapes.push(
        @svg.polyline(points~, fill="none", stroke=color, stroke_width=3),
      )
    }
    shapes.push(
      @svg.svg_text(
        x=points[0].0 + 7,
        y=points[0].1 - 7,
        text=(index + 1).to_string(),
        fill="#0f172a",
      ),
    )
  }
  @html.figure([
    @html.div(
      attrs=@html.Attrs::build()
        .role("img")
        .aria_label(
          "Coordinate schematic of imported features; numbered by source feature. Selected features are amber.",
        ),
      @svg.svg(
        style=[
          "width:100%", "max-height:20rem", "background:#f1f5f9", "border:1px solid #cbd5e1",
        ],
        view_box="0 0 440 280",
        shapes,
      ),
    ),
    @html.figcaption(
      "Coordinate schematic: " +
      plotted.length().to_string() +
      " of " +
      candidates.length().to_string() +
      " matching features" +
      (match zone {
        Some(i) =>
          if plotted.contains(i) {
            " including the chosen zone outline"
          } else {
            "; chosen zone outline exceeds the remaining display limit and is omitted"
          }
        None => ""
      }) +
      ". North is up; axes scale independently. Labels are source feature numbers; amber means selected. Polygon holes are unfilled. Display limit: 100 whole features / 2,000 positions. No basemap, navigation or routing; dateline wrapping is not modeled.",
    ),
  ])
}

///|
fn render_imported_geo(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
  content : String,
) -> @rabbita.Html {
  let geo = state.geo
  guard geo.features is Some(Ok(features)) else {
    let reason = match geo.features {
      Some(Err(reason)) => reason
      _ => "Unavailable"
    }
    return @html.div([
      imported_output_status("GeoJSON explorer unavailable: " + reason),
      @html.pre(
        class="imported-outputs-text",
        attrs=@html.Attrs::build().aria_label("Verified raw GeoJSON"),
        content,
      ),
    ])
  }
  let matching = geo_matches(geo, features)
  let start = (geo.page * 25).min(matching.length())
  let end = (start + 25).min(matching.length())
  let visible = matching[start:end].to_owned()
  @html.section(class="imported-geojson-explorer", [
    @html.h3(
      if state.table is Some(_) {
        "Table places explorer"
      } else {
        "GeoJSON places and routes · zones"
      },
    ),
    @html.p(
      if state.table is Some(_) {
        "Read-only Point places from the complete mapped table, independent of the table search. Feature numbers equal data-row numbers (header excluded). Original columns remain inert text. No location sharing or external map requests."
      } else {
        "Read-only Point, LineString and Polygon source features. Coordinates are longitude, latitude; source properties stay inert text. No location sharing, bookings or external map requests."
      },
    ),
    @html.label(for_="geo-query", "Search name and category"),
    @html.input(id="geo-query", class="request-input", value=geo.query, on_input=query => {
      dispatch(ImportedOutputsEvent(GeoEvent(Query(query))))
    }),
    @html.label(for_="geo-kind", "Geometry kind"),
    @html.select(
      id="geo-kind",
      class="request-input",
      on_change=kind => dispatch(ImportedOutputsEvent(GeoEvent(Kind(kind)))),
      [
        @html.option(value="", selected=geo.kind == "", "All geometry kinds"),
        @html.option(
          value="Point",
          selected=geo.kind == "Point",
          "Places (Point)",
        ),
        @html.option(
          value="LineString",
          selected=geo.kind == "LineString",
          "Routes (LineString)",
        ),
        @html.option(
          value="Polygon",
          selected=geo.kind == "Polygon",
          "Zones (Polygon)",
        ),
      ],
    ),
    render_geo_zone_filter(dispatch, geo, features),
    imported_output_status(
      matching.length().to_string() +
      " of " +
      features.length().to_string() +
      " source features · " +
      geo.selected.length().to_string() +
      " selected (selection stays across filters)",
    ),
    @html.div(class="imported-outputs-actions", [
      geo_button(dispatch, SelectMatching, "Select all matching"),
      geo_button(dispatch, Clear, "Clear selection"),
      geo_button(
        dispatch,
        Raw,
        if geo.raw {
          "Explorer view"
        } else if state.table is Some(_) {
          "Raw source table"
        } else {
          "Raw GeoJSON"
        },
      ),
    ]),
    if geo.raw {
      @html.pre(class="imported-outputs-text", content)
    } else if matching.is_empty() {
      @html.div([
        imported_output_status(
          if features.is_empty() {
            "This FeatureCollection contains no source features."
          } else {
            "No source features match these filters."
          },
        ),
        match geo.zone {
          Some(zone) =>
            render_geo_schematic(features, matching, geo.selected, zone~)
          None => @html.div("")
        },
      ])
    } else {
      @html.div([
        render_geo_schematic(features, matching, geo.selected, zone?=geo.zone),
        @html.div(class="imported-outputs-actions", [
          geo_button(
            dispatch,
            Page(geo.page - 1),
            "Previous features",
            disabled=geo.page == 0,
          ),
          geo_button(
            dispatch,
            Page(geo.page + 1),
            "Next features",
            disabled=end >= matching.length(),
          ),
        ]),
        @html.p(
          "Showing features " +
          (start + 1).to_string() +
          "–" +
          end.to_string() +
          " of " +
          matching.length().to_string() +
          " matches",
        ),
        @html.div(
          style=["max-height:28rem", "overflow:auto"],
          visible.map(index => {
            let feature = features[index]
            @html.article(
              style=[
                "padding:12px", "border:1px solid #ccd5dc", "border-radius:8px",
                "margin-bottom:8px",
              ],
              [
                @html.button(
                  class="square-action",
                  attrs=@html.Attrs::build().aria_pressed(
                    if geo.selected.contains(index) {
                      "true"
                    } else {
                      "false"
                    },
                  ),
                  on_click=dispatch(
                    ImportedOutputsEvent(GeoEvent(Toggle(index))),
                  ),
                  (if geo.selected.contains(index) {
                    "Selected · "
                  } else {
                    "Select · "
                  }) +
                  (index + 1).to_string() +
                  " · " +
                  feature.name,
                ),
                @html.p(
                  feature.kind +
                  " · Category: " +
                  feature.category +
                  " · " +
                  feature.points.length().to_string() +
                  " positions",
                ),
                @html.details([
                  @html.summary("Source properties and coordinates"),
                  @html.pre(
                    class="imported-outputs-text",
                    feature.source.stringify(indent=2),
                  ),
                ]),
              ],
            )
          }),
        ),
      ])
    },
    @html.h3("Selected places, routes and zones"),
    if geo.selected.is_empty() {
      imported_output_status(
        "Select source features to prepare a local export.",
      )
    } else {
      @html.div([
        @html.div(class="imported-outputs-actions", [
          geo_button(
            dispatch,
            Export(false),
            "Download selected features (.geojson)",
          ),
          geo_button(
            dispatch,
            Export(true),
            "Download selected features (.csv)",
          ),
        ]),
        @html.p(
          if state.table is Some(_) {
            "GeoJSON includes mapped coordinates plus every original header and cell in source_table. Selected CSV keeps the original columns and source row order, with formula-leading cells apostrophe-prefixed for spreadsheet safety. Exact original download is unchanged."
          } else {
            "GeoJSON preserves complete selected source features. Spreadsheet-safe CSV has one row per vertex in source order; selections containing polygons include ring and ring_vertex columns (ring 1 is the exterior). Selection exports are local; the exact original download remains available."
          },
        ),
      ])
    },
  ])
}
