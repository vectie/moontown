///|
// Indented literal text keeps source Markdown/HTML from becoming report markup.
fn comparison_literal(text : String) -> String {
  text
  .replace(old="\r\n", new="\n")
  .replace(old="\r", new="\n")
  .split("\n")
  .map(line => "    " + line.to_owned())
  .collect()
  .join("\n") +
  "\n"
}

///|
fn[T] comparison_section(
  title : String,
  rows : Array[OutcomeChange[T]],
  render : (T) -> String,
) -> String {
  let changed = rows.filter(row => row.change != "unchanged")
  let sections = [
    "## " + title,
    changed.length().to_string() +
    " changed entries; " +
    (rows.length() - changed.length()).to_string() +
    " unchanged.",
  ]
  for row in changed {
    sections.push(
      "### " +
      row.change +
      "\n\nIdentity:\n\n" +
      comparison_literal(row.identity),
    )
    for (label, value) in [("Before", row.before), ("After", row.after)] {
      let rendered = match value {
        None => "Absent from this selected outcome.\n"
        Some(value) => comparison_literal(render(value))
      }
      sections.push(label + ":\n\n" + rendered)
    }
  }
  sections.join("\n\n")
}

///|
fn comparison_source(source : SourceSnapshot) -> String {
  "Book: " +
  source.book_id +
  " (" +
  source.book_title +
  ")\nSource: " +
  source.source_path +
  "\nCaptured artifact: " +
  source.artifact_ref +
  "\nDigest: " +
  source.digest +
  "\nBytes: " +
  source.size_bytes.to_string()
}

///|
fn comparison_assignment(p : Participant) -> String {
  "Book: " +
  p.book_id +
  "\nSources: " +
  p.source_paths.join(", ") +
  "\nFocus: " +
  p.focus_area +
  "\nPerspective: " +
  p.perspective +
  "\nRequested contribution: " +
  p.contribution +
  "\nNext artifact: " +
  p.next_artifact
}

///|
fn comparison_contribution(p : ParticipantWork) -> String {
  "Book: " +
  p.book_id +
  "\nStatus: " +
  p.status +
  "\nPacket: " +
  p.packet_id +
  "\nProposal: " +
  p.proposal_id +
  "\nRun: " +
  p.run_id +
  "\nOutput: " +
  p.output_ref +
  "\nDigest: " +
  p.output_digest +
  "\nDetail: " +
  p.detail +
  "\nContribution:\n" +
  p.output_text
}

///|
fn comparison_decision(d : WorkDecision) -> String {
  "Reviewer: " +
  d.reviewer_name +
  " (" +
  d.reviewer_id +
  ")\nPrompt: " +
  d.prompt +
  "\nDecision: " +
  d.decision +
  "\nRationale: " +
  d.rationale
}

///|
fn comparison_text(value : String) -> String {
  value
}

///|
fn comparison_context(
  rows : Array[OutcomeChange[String]],
  before : Bool,
) -> String {
  rows
  .filter(row => {
    [
      "title", "question", "reviewer_id", "reviewer_name", "outcome_status", "review_status",
    ].contains(row.identity)
  })
  .map(row => {
    row.identity +
    ": " +
    (if before { row.before } else { row.after }).unwrap_or("")
  })
  .join("\n")
}

///|
/// A changed-entry brief with exact selection keys. Unchanged payloads are kept
/// in the JSON export. Literal content is indented; no source text is executed.
pub fn OutcomeComparison::markdown(self : OutcomeComparison) -> String raise {
  let parts = [
    "# Retained collaboration change brief",
    "Read-only comparison of two explicitly selected historical outcomes. Before and after are caller-selected labels, not a chronological claim. Changes are exact recorded differences, not inferred contradictions, consensus, or accepted Book knowledge. Unavailable outcomes cannot be compared.",
    "## Selected evidence",
    "Before context:\n\n" +
    comparison_literal(
      "Recorded: " +
      self.before_recorded_at +
      "\n" +
      comparison_context(self.fields, true),
    ),
    "Before key:\n\n" +
    comparison_literal(self.before.to_json().stringify(indent=2)),
    "Before dossier digest:\n\n" +
    comparison_literal(self.before_archive_digest),
    "After context:\n\n" +
    comparison_literal(
      "Recorded: " +
      self.after_recorded_at +
      "\n" +
      comparison_context(self.fields, false),
    ),
    "After key:\n\n" +
    comparison_literal(self.after.to_json().stringify(indent=2)),
    "After dossier digest:\n\n" + comparison_literal(self.after_archive_digest),
    comparison_section(
      "Question and review context",
      self.fields,
      comparison_text,
    ),
    comparison_section(
      "Participant assignments",
      self.assignments,
      comparison_assignment,
    ),
    comparison_section("Captured sources", self.sources, comparison_source),
    comparison_section(
      "Attributed contributions and failures",
      self.contributions,
      comparison_contribution,
    ),
    comparison_section(
      "Selected review decisions",
      self.decisions,
      comparison_decision,
    ),
    "Unchanged entries are omitted from this brief; their full before/after provenance is retained in the JSON comparison. Different run IDs or captured artifact paths alone do not count as evidence changes. A changed source does not automatically invalidate or approve any review. Inspect the owning Book before making a knowledge change.",
  ]
  let text = parts.join("\n\n") + "\n"
  guard text.length() <= 4194304 else {
    fail("Comparison brief exceeds 4 Mi UTF-16 code units")
  }
  text
}
