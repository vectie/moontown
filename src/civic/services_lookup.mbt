///|
pub fn wenyu_civic_service_for_module_id(
  module_id : String,
) -> CivicServiceDefinition? {
  let key = civic_binding_key(module_id)
  for service in wenyu_civic_services() {
    if civic_binding_key(service.id) == key {
      return Some(service)
    }
  }
  None
}

///|
pub fn wenyu_civic_service_for_book_id(
  book_id : String,
) -> CivicServiceDefinition? {
  let key = civic_binding_key(book_id)
  for service in wenyu_civic_services() {
    if civic_binding_key(service.book_id) == key ||
      civic_binding_key(service.id) == key {
      return Some(service)
    }
  }
  None
}

///|
pub fn is_wenyu_civic_book_id(book_id : String) -> Bool {
  wenyu_civic_service_for_book_id(book_id) != None
}

///|
pub fn is_wenyu_book_entry(
  id : String,
  name : String,
  tags : Array[String],
) -> Bool {
  @policy.catalog_entry_type(id, name, tags) == @policy.civic_type() &&
  id.has_prefix("wenyu-")
}

///|
pub fn is_wenyu_build_book_entry(
  id : String,
  name : String,
  tags : Array[String],
) -> Bool {
  is_wenyu_book_entry(id, name, tags) &&
  wenyu_civic_service_for_book_id(id) == None
}
