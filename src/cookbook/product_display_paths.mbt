///|
fn cookbook_product_path(relative : String) -> String {
  @storage.moontown_product_display_artifact(relative)
}

///|
fn cookbook_product_path_code(relative : String) -> String {
  "`\{cookbook_product_path(relative)}`"
}

///|
fn cookbook_product_home_code() -> String {
  "`\{@storage.moontown_product_display_state_dir()}`"
}
