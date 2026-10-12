///|
fn render_geo_zone_filter(
  dispatch : Dispatch[Msg],
  geo : GeoState,
  features : Array[@imported_output_contract.GeoFeature],
) -> @rabbita.Html {
  let options = [
    @html.option(value="", selected=geo.zone is None, "All locations"),
  ]
  for i, feature in features {
    if feature.kind == "Polygon" {
      options.push(
        @html.option(
          value=i.to_string(),
          selected=geo.zone == Some(i),
          (i + 1).to_string() + " · " + feature.name,
        ),
      )
    }
  }
  if options.length() == 1 {
    return @html.div("")
  }
  @html.div([
    @html.label(for_="geo-zone", "Find places in a zone"),
    @html.select(
      id="geo-zone",
      class="request-input",
      on_change=value => dispatch(ImportedOutputsEvent(GeoEvent(Zone(value)))),
      options,
    ),
    @html.p(
      "A zone filters Point places only, combined with your search. Exterior edges are included; holes and hole edges are excluded. Uses planar longitude/latitude, not legal boundaries or navigation. Changing geometry kind clears the zone filter. Existing selection is kept; use Select all matching to replace it.",
    ),
  ])
}
