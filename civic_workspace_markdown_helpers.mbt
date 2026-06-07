///|
fn schema_title(path : String) -> String {
  let name = label_from_slug(path_basename(path).replace(old=".md", new=""))
  name
}
