///|
struct PdfEvidenceWatchConfig {
  template_id : String
  template_version : String
  book_id : String
  book_type : String
  title : String
  purpose : String
  workspace_root : String
  tags : Array[String]
  skills : Array[String]
  watch : PdfEvidenceWatchSettings
  analysis : PdfEvidenceWatchAnalysisSettings
  moondesk : PdfEvidenceWatchMoondeskSettings
} derive(Debug, Eq, ToJson, FromJson)

///|
struct PdfEvidenceWatchSettings {
  websites : Array[String]
  cadence_ticks : Int
  source_policy : String
  notify_when : Array[String]
  required_outputs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct PdfEvidenceWatchAnalysisSettings {
  method_path : String
  source_registry_path : String
  findings_path : String
  review_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
struct PdfEvidenceWatchMoondeskSettings {
  create_mode : String
  editable_files : Array[String]
  output_files : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct PdfEvidenceWatchInstallSpec {
  book_id : String
  title : String
  purpose : String
  websites : Array[String]
  analysis_method : String
  analysis_method_path : String
  cadence_ticks : Int
  workspace_root : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct PdfEvidenceWatchBookStatus {
  book_id : String
  workspace_root : String
  required_count : Int
  missing_count : Int
  missing_paths : Array[String]
  has_catalog_entry : Bool
  has_standing_goal : Bool
  standing_goal_enabled : Bool
  ready : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_pdf_evidence_watch_template_root() -> String {
  "templates/books/pdf-evidence-watch"
}

///|
pub fn default_pdf_evidence_watch_book_id() -> String {
  "research-pdf-evidence-watch"
}

///|
pub fn default_pdf_evidence_watch_workspace_root(
  book_id? : String = default_pdf_evidence_watch_book_id(),
) -> String {
  @moonbook.default_workspace_root(book_id)
}

///|
pub async fn bootstrap_pdf_evidence_watch_book(
  book_id? : String = default_pdf_evidence_watch_book_id(),
  title? : String = "PDF Evidence Watch",
  purpose? : String = default_pdf_evidence_watch_purpose(),
  websites? : Array[String] = [],
  analysis_method? : String = "",
  cadence_ticks? : Int = 60,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  workspace_root? : String = "",
  template_root? : String = default_pdf_evidence_watch_template_root(),
) -> String {
  let root = if workspace_root.is_empty() {
    default_pdf_evidence_watch_workspace_root(book_id~)
  } else {
    workspace_root
  }
  let entry = pdf_evidence_watch_catalog_entry(book_id, title, purpose, root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_single_book(catalog, entry),
  )
  write_pdf_evidence_watch_workspace(
    entry, title, purpose, websites, analysis_method, cadence_ticks, template_root,
  )
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let goal = pdf_evidence_watch_standing_goal(
    book_id, title, purpose, websites, cadence_ticks,
  )
  @storage.save_standing_goals_file(
    standing_goal_path,
    upsert_pdf_evidence_watch_standing_goal(goals, goal),
  )
  let status = inspect_pdf_evidence_watch_book(
    book_id~,
    workspace_root=root,
    book_catalog_path~,
    standing_goal_path~,
  )
  [
    "Bootstrapped PDF Evidence Watch book `\{book_id}`.",
    "- Workspace: `\{root}`",
    "- Catalog: `\{book_catalog_path}`",
    "- Standing goal: `\{goal.id}` in `\{standing_goal_path}`",
    "- Websites: `\{websites.length()}`",
    "- Ready: `\{status.ready}`",
    "- Missing required: `\{status.missing_count}`",
  ].join("\n")
}

///|
pub async fn install_pdf_evidence_watch_book_config(
  config_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  template_root? : String = default_pdf_evidence_watch_template_root(),
) -> String {
  match load_pdf_evidence_watch_install_spec(config_path) {
    Some(spec) => {
      let base_dir = @path.Path::dirname(config_path).to_string()
      let analysis_method = resolve_pdf_evidence_watch_analysis_method(
        spec, base_dir,
      )
      let workspace_root = if spec.workspace_root.trim().is_empty() {
        default_pdf_evidence_watch_workspace_root(book_id=spec.book_id)
      } else {
        resolve_pdf_evidence_watch_relative_path(base_dir, spec.workspace_root)
      }
      let summary = bootstrap_pdf_evidence_watch_book(
        book_id=spec.book_id,
        title=spec.title,
        purpose=spec.purpose,
        websites=spec.websites,
        analysis_method~,
        cadence_ticks=spec.cadence_ticks,
        book_catalog_path~,
        standing_goal_path~,
        workspace_root~,
        template_root~,
      )
      "Installed PDF Evidence Watch config `\{config_path}`.\n\{summary}"
    }
    None => "Could not load PDF Evidence Watch config: \{config_path}"
  }
}

///|
pub async fn inspect_pdf_evidence_watch_book(
  book_id? : String = default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> PdfEvidenceWatchBookStatus {
  let root = if workspace_root.is_empty() {
    default_pdf_evidence_watch_workspace_root(book_id~)
  } else {
    workspace_root
  }
  let required = pdf_evidence_watch_required_paths()
  let missing : Array[String] = []
  for path in required {
    if !@fs.exists("\{root}/\{path}") {
      missing.push(path)
    }
  }
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let has_catalog_entry = @moonbook.entry_for_book_id(catalog, book_id)
    is Some(_)
  let goal_id = pdf_evidence_watch_goal_id(book_id)
  let has_standing_goal = pdf_evidence_watch_goal_in(goals, goal_id)
  let standing_goal_enabled = pdf_evidence_watch_goal_enabled_in(goals, goal_id)
  {
    book_id,
    workspace_root: root,
    required_count: required.length(),
    missing_count: missing.length(),
    missing_paths: missing,
    has_catalog_entry,
    has_standing_goal,
    standing_goal_enabled,
    ready: missing.is_empty() &&
    has_catalog_entry &&
    has_standing_goal &&
    standing_goal_enabled,
  }
}

///|
pub async fn archive_pdf_evidence_watch_book(
  book_id? : String = default_pdf_evidence_watch_book_id(),
  reason? : String = "Archived by operator.",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  request_event_path? : String = default_book_template_request_event_path(),
) -> String {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let archived_catalog = archive_pdf_evidence_watch_catalog_entry(
    catalog, book_id, reason,
  )
  @moonbook.save_catalog_file(book_catalog_path, archived_catalog)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let goal_id = pdf_evidence_watch_goal_id(book_id)
  let disabled_goals = disable_pdf_evidence_watch_book_standing_goals(
    goals, book_id,
  )
  let disabled_count = count_disabled_pdf_evidence_watch_book_standing_goals(
    goals, disabled_goals, book_id,
  )
  @storage.save_standing_goals_file(standing_goal_path, disabled_goals)
  let status = inspect_pdf_evidence_watch_book(
    book_id~,
    book_catalog_path~,
    standing_goal_path~,
  )
  let summary = "Archived PDF Evidence Watch book `\{book_id}`; standing goal `\{goal_id}` enabled=`\{status.standing_goal_enabled}`; disabled_goals=\{disabled_count}. Reason: \{reason}"
  append_book_template_request_event(request_event_path, {
    id: "archive-\{book_id}-\{@env.now()}",
    request_id: "archive-\{book_id}",
    template_id: "pdf-evidence-watch",
    status: "archived",
    config_path: "",
    summary,
    tick: 0,
    generated_at_ms: @env.now(),
  })
  [
    "Archived PDF Evidence Watch book `\{book_id}`.",
    "- Reason: \{reason}",
    "- Catalog: `\{book_catalog_path}`",
    "- Standing goal: `\{goal_id}` enabled=`\{status.standing_goal_enabled}`",
    "- Disabled standing goals targeting this book: `\{disabled_count}`",
    "- Lifecycle event log: `\{request_event_path}`",
    "- Workspace preserved: `\{status.workspace_root}`",
    "- Ready for autonomous watching: `\{status.ready}`",
  ].join("\n")
}

///|
pub async fn render_pdf_evidence_watch_book_status(
  book_id? : String = default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let status = inspect_pdf_evidence_watch_book(
    book_id~,
    workspace_root~,
    book_catalog_path~,
    standing_goal_path~,
  )
  [
    "# PDF Evidence Watch Book Status",
    "",
    "- Book: `\{status.book_id}`",
    "- Workspace: `\{status.workspace_root}`",
    "- Ready: `\{status.ready}`",
    "- Catalog entry: `\{status.has_catalog_entry}`",
    "- Standing goal: `\{status.has_standing_goal}`",
    "- Standing goal enabled: `\{status.standing_goal_enabled}`",
    "- Missing required: `\{status.missing_count}` / `\{status.required_count}`",
    "",
    "## Missing",
    "",
    if status.missing_paths.is_empty() {
      "- none"
    } else {
      markdown_bullets(status.missing_paths)
    },
  ].join("\n")
}

///|
async fn load_pdf_evidence_watch_install_spec(
  config_path : String,
) -> PdfEvidenceWatchInstallSpec? {
  if !@fs.exists(config_path) {
    return None
  }
  let text = @fs.read_file(config_path).text() catch { _ => return None }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn resolve_pdf_evidence_watch_analysis_method(
  spec : PdfEvidenceWatchInstallSpec,
  base_dir : String,
) -> String {
  if !spec.analysis_method.trim().is_empty() {
    return spec.analysis_method
  }
  if spec.analysis_method_path.trim().is_empty() {
    return ""
  }
  read_text_or_empty(
    resolve_pdf_evidence_watch_relative_path(
      base_dir,
      spec.analysis_method_path,
    ),
  )
}

///|
fn resolve_pdf_evidence_watch_relative_path(
  base_dir : String,
  path : String,
) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}

///|
fn pdf_evidence_watch_catalog_entry(
  book_id : String,
  title : String,
  purpose : String,
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=book_id,
    name="MoonBook / PDF Evidence Watch / \{title}",
    purpose~,
    workspace_root~,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=[
      "research", "standing-watch", "pdf-evidence", "source-first", "template:pdf-evidence-watch",
    ],
    skills=[
      "pdf-watch", "pdf-analysis", "source-screening", "evidence-review", "notification-digest",
    ],
  )
}

///|
async fn write_pdf_evidence_watch_workspace(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
  analysis_method : String,
  cadence_ticks : Int,
  template_root : String,
) -> Unit {
  let root = entry.workspace_root
  for path in pdf_evidence_watch_template_copy_paths() {
    copy_pdf_evidence_watch_template_file(template_root, root, path)
  }
  write_text_file(
    "\{root}/book.json",
    pdf_evidence_watch_config(entry, title, purpose, websites, cadence_ticks)
    .to_json()
    .stringify(indent=2),
  )
  write_text_file_if_missing("\{root}/raw/pdfs/.keep", "")
  write_text_file_if_missing("\{root}/raw/extracted/.keep", "")
  write_text_file_if_missing("\{root}/raw/analysis-runs/.keep", "")
  write_text_file_if_missing(
    "\{root}/wiki/history/standing-watch.md",
    pdf_evidence_watch_history_markdown(entry, title),
  )
  if !analysis_method.trim().is_empty() {
    write_text_file("\{root}/wiki/methods/analysis-method.md", analysis_method)
  }
  let html = pdf_evidence_watch_generated_site_html(
    entry, title, purpose, websites,
  )
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

///|
async fn copy_pdf_evidence_watch_template_file(
  template_root : String,
  workspace_root : String,
  relative_path : String,
) -> Unit {
  let source = "\{template_root}/\{relative_path}"
  let content = read_text_or_empty(source)
  if content.trim().is_empty() {
    return
  }
  write_text_file("\{workspace_root}/\{relative_path}", content)
}

///|
fn pdf_evidence_watch_config(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
  cadence_ticks : Int,
) -> PdfEvidenceWatchConfig {
  {
    template_id: "pdf-evidence-watch",
    template_version: "1",
    book_id: entry.id,
    book_type: "pdf-evidence-watch",
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
        "new_pdf_found", "new_pdf_downloaded", "new_text_extracted", "new_claim_accepted",
        "important_revision_detected",
      ],
      required_outputs: [
        "wiki/sources/*.md", "wiki/findings/*.md", "wiki/history/standing-watch.md",
        "book/site/generated/index.html",
      ],
    },
    analysis: {
      method_path: "wiki/methods/analysis-method.md",
      source_registry_path: "wiki/sources/README.md",
      findings_path: "wiki/findings/README.md",
      review_path: "wiki/reviews/pdf-watch-review.md",
    },
    moondesk: {
      create_mode: "template-installer",
      editable_files: [
        "book.json", "wiki/methods/analysis-method.md", "skills/pdf-watch/SKILL.md",
        "skills/pdf-analysis/SKILL.md",
      ],
      output_files: [
        "raw/pdfs/", "raw/extracted/", "wiki/sources/", "wiki/findings/", "book/site/generated/index.html",
      ],
    },
  }
}

///|
fn pdf_evidence_watch_standing_goal(
  book_id : String,
  title : String,
  purpose : String,
  websites : Array[String],
  cadence_ticks : Int,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=pdf_evidence_watch_goal_id(book_id),
    title="Watch PDFs for \{title}",
    prompt=pdf_evidence_watch_goal_prompt(title, purpose, websites),
    target_book_id=Some(book_id),
    cadence_ticks~,
    next_due_tick=0,
    source_policy="web-first",
    quality_threshold=90,
  )
}

///|
fn upsert_pdf_evidence_watch_standing_goal(
  goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  for existing in goals {
    if existing.id != goal.id {
      updated.push(existing)
    }
  }
  updated.push(goal)
  updated
}

///|
fn pdf_evidence_watch_goal_in(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  for goal in goals {
    if goal.id == goal_id {
      return true
    }
  }
  false
}

///|
fn pdf_evidence_watch_goal_enabled_in(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  for goal in goals {
    if goal.id == goal_id {
      return goal.enabled
    }
  }
  false
}

///|
fn disable_pdf_evidence_watch_book_standing_goals(
  goals : Array[@core.StandingGoal],
  book_id : String,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  for goal in goals {
    if pdf_evidence_watch_should_disable_goal_for_book(goal, book_id) {
      updated.push(
        @core.StandingGoal::new(
          id=goal.id,
          title=goal.title,
          prompt=goal.prompt,
          target_book_id=goal.target_book_id,
          cadence_ticks=goal.cadence_ticks,
          next_due_tick=goal.next_due_tick,
          last_run_tick=goal.last_run_tick,
          enabled=false,
          source_policy=goal.source_policy,
          quality_threshold=goal.quality_threshold,
        ),
      )
    } else {
      updated.push(goal)
    }
  }
  updated
}

///|
fn pdf_evidence_watch_should_disable_goal_for_book(
  goal : @core.StandingGoal,
  book_id : String,
) -> Bool {
  if goal.id == pdf_evidence_watch_goal_id(book_id) {
    return true
  }
  if goal.id == book_quality_repair_goal_id(book_id) {
    return true
  }
  match goal.target_book_id {
    Some(target) => target == book_id
    None => false
  }
}

///|
fn count_disabled_pdf_evidence_watch_book_standing_goals(
  before : Array[@core.StandingGoal],
  after : Array[@core.StandingGoal],
  book_id : String,
) -> Int {
  let mut count = 0
  for goal in before {
    if goal.enabled &&
      pdf_evidence_watch_should_disable_goal_for_book(goal, book_id) {
      for candidate in after {
        if candidate.id == goal.id && !candidate.enabled {
          count += 1
        }
      }
    }
  }
  count
}

///|
fn archive_pdf_evidence_watch_catalog_entry(
  catalog : Array[@moonbook.BookCatalogEntry],
  book_id : String,
  reason : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let updated : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id == book_id {
      updated.push(
        @moonbook.BookCatalogEntry::new(
          id=entry.id,
          name=entry.name,
          purpose="\{entry.purpose}\n\nArchived: \{reason}",
          workspace_root=entry.workspace_root,
          memory_scope=entry.memory_scope,
          tags=ensure_pdf_evidence_watch_archive_tags(entry.tags),
          skills=entry.skills,
        ),
      )
    } else {
      updated.push(entry)
    }
  }
  updated
}

///|
fn ensure_pdf_evidence_watch_archive_tags(
  tags : Array[String],
) -> Array[String] {
  let updated : Array[String] = []
  for tag in tags {
    if !updated.contains(tag) {
      updated.push(tag)
    }
  }
  for tag in ["archived", "hidden", "internal"] {
    if !updated.contains(tag) {
      updated.push(tag)
    }
  }
  updated
}

///|
fn pdf_evidence_watch_goal_id(book_id : String) -> String {
  "watch-\{book_id}-pdfs"
}

///|
fn pdf_evidence_watch_goal_prompt(
  title : String,
  purpose : String,
  websites : Array[String],
) -> String {
  [
    "Run the PDF Evidence Watch workflow for `\{title}`.",
    "",
    "Purpose: \{purpose}",
    "",
    "Configured websites:",
    if websites.is_empty() {
      "- none yet; ask Moondesk/user configuration for approved sites before fetching"
    } else {
      markdown_bullets(websites)
    },
    "",
    "Required loop:",
    "- search configured websites for new or changed PDFs before local reuse",
    "- download approved PDFs into `raw/pdfs/`",
    "- extract text, tables, figures, metadata, and provenance into `raw/extracted/`",
    "- analyze with `wiki/methods/analysis-method.md` and book-local skills",
    "- write durable source cards under `wiki/sources/`",
    "- promote only accepted new knowledge under `wiki/findings/`",
    "- update `wiki/history/standing-watch.md` with checked sources, accepted facts, rejected facts, and notification status",
    "- notify the operator only when accepted domain knowledge changes",
  ].join("\n")
}

///|
fn default_pdf_evidence_watch_purpose() -> String {
  "Standing MoonBook workspace for website-driven PDF discovery, download, extraction, method-specific analysis, durable findings, and operator notification when accepted new knowledge appears."
}

///|
fn pdf_evidence_watch_template_copy_paths() -> Array[String] {
  [
    "raw/bootstrap/PDF_WATCH_CONTRACT.md", "wiki/index.md", "wiki/methods/analysis-method.md",
    "wiki/sources/README.md", "wiki/findings/README.md", "wiki/reviews/pdf-watch-review.md",
    "skills/pdf-watch/SKILL.md", "skills/pdf-analysis/SKILL.md", "schemas/pdf-source.schema.md",
    "schemas/analysis-result.schema.md",
  ]
}

///|
fn pdf_evidence_watch_required_paths() -> Array[String] {
  [
    "book.json", "raw/bootstrap/PDF_WATCH_CONTRACT.md", "raw/pdfs/.keep", "raw/extracted/.keep",
    "raw/analysis-runs/.keep", "wiki/index.md", "wiki/methods/analysis-method.md",
    "wiki/sources/README.md", "wiki/findings/README.md", "wiki/reviews/pdf-watch-review.md",
    "wiki/history/standing-watch.md", "skills/pdf-watch/SKILL.md", "skills/pdf-analysis/SKILL.md",
    "schemas/pdf-source.schema.md", "schemas/analysis-result.schema.md", "book/Home.html",
    "book/site/generated/index.html",
  ]
}

///|
fn pdf_evidence_watch_history_markdown(
  entry : @moonbook.BookCatalogEntry,
  title : String,
) -> String {
  [
    "# PDF Evidence Watch History",
    "",
    "- Book: `\{entry.id}`",
    "- Title: \{title}",
    "- Current state: initialized",
    "",
    "Each watcher run must append a digest with checked websites, PDFs discovered, PDFs downloaded, accepted findings, rejected findings, wiki pages changed, and notification status.",
  ].join("\n")
}

///|
fn pdf_evidence_watch_generated_site_html(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
) -> String {
  let site_list = if websites.is_empty() {
    "<li>No websites configured yet.</li>"
  } else {
    websites.map(fn(site) { "<li>\{site}</li>" }).join("")
  }
  [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>\{title}</title>",
    "  <style>",
    "    body { margin: 0; font-family: ui-serif, Georgia, serif; background: #f7f4ec; color: #172018; }",
    "    main { max-width: 960px; margin: 0 auto; padding: 56px 24px; }",
    "    .card { background: #fffaf0; border: 1px solid #d7c8a4; border-radius: 24px; padding: 28px; box-shadow: 0 18px 60px rgba(30, 44, 20, .12); }",
    "    h1 { font-size: clamp(2.2rem, 5vw, 4rem); line-height: .95; margin: 0 0 18px; }",
    "    h2 { margin-top: 34px; }",
    "    code { background: #ece3ce; border-radius: 8px; padding: 2px 6px; }",
    "    li { margin: 8px 0; }",
    "  </style>",
    "</head>",
    "<body>",
    "  <main>",
    "    <section class=\"card\">",
    "      <p><code>\{entry.id}</code> · PDF Evidence Watch</p>",
    "      <h1>\{title}</h1>",
    "      <p>\{purpose}</p>",
    "      <h2>Watch Sites</h2>",
    "      <ul>\{site_list}</ul>",
    "      <h2>Workflow</h2>",
    "      <ol>",
    "        <li>Discover changed PDFs from configured websites.</li>",
    "        <li>Download PDFs and extract text/tables with provenance.</li>",
    "        <li>Analyze with the book-local method and skills.</li>",
    "        <li>Promote accepted findings into the wiki and notify only on new knowledge.</li>",
    "      </ol>",
    "    </section>",
    "  </main>",
    "</body>",
    "</html>",
  ].join("\n")
}
