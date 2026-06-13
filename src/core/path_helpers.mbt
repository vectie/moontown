///|
pub fn absolute_path_from_base(base : String, path : String) -> String {
  if path.has_prefix("/") {
    path
  } else {
    @path.Path(base).join(@path.Path(path)).to_string()
  }
}
