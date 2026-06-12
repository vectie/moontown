///|
pub fn catalog_entry_active(
  id : String,
  name : String,
  purpose : String,
  tags : Array[String],
) -> Bool {
  @policy.catalog_entry_active(id, name, purpose, tags)
}

///|
pub fn catalog_entry_type(
  id : String,
  name : String,
  tags : Array[String],
) -> String {
  @policy.catalog_entry_type(id, name, tags)
}
