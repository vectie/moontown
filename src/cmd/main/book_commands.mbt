///|
async fn render_books_command(args : Array[String]) -> String {
  match args {
    ["quality"] => @book_quality_runtime.render_book_quality()
    ["bootstrap"] =>
      @book_quality_runtime.bootstrap_registered_book_workspaces()
    ["templates"] | ["templates", "status"] =>
      @book_templates_runtime.render_book_template_registry()
    ["template", "install", template_id, config_path] =>
      @book_templates_runtime.install_book_template_config(
        template_id, config_path,
      )
    ["template", "requests"] | ["template", "requests", "status"] =>
      @book_templates_runtime.render_book_template_request_status()
    ["template", "requests", "process"] =>
      @book_templates_runtime.process_book_template_requests()
    ["pdf-watch", .. rest] => render_pdf_watch_command(rest.to_owned())
    ["app-tool", .. rest] => render_app_tool_command(rest.to_owned())
    ["doctor"] => @book_quality_runtime.write_book_quality_audit()
    ["ai-review-packets"] =>
      @book_quality_runtime.write_book_quality_review_packets()
    ["ai-review", "--dispatch"] =>
      @book_quality_runtime.dispatch_next_book_quality_ai_review()
    ["ai-review", "bridge"] =>
      @book_quality_runtime.reconcile_book_quality_repair_bridge()
    ["ai-review", "status"] =>
      @book_quality_runtime.render_book_quality_ai_review_status()
    _ => @moontown.load_or_create_saved_dashboard()
  }
}

///|
async fn render_pdf_watch_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] =>
      @pdf_evidence_watch_runtime.bootstrap_pdf_evidence_watch_book()
    ["bootstrap", book_id] =>
      @pdf_evidence_watch_runtime.bootstrap_pdf_evidence_watch_book(book_id~)
    ["install", config_path] =>
      @pdf_evidence_watch_runtime.install_pdf_evidence_watch_book_config(
        config_path,
      )
    ["archive", book_id] =>
      @pdf_archive_runtime.archive_pdf_evidence_watch_book(book_id~)
    ["status"] =>
      @pdf_evidence_watch_runtime.render_pdf_evidence_watch_book_status()
    ["status", book_id] =>
      @pdf_evidence_watch_runtime.render_pdf_evidence_watch_book_status(
        book_id~,
      )
    _ => @moontown.load_or_create_saved_dashboard()
  }
}

///|
async fn render_app_tool_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @app_tool_book_runtime.bootstrap_app_tool_book()
    ["bootstrap", book_id] =>
      @app_tool_book_runtime.bootstrap_app_tool_book(book_id~)
    ["install", config_path] =>
      @app_tool_book_runtime.install_app_tool_book_config(config_path)
    ["status"] => @app_tool_book_runtime.render_app_tool_book_status()
    ["status", book_id] =>
      @app_tool_book_runtime.render_app_tool_book_status(book_id~)
    _ => @moontown.load_or_create_saved_dashboard()
  }
}
