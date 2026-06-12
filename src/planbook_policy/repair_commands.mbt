///|
pub fn repair_required_commands() -> Array[String] {
  [
    "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt --no-render",
    "moon test --no-render", "moon fmt", "moon info", "git diff --check",
  ]
}

///|
pub fn repair_validation_command() -> String {
  repair_required_commands().join(" && ")
}
