///|
fn wenyu_modules() -> Array[WenyuTownModule] {
  parse_bootstrap_wenyu_modules()
}

///|
fn wenyu_module_count() -> Int {
  wenyu_modules().length()
}

///|
fn find_wenyu_module(module_id : String) -> WenyuTownModule? {
  for civic in wenyu_modules() {
    if civic.id == module_id {
      return Some(civic)
    }
  }
  None
}

///|
fn strip_prefix_once(text : String, prefix : String) -> String {
  if text.length() >= prefix.length() &&
    text[:prefix.length()].to_owned() == prefix {
    text[prefix.length():].to_owned()
  } else {
    text
  }
}

///|
fn normalize_module_binding_key(text : String) -> String {
  strip_prefix_once(strip_prefix_once(text, "book-"), "wenyu-")
}

///|
fn module_book_matches(civic : WenyuTownModule, book_id : String) -> Bool {
  book_id == civic.book_id ||
  book_id == civic.id ||
  normalize_module_binding_key(book_id) ==
  normalize_module_binding_key(civic.book_id) ||
  normalize_module_binding_key(book_id) ==
  normalize_module_binding_key(civic.id)
}

///|
fn find_module_for_book(book_id : String) -> WenyuTownModule? {
  for civic in wenyu_modules() {
    if module_book_matches(civic, book_id) {
      return Some(civic)
    }
  }
  None
}

///|
fn find_module_book_projection(
  model : Model,
  civic : WenyuTownModule,
) -> BookProjectionFragment? {
  for projection in model.module_projections {
    if module_book_matches(civic, projection.book_id) {
      return Some(projection)
    }
  }
  None
}

///|
fn find_module_civic_health(
  model : Model,
  civic : WenyuTownModule,
) -> CivicServiceHealthSnapshot? {
  match model.civic_status {
    Some(status) => {
      for health in status.services {
        if module_book_matches(civic, health.book_id) ||
          normalize_module_binding_key(health.service_id) ==
          normalize_module_binding_key(civic.id) {
          return Some(health)
        }
      }
      None
    }
    None => None
  }
}
