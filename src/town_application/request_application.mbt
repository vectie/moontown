///|
pub struct RequestApplication {
  state_root : String
  operator_policy_path : String
}

///|
pub fn request_application(
  state_root : String,
  operator_policy_path : String,
) -> RequestApplication {
  { state_root, operator_policy_path }
}

///|
pub fn default_request_application(
  operator_policy_path : String,
) -> RequestApplication {
  request_application(
    @storage.moontown_product_state_dir(),
    operator_policy_path,
  )
}
