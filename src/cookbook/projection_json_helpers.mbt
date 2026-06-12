///|
fn cookbook_write_json_array(
  builder : StringBuilder,
  field : String,
  items : Array[String],
  trailing_comma~ : Bool,
) -> Unit {
  builder.write_string("  \"\{field}\": [\n")
  builder.write_string(items.join(",\n"))
  builder.write_string("\n")
  builder.write_string(if trailing_comma { "  ],\n" } else { "  ]\n" })
}

///|
fn cookbook_chip_json(label : String, tone : String) -> String {
  "    {\"label\":\{json_string(label)},\"tone\":\{json_string(tone)}}"
}

///|
fn cookbook_metric_json(
  label : String,
  value : String,
  note : String,
  tone : String,
) -> String {
  "    {\"label\":\{json_string(label)},\"value\":\{value},\"note\":\{json_string(note)},\"tone\":\{json_string(tone)}}"
}

///|
fn cookbook_item_json(
  title : String,
  detail : String,
  meta : String,
  detail_is_json? : Bool = false,
) -> String {
  let detail_value = if detail_is_json { detail } else { json_string(detail) }
  "    {\"title\":\{json_string(title)},\"detail\":\{detail_value},\"meta\":\{json_string(meta)}}"
}

///|
fn cookbook_journey_item_json(
  title : String,
  stage : String,
  status : String,
  summary : String,
  highlights : Array[String],
) -> String {
  let title_field = "\"title\":\{json_string(title)}"
  let stage_field = "\"stage\":\{json_string(stage)}"
  let status_field = "\"status\":\{json_string(status)}"
  let summary_field = "\"summary\":\{json_string(summary)}"
  let highlights_field = "\"highlights\":\{json_string_array(highlights)}"
  "    {\{[title_field, stage_field, status_field, summary_field, highlights_field].join(",")}}"
}

///|
fn cookbook_link_json(label : String, kind : String, url : String) -> String {
  "    {\"label\":\{json_string(label)},\"kind\":\{json_string(kind)},\"url\":\{json_string(url)}}"
}
