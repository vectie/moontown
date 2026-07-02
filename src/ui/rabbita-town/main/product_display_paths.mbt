///|
fn moontown_product_display_state_dir() -> String {
  ".moonsuite/products/moontown"
}

///|
fn moontown_product_display_artifact(relative : String) -> String {
  if relative == "" {
    moontown_product_display_state_dir()
  } else {
    "\{moontown_product_display_state_dir()}/\{relative}"
  }
}

///|
fn moontown_product_display_artifact_code(relative : String) -> String {
  "`\{moontown_product_display_artifact(relative)}`"
}
