///|
fn research_report_concrete_example_section(display : String) -> String {
  [
    "",
    "## Concrete Example",
    "",
    "```md",
    "# \{display}: Deep Research Analysis",
    "",
    "## Executive Summary",
    "",
    "<Answer the research question directly in one or two dense paragraphs. Cite strongest source IDs.>",
    "",
    "## Technical Route Comparison",
    "",
    "| Route | Advantage | Bottleneck | Maturity | Evidence |",
    "| --- | --- | --- | --- | --- |",
    "| Route A | Supported advantage | Specific unresolved issue | pilot / mature / speculative | W1, W3 |",
    "",
    "## Relationship Model",
    "",
    "```mermaid",
    "flowchart LR",
    "  Need[Manufacturing need] --> RouteA[Route A]",
    "  Need --> RouteB[Route B]",
    "  RouteA --> Constraint[Shared bottleneck]",
    "  RouteB --> Supplement[Supplementary use case]",
    "```",
    "",
    "## Evidence and Limits",
    "",
    "- Strongest sources: W1, W2, W3.",
    "- Weakest point: <missing source, uncertainty, or contradiction>.",
    "```",
  ].join("\n")
}

///|
fn research_report_final_revision_rule(topic : String) -> String {
  [
    "",
    "Before returning success, revise if the draft is short, generic, missing tables, missing diagram, not lane-specific to \{topic}, or reads like a run log.",
  ].join("\n")
}
