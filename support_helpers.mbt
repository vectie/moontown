///|
async fn read_optional_text(path : String) -> String? {
  @support.read_optional_text(path)
}

///|
async fn read_optional_json_file(path : String) -> Json? {
  @support.read_optional_json_file(path)
}

///|
async fn read_json_file_or_empty_object(path : String) -> Json {
  @support.read_json_file_or_empty_object(path)
}

///|
async fn read_text_or_empty(path : String) -> String {
  @support.read_text_or_empty(path)
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  @support.write_text_file(path, content)
}

///|
async fn write_text_file_if_missing(path : String, content : String) -> Unit {
  @support.write_text_file_if_missing(path, content)
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  @support.ensure_parent_directory(path)
}

///|
fn json_string(text : String) -> String {
  @support.json_string(text)
}

///|
fn json_string_array(items : Array[String]) -> String {
  @support.json_string_array(items)
}

///|
fn json_object_string(object : Map[String, Json], key : String) -> String? {
  @support.json_object_string(object, key)
}

///|
fn json_object_field_summary(
  object : Map[String, Json],
  key : String,
) -> String? {
  @support.json_object_field_summary(object, key)
}

///|
fn json_string_field(value : Json, key : String) -> String? {
  @support.json_string_field(value, key)
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  @support.markdown_bullets(values)
}

///|
fn remove_first_markdown_title(report : String) -> String {
  @support.remove_first_markdown_title(report)
}

///|
fn demote_markdown_headings(markdown : String) -> String {
  @support.demote_markdown_headings(markdown)
}

///|
fn section_body(report : String, heading : String) -> String {
  @support.section_body(report, heading)
}

///|
fn first_non_heading_paragraph(markdown : String) -> String {
  @support.first_non_heading_paragraph(markdown)
}

///|
fn markdown_excerpt(text : String, limit : Int) -> String {
  @support.markdown_excerpt(text, limit)
}

///|
fn html_escape(text : String) -> String {
  @support.html_escape(text)
}

///|
fn label_from_slug(value : String) -> String {
  @support.label_from_slug(value)
}

///|
fn upsert_moonclaw_job_profile_json(
  config : Json,
  profile_id : String,
  profile : Json,
) -> Json {
  @support.upsert_moonclaw_job_profile_json(config, profile_id, profile)
}
