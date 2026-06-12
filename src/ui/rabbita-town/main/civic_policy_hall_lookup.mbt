///|
fn policy_hall_book_ids() -> Array[String] {
  ["wenyu-policy-hall", "policy-hall"]
}

///|
fn policy_hall_runtime_context(model : Model) -> CivicModuleRuntimeContext {
  civic_module_priority_runtime_context_by_ids(model, policy_hall_book_ids())
}
