///|
pub fn absolute_path_from_base(base : String, path : String) -> String {
  if path.has_prefix("/") {
    path
  } else {
    town_core_path(base).join(town_core_path(path)).to_string()
  }
}
