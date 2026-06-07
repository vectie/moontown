///|
fn social_square_book_ids() -> Array[String] {
  ["social-square", "wenyu-social-square"]
}

///|
fn social_square_runtime_context(model : Model) -> CivicModuleRuntimeContext {
  civic_module_priority_runtime_context_by_ids(model, social_square_book_ids())
}
