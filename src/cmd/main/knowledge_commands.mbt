///|
async fn render_knowledge_command(args : Array[String]) -> String {
  match args {
    ["catalog"] => @domain_catalog_runtime.render_knowledge_domain_catalog()
    ["catalog", catalog_path] =>
      @domain_catalog_runtime.render_knowledge_domain_catalog(catalog_path~)
    ["status"] =>
      @domain_catalog_runtime.render_knowledge_domain_catalog_status()
    ["status", catalog_path] =>
      @domain_catalog_runtime.render_knowledge_domain_catalog_status(
        catalog_path~,
      )
    ["seed"] => @domain_catalog_runtime.seed_knowledge_domain_catalog()
    ["seed", catalog_path] =>
      @domain_catalog_runtime.seed_knowledge_domain_catalog(catalog_path~)
    _ => @moontown.load_or_create_saved_dashboard()
  }
}
