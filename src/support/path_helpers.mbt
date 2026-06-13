///|
pub fn absolute_path_from_base(base : String, path : String) -> String {
  @core.absolute_path_from_base(base, path)
}

///|
pub fn absolute_path_from_cwd(path : String) -> String {
  absolute_path_from_base(
    match @env.current_dir() {
      Some(dir) => dir
      None => "."
    },
    path,
  )
}
