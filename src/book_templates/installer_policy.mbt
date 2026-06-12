///|
pub fn registered_without_installer_summary(template_id : String) -> String {
  "Book template `\{template_id}` is registered but has no installer yet."
}

///|
pub fn unknown_template_summary(template_id : String) -> String {
  "Unknown book template: \{template_id}"
}
