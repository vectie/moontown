///|
pub struct RequestApplication {
  state_root : String
  operator_policy_path : String
  catalog_path : String
}

///|
pub fn request_application(
  state_root : String,
  operator_policy_path : String,
  catalog_path? : String = state_root + "/moonbooks.json",
) -> RequestApplication {
  { state_root, operator_policy_path, catalog_path, }
}

///|
pub fn default_request_application(
  operator_policy_path : String,
) -> RequestApplication {
  request_application(
    @storage.moontown_product_state_dir(),
    operator_policy_path,
    catalog_path=@moonbook.default_catalog_path(),
  )
}
