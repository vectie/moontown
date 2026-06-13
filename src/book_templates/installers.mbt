///|
struct BookTemplateInstaller {
  template_id : String
} derive(Debug, Eq)

///|
fn book_template_installers() -> Array[BookTemplateInstaller] {
  [{ template_id: "pdf-evidence-watch" }, { template_id: "app-tool-book" }]
}

///|
fn find_book_template_installer(template_id : String) -> BookTemplateInstaller? {
  for installer in book_template_installers() {
    if installer.template_id == template_id {
      return Some(installer)
    }
  }
  None
}

///|
async fn BookTemplateInstaller::install_config(
  self : BookTemplateInstaller,
  config_path : String,
  book_catalog_path : String,
  standing_goal_path : String,
) -> String {
  match self.template_id {
    "pdf-evidence-watch" =>
      @pdf_evidence_watch.install_pdf_evidence_watch_book_config(
        config_path,
        book_catalog_path~,
        standing_goal_path~,
      )
    "app-tool-book" =>
      @app_tool_book_runtime.install_app_tool_book_config(
        config_path,
        book_catalog_path~,
        standing_goal_path~,
      )
    id => registered_without_installer_summary(id)
  }
}
