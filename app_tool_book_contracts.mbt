///|
fn app_tool_book_config(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
  civic_building_id : String,
  cadence_ticks : Int,
) -> AppToolBookConfig {
  {
    template_id: "app-tool-book",
    template_version: "1",
    book_id: entry.id,
    book_type: "app-tool-book",
    title,
    purpose,
    workspace_root: entry.workspace_root,
    tags: entry.tags,
    skills: entry.skills,
    watch: {
      websites,
      cadence_ticks,
      source_policy: "web-first",
      notify_when: [
        "new_data_found", "analysis_changed", "tool_updated", "tool_build_failed",
        "review_required",
      ],
      required_outputs: [
        "wiki/reports/latest-analysis.md", "tool-manifest.json", "app/index.html",
        "book/site/generated/tool.html",
      ],
    },
    analysis: {
      method_path: "wiki/methods/analysis-method.md",
      report_path: "wiki/reports/latest-analysis.md",
      data_path: "raw/data/latest.json",
      review_path: "wiki/reviews/tool-review.md",
    },
    app: {
      tool_spec_path: "wiki/tools/tool-spec.md",
      manifest_path: "tool-manifest.json",
      app_root: "app/",
      app_entrypoint: "app/index.html",
      generated_tool_path: "book/site/generated/tool.html",
      build_command: "moon run cmd/main -- books app-tool status \{entry.id}",
      review_status: "draft",
    },
    civic: {
      building_id: civic_building_id,
      open_tool_action: "open-generated-tool",
      open_report_action: "open-latest-report",
      configure_action: "configure-in-moondesk",
    },
    moondesk: {
      create_mode: "template-installer",
      editable_files: [
        "book.json", "tool-manifest.json", "wiki/methods/analysis-method.md", "wiki/tools/tool-spec.md",
        "skills/tool-watch/SKILL.md", "skills/tool-build/SKILL.md",
      ],
      output_files: [
        "raw/data/", "wiki/reports/", "app/", "book/site/generated/tool.html", "book/site/generated/index.html",
      ],
    },
  }
}

///|
fn app_tool_book_manifest(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  civic_building_id : String,
) -> AppToolManifest {
  {
    schema: "moontown.app_tool_book.manifest.v1",
    book_id: entry.id,
    title,
    purpose,
    civic_building_id,
    report_path: "wiki/reports/latest-analysis.md",
    app_entrypoint: "app/index.html",
    generated_tool_path: "book/site/generated/tool.html",
    data_path: "raw/data/latest.json",
    tool_spec_path: "wiki/tools/tool-spec.md",
    build_command: "moon run cmd/main -- books app-tool status \{entry.id}",
    review_status: "draft",
    last_successful_build_ms: Some(@env.now()),
  }
}

///|
fn app_tool_book_history_markdown(
  entry : @moonbook.BookCatalogEntry,
  title : String,
) -> String {
  [
    "# App ToolBook Watch History",
    "",
    "- book: `\{entry.id}`",
    "- title: \{title}",
    "- generated_at_ms: `\{@env.now()}`",
    "",
    "Standing watch cycles append source checks, analysis deltas, tool build results, and review decisions here.",
  ].join("\n")
}
