///|
fn ai_garden_book_ids() -> Array[String] {
  ["wenyu-ai-garden", "ai-garden"]
}

///|
fn ai_garden_runtime_context(model : Model) -> CivicModuleRuntimeContext {
  civic_module_priority_runtime_context_by_ids(model, ai_garden_book_ids())
}
