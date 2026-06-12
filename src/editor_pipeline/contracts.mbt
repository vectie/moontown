///|
pub fn feature_selection_result_contract() -> String {
  "moontown.editor_feature_selection.v1"
}

///|
pub fn selected_feature_implementation_contract() -> String {
  "moontown.editor_selected_feature_implementation.v1"
}

///|
pub fn feature_selection_result_satisfies_contract(text : String) -> Bool {
  text.contains(feature_selection_result_contract()) &&
  text.contains("selected_feature") &&
  text.contains("score") &&
  text.contains("implementation_hint") &&
  text.contains("acceptance")
}
