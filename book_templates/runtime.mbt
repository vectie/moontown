///|
pub async fn install_book_template_config(
  template_id : String,
  config_path : String,
  registry_path? : String = default_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let registry = inspect_registry(registry_path~)
  match find_registry_descriptor(registry.templates, template_id) {
    Some(template) =>
      match find_book_template_installer(template.template_id) {
        Some(installer) =>
          installer.install_config(
            config_path, book_catalog_path, standing_goal_path,
          )
        None => registered_without_installer_summary(template_id)
      }
    None => unknown_template_summary(template_id)
  }
}
