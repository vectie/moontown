///|
fn knowledge_book_research_method(
  domain : @domain_catalog.KnowledgeDomain,
  book : @domain_catalog.KnowledgeDomainBook,
  policy : @domain_catalog.KnowledgeDomainPolicy,
) -> String {
  let reviewers = if policy.review_chain.is_empty() {
    "- no review chain configured; keep every result pending"
  } else {
    policy.review_chain.map(fn(reviewer) { "- \{reviewer}" }).join("\n")
  }
  [
    "# \{book.title} Research Method",
    "",
    "This file configures a declared MoonBook. It is not evidence that research has run or that any conclusion was accepted.",
    "",
    "## Domain",
    "",
    "- Domain: \{domain.title}",
    "- Research question: \{book.question}",
    "- Source policy: `\{book.source_policy}`",
    "- Evidence policy: `\{policy.evidence_policy}`",
    "- Quality threshold: `\{policy.quality_threshold}`",
    "- Completion claim ceiling: `\{policy.completion_claim}`",
    "",
    "## Required review chain",
    "",
    reviewers,
    "",
    "## Operating rule",
    "",
    "Gather attributable evidence, separate observations from inference, preserve contradictory evidence, and leave results pending until the configured review chain accepts them.",
  ].join("\n")
}

///|
fn knowledge_book_tool_spec(
  domain : @domain_catalog.KnowledgeDomain,
  book : @domain_catalog.KnowledgeDomainBook,
  policy : @domain_catalog.KnowledgeDomainPolicy,
) -> String {
  [
    "# \{book.title} Tool Specification",
    "",
    "Status: declared. Generation of a tool workspace does not mean that its analysis or recommendations are accepted.",
    "",
    "- Civic building: `\{domain.building_id}`",
    "- Domain: \{domain.title}",
    "- User question: \{book.question}",
    "- Evidence policy: `\{policy.evidence_policy}`",
    "- Review policy: `\{policy.id}@\{policy.version}`",
    "",
    "The generated application must expose evidence provenance, current review state, stale or missing inputs, and a clear boundary between generated output and accepted MoonBook knowledge.",
  ].join("\n")
}

///|
fn knowledge_book_config_json(
  domain : @domain_catalog.KnowledgeDomain,
  book : @domain_catalog.KnowledgeDomainBook,
  policy : @domain_catalog.KnowledgeDomainPolicy,
) -> Json? {
  let research_method = knowledge_book_research_method(domain, book, policy)
  match knowledge_book_installer_template_id(book) {
    Some("pdf-evidence-watch") => {
      let spec = @pdf_evidence_watch.PdfEvidenceWatchInstallSpec::{
        book_id: book.book_id,
        title: book.title,
        purpose: book.question,
        websites: [],
        analysis_method: research_method,
        analysis_method_path: "",
        cadence_ticks: book.cadence_ticks,
        workspace_root: "",
      }
      Some(spec.to_json())
    }
    Some("app-tool-book") => {
      let spec = @app_tool_book.AppToolBookInstallSpec::{
        book_id: book.book_id,
        title: book.title,
        purpose: book.question,
        websites: [],
        analysis_method: research_method,
        analysis_method_path: "",
        tool_spec: knowledge_book_tool_spec(domain, book, policy),
        tool_spec_path: "",
        civic_building_id: domain.building_id,
        cadence_ticks: book.cadence_ticks,
        workspace_root: "",
      }
      Some(spec.to_json())
    }
    _ => None
  }
}

///|
fn knowledge_book_installer_template_id(
  book : @domain_catalog.KnowledgeDomainBook,
) -> String? {
  match book.template_id {
    "domain-research-book"
    | "learning-book"
    | "private-resident-book"
    | "project-review-book" => Some("pdf-evidence-watch")
    "civic-ledger-book"
    | "market-intelligence-book"
    | "physical-handoff-book"
    | "service-operations-book"
    | "story-publication-book" => Some("app-tool-book")
    _ => None
  }
}

///|
fn knowledge_book_template_supported(
  book : @domain_catalog.KnowledgeDomainBook,
) -> Bool {
  knowledge_book_installer_template_id(book) is Some(_)
}

///|
fn knowledge_book_seed_enabled(
  book : @domain_catalog.KnowledgeDomainBook,
) -> Bool {
  book.status == "active"
}
