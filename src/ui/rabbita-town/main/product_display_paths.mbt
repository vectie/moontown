///|
fn moontown_product_display_artifact(relative : String) -> String {
  @moonsuite.product_display_artifact("moontown", relative)
}

///|
fn moontown_product_display_artifact_code(relative : String) -> String {
  "`\{moontown_product_display_artifact(relative)}`"
}
