///|
pub fn pdf_evidence_watch_catalog_entry(
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
    memory_scope=BookPrivate,
    tags=[
      "research", "standing-watch", "pdf-evidence", "source-first", "template:pdf-evidence-watch",
    ],
    skills=[
      "pdf-watch", "pdf-analysis", "source-screening", "evidence-review", "notification-digest",
    ],
  )
}

///|
pub fn pdf_evidence_watch_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
pub fn pdf_evidence_watch_generated_site_workspace_path(
  root : String,
) -> String {
  "\{root}/\{pdf_evidence_watch_generated_site_path()}"
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
    book_type: @policy.research_type(),
    title,
    purpose,
    workspace_root: entry.workspace_root,
    tags: entry.tags,
    skills: entry.skills,
    watch: {
      websites,
      cadence_ticks,
      source_policy: @policy.web_first_policy(),
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
      ocr_engine: "unlimited-ocr",
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
pub fn pdf_evidence_watch_config_json(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
  cadence_ticks : Int,
) -> String {
  pdf_evidence_watch_config(entry, title, purpose, websites, cadence_ticks)
  .to_json()
  .stringify(indent=2)
}

///|
pub fn pdf_evidence_watch_template_copy_paths() -> Array[String] {
  [
    "raw/bootstrap/PDF_WATCH_CONTRACT.md", "wiki/index.md", "wiki/methods/analysis-method.md",
    "wiki/sources/README.md", "wiki/findings/README.md", "wiki/reviews/pdf-watch-review.md",
    "skills/pdf-watch/SKILL.md", "skills/pdf-analysis/SKILL.md", "schemas/pdf-source.schema.md",
    "schemas/analysis-result.schema.md",
  ]
}

///|
pub fn pdf_evidence_watch_required_paths() -> Array[String] {
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
pub fn pdf_evidence_watch_history_markdown(
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
