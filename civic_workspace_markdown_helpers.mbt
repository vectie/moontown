///|
fn schema_title(path : String) -> String {
  let name = label_from_slug(
    @support.path_basename(path).replace(old=".md", new=""),
  )
  name
}
