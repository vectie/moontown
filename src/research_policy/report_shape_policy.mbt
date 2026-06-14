///|
pub fn report_article_shape_section() -> String {
  [
    "", "## Article Shape", "", "Use this shape unless the evidence clearly calls for a better structure:",
    "", "1. Executive Summary", "2. Research Question and Scope", "3. Ecosystem Context",
    "4. Core Thesis", "5. Technical Routes or Architecture", "6. Evidence and Key Claims",
    "7. Comparison and Tradeoffs", "8. Maturity, Bottlenecks, and Adoption Signals",
    "9. Roadmap and Watch Points", "10. Evidence and Limits", "", "For technology-route research, compare alternatives by performance, manufacturability, cost, maturity, supply chain, scalability, and unresolved physics or engineering bottlenecks when the evidence supports those dimensions.",
    "For long-form reference-matched technology research, create section depth from reasoning over screened claims: explain mechanisms, dependencies, adoption constraints, what would change the conclusion, and why each route is or is not a supplement. Do not fill length with repeated definitions.",
  ].join("\n")
}

///|
pub fn report_quality_rubric_section() -> String {
  [
    "", "## Quality Rubric", "", "| Dimension | Strong output | Weak output |", "| --- | --- | --- |",
    "| Thesis | Opens with a clear interpretation and why it matters now | Opens with workspace/process notes |",
    "| Evidence | Converts source rows into claim-backed paragraphs | Lists sources without synthesis |",
    "| Comparison | Explains tradeoffs across alternatives | Ranks things without criteria |",
    "| Specificity | Names concrete actors, technologies, dates, metrics, and bottlenecks when sourced | Uses generic claims that could fit any topic |",
    "| Judgement | Separates near-term reality, plausible supplement, and speculative route | Treats every idea as equally viable |",
  ].join("\n")
}
