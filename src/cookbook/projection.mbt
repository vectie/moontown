///|
pub fn ui_state_json(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> String {
  let summary = CookbookArtifactSummary::from_artifacts(manifest.artifacts)
  let docs_value = json_string("\{summary.docs_count}")
  let definitions_value = json_string("\{summary.definition_count}")
  let runtime_value = json_string("\{summary.runtime_state_count}")
  let missing_value = json_string("\{summary.required_missing_count()}")
  let manifest_path_value = json_string(manifest.manifest_path)
  let builder = StringBuilder::new()
  builder.write_string("{\n")
  builder.write_string("  \"book_id\": \{json_string(entry.id)},\n")
  builder.write_string("  \"title\": \"MoonTown Stable-State Cookbook\",\n")
  builder.write_string(
    "  \"summary\": \"Generated control book for docs, definitions, runtime state, and ownership contracts.\",\n",
  )
  cookbook_write_json_array(
    builder,
    "status_chips",
    cookbook_status_chips_json(),
    trailing_comma=true,
  )
  cookbook_write_json_array(
    builder,
    "metrics",
    cookbook_metrics_json(
      docs_value, definitions_value, runtime_value, missing_value,
    ),
    trailing_comma=true,
  )
  cookbook_write_json_array(
    builder,
    "readiness",
    cookbook_readiness_json(manifest_path_value),
    trailing_comma=true,
  )
  cookbook_write_json_array(
    builder,
    "review_queue",
    cookbook_review_queue_json(),
    trailing_comma=true,
  )
  cookbook_write_json_array(
    builder,
    "page_families",
    cookbook_page_families_json(),
    trailing_comma=true,
  )
  cookbook_write_json_array(
    builder,
    "journey",
    cookbook_journey_json(entry, manifest),
    trailing_comma=true,
  )
  cookbook_write_json_array(
    builder,
    "links",
    cookbook_links_json(),
    trailing_comma=false,
  )
  builder.write_string("\n")
  builder.write_string("}")
  builder.to_string()
}
