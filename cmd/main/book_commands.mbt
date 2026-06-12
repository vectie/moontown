///|
async fn render_books_command(args : Array[String]) -> String {
  match args {
    ["quality"] => @moontown.render_book_quality()
    ["bootstrap"] => @moontown.bootstrap_registered_book_workspaces()
    ["templates"] | ["templates", "status"] =>
      @moontown.render_book_template_registry()
    ["template", "install", template_id, config_path] =>
      @moontown.install_book_template_config(template_id, config_path)
    ["template", "requests"] | ["template", "requests", "status"] =>
      @moontown.render_book_template_request_status()
    ["template", "requests", "process"] =>
      @moontown.process_book_template_requests()
    ["pdf-watch", .. rest] => render_pdf_watch_command(rest.to_owned())
    ["app-tool", .. rest] => render_app_tool_command(rest.to_owned())
    ["doctor"] => @moontown.write_book_quality_audit()
    ["ai-review-packets"] => @moontown.write_book_quality_review_packets()
    ["ai-review", "--dispatch"] =>
      @moontown.dispatch_next_book_quality_ai_review()
    ["ai-review", "bridge"] => @moontown.reconcile_book_quality_repair_bridge()
    ["ai-review", "status"] => @moontown.render_book_quality_ai_review_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_pdf_watch_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @pdf_evidence_watch.bootstrap_pdf_evidence_watch_book()
    ["bootstrap", book_id] =>
      @pdf_evidence_watch.bootstrap_pdf_evidence_watch_book(book_id~)
    ["install", config_path] =>
      @pdf_evidence_watch.install_pdf_evidence_watch_book_config(config_path)
    ["archive", book_id] =>
      @pdf_archive.archive_pdf_evidence_watch_book(book_id~)
    ["status"] => @pdf_evidence_watch.render_pdf_evidence_watch_book_status()
    ["status", book_id] =>
      @pdf_evidence_watch.render_pdf_evidence_watch_book_status(book_id~)
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_app_tool_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @moontown.bootstrap_app_tool_book()
    ["bootstrap", book_id] => @moontown.bootstrap_app_tool_book(book_id~)
    ["install", config_path] =>
      @moontown.install_app_tool_book_config(config_path)
    ["status"] => @moontown.render_app_tool_book_status()
    ["status", book_id] => @moontown.render_app_tool_book_status(book_id~)
    _ => @moontown.load_or_create_demo_dashboard()
  }
}
