///|
pub fn label_from_slug(value : String) -> String {
  value.replace(old="-", new=" ").replace(old="_", new=" ")
}
