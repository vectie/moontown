///|
priv struct ResearchBootstrapArtifacts {
  brief : String
  report : String
  source_screen : String
  evidence : String
}

///|
async fn read_research_bootstrap_artifacts(
  entry : @moonbook.BookCatalogEntry,
) -> ResearchBootstrapArtifacts {
  let root = @moonbook.workspace_root(entry)
  {
    brief: @support.read_text_or_empty(
      "\{root}/raw/bootstrap/synthesis-brief.md",
    ),
    report: @support.read_text_or_empty("\{root}/raw/bootstrap/deep-report.md"),
    source_screen: @support.read_text_or_empty(
      "\{root}/raw/bootstrap/source-screen.md",
    ),
    evidence: @support.read_text_or_empty(
      "\{root}/raw/bootstrap/evidence-matrix.md",
    ),
  }
}

///|
fn ResearchBootstrapArtifacts::summary_excerpt(
  self : ResearchBootstrapArtifacts,
) -> String {
  first_non_empty_compact_excerpt(
    [self.brief, self.report, self.source_screen, self.evidence],
    900,
  )
}

///|
fn ResearchBootstrapArtifacts::source_detail(
  self : ResearchBootstrapArtifacts,
) -> String {
  first_non_empty_compact_excerpt(
    [self.source_screen, self.evidence, self.brief],
    700,
  )
}

///|
fn ResearchBootstrapArtifacts::entity_detail(
  self : ResearchBootstrapArtifacts,
) -> String {
  first_non_empty_compact_excerpt([self.brief, self.report], 700)
}

///|
fn ResearchBootstrapArtifacts::concept_detail(
  self : ResearchBootstrapArtifacts,
) -> String {
  first_non_empty_compact_excerpt([self.evidence, self.brief, self.report], 700)
}

///|
fn ResearchBootstrapArtifacts::synthesis_detail(
  self : ResearchBootstrapArtifacts,
) -> String {
  first_non_empty_compact_excerpt([self.brief, self.evidence, self.report], 700)
}
