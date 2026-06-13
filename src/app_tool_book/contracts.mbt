///|
pub fn template_root() -> String {
  "assets/templates/books/app-tool-book"
}

///|
pub fn default_book_id() -> String {
  "toolbook-data-watch-dashboard"
}

///|
pub fn default_purpose() -> String {
  "Watch configured sources, analyze changing data, maintain durable reports, and expose a usable generated web tool through a civic building."
}

///|
fn generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
fn generated_site_workspace_path(root : String) -> String {
  "\{root}/\{generated_site_path()}"
}

///|
fn generated_tool_path() -> String {
  "book/site/generated/tool.html"
}

///|
fn generated_tool_workspace_path(root : String) -> String {
  "\{root}/\{generated_tool_path()}"
}

///|
pub fn config(
  book_id : String,
  title : String,
  purpose : String,
  workspace_root : String,
  tags : Array[String],
  skills : Array[String],
  websites : Array[String],
  civic_building_id : String,
  cadence_ticks : Int,
) -> AppToolBookConfig {
  {
    template_id: "app-tool-book",
    template_version: "1",
    book_id,
    book_type: @policy.general_type(),
    title,
    purpose,
    workspace_root,
    tags,
    skills,
    watch: {
      websites,
      cadence_ticks,
      source_policy: @policy.web_first_policy(),
      notify_when: [
        "new_data_found", "analysis_changed", "tool_updated", "tool_build_failed",
        "review_required",
      ],
      required_outputs: [
        "wiki/reports/latest-analysis.md",
        "tool-manifest.json",
        "app/index.html",
        generated_tool_path(),
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
      generated_tool_path: generated_tool_path(),
      build_command: "moon run src/cmd/main -- books app-tool status \{book_id}",
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
        "raw/data/",
        "wiki/reports/",
        "app/",
        generated_tool_path(),
        generated_site_path(),
      ],
    },
  }
}

///|
pub fn config_with_catalog_identity(
  book_id : String,
  title : String,
  purpose : String,
  workspace_root : String,
  websites : Array[String],
  civic_building_id : String,
  cadence_ticks : Int,
) -> AppToolBookConfig {
  config(
    book_id,
    title,
    purpose,
    workspace_root,
    catalog_tags(),
    catalog_skills(),
    websites,
    civic_building_id,
    cadence_ticks,
  )
}

///|
pub fn manifest(
  book_id : String,
  title : String,
  purpose : String,
  civic_building_id : String,
  last_successful_build_ms : UInt64?,
) -> AppToolManifest {
  {
    schema: "moontown.app_tool_book.manifest.v1",
    book_id,
    title,
    purpose,
    civic_building_id,
    report_path: "wiki/reports/latest-analysis.md",
    app_entrypoint: "app/index.html",
    generated_tool_path: generated_tool_path(),
    data_path: "raw/data/latest.json",
    tool_spec_path: "wiki/tools/tool-spec.md",
    build_command: "moon run src/cmd/main -- books app-tool status \{book_id}",
    review_status: "draft",
    last_successful_build_ms,
  }
}

///|
fn path_specs() -> Array[AppToolBookPathSpec] {
  [
    { path: "book.json", copy_from_template: false },
    { path: "tool-manifest.json", copy_from_template: false },
    {
      path: "raw/bootstrap/APP_TOOL_BOOK_CONTRACT.md",
      copy_from_template: true,
    },
    { path: "wiki/index.md", copy_from_template: true },
    { path: "wiki/methods/analysis-method.md", copy_from_template: true },
    { path: "wiki/tools/tool-spec.md", copy_from_template: true },
    { path: "wiki/reports/latest-analysis.md", copy_from_template: true },
    { path: "wiki/reviews/tool-review.md", copy_from_template: true },
    { path: "skills/tool-watch/SKILL.md", copy_from_template: true },
    { path: "skills/tool-build/SKILL.md", copy_from_template: true },
    { path: "schemas/tool-manifest.schema.md", copy_from_template: true },
    { path: "app/index.html", copy_from_template: false },
    { path: "app/tool.js", copy_from_template: true },
    { path: "app/styles.css", copy_from_template: true },
    { path: generated_site_path(), copy_from_template: false },
    { path: generated_tool_path(), copy_from_template: false },
  ]
}

///|
pub fn required_paths() -> Array[String] {
  path_specs().map(fn(spec) { spec.path })
}

///|
pub fn resolved_workspace_root(
  book_id : String,
  workspace_root : String,
) -> String {
  if workspace_root.is_empty() {
    @moonbook.default_workspace_root(book_id)
  } else {
    workspace_root
  }
}

///|
pub async fn missing_required_paths(workspace_root : String) -> Array[String] {
  let missing : Array[String] = []
  for path in required_paths() {
    if !@fs.exists("\{workspace_root}/\{path}") {
      missing.push(path)
    }
  }
  missing
}

///|
pub fn template_copy_paths() -> Array[String] {
  path_specs()
  .filter(fn(spec) { spec.copy_from_template })
  .map(fn(spec) { spec.path })
}

///|
pub fn status(
  book_id : String,
  workspace_root : String,
  missing_paths : Array[String],
  has_catalog_entry~ : Bool,
  has_standing_goal~ : Bool,
  standing_goal_enabled~ : Bool,
  has_tool_manifest~ : Bool,
) -> AppToolBookStatus {
  let required_count = required_paths().length()
  {
    book_id,
    workspace_root,
    required_count,
    missing_count: missing_paths.length(),
    missing_paths,
    has_catalog_entry,
    has_standing_goal,
    standing_goal_enabled,
    has_tool_manifest,
    ready: missing_paths.is_empty() &&
    has_catalog_entry &&
    has_standing_goal &&
    standing_goal_enabled &&
    has_tool_manifest,
  }
}
