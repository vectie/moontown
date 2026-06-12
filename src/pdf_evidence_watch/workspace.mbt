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
  write_text_file(pdf_evidence_watch_generated_site_workspace_path(root), html)
}

///|
fn pdf_evidence_watch_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
fn pdf_evidence_watch_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{pdf_evidence_watch_generated_site_path()}"
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
        "wiki/sources/*.md",
        "wiki/findings/*.md",
        "wiki/history/standing-watch.md",
        pdf_evidence_watch_generated_site_path(),
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
        "raw/pdfs/",
        "raw/extracted/",
        "wiki/sources/",
        "wiki/findings/",
        pdf_evidence_watch_generated_site_path(),
      ],
    },
  }
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
    "book.json",
    "raw/bootstrap/PDF_WATCH_CONTRACT.md",
    "raw/pdfs/.keep",
    "raw/extracted/.keep",
    "raw/analysis-runs/.keep",
    "wiki/index.md",
    "wiki/methods/analysis-method.md",
    "wiki/sources/README.md",
    "wiki/findings/README.md",
    "wiki/reviews/pdf-watch-review.md",
    "wiki/history/standing-watch.md",
    "skills/pdf-watch/SKILL.md",
    "skills/pdf-analysis/SKILL.md",
    "schemas/pdf-source.schema.md",
    "schemas/analysis-result.schema.md",
    "book/Home.html",
    pdf_evidence_watch_generated_site_path(),
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
