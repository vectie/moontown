///|
fn research_question_seed_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "# Research Question",
    "",
    "## Core Question",
    "",
    research_question_text(topic, display),
    "",
    "## Scope",
    "",
    "This seed file frames a web-first research pass for \{display}. It is intentionally provisional; the worker should revise it when source screening finds better boundaries.",
    "",
    "## Inclusion Criteria",
    "",
    "- directly relevant to \{display}",
    "- attributable to a reputable publisher, official body, company, operator, or named expert",
    "- specific enough to support falsifiable claims",
    "- current enough for the research question, or clearly foundational if older",
    "",
    "## Exclusion Criteria",
    "",
    "- search snippets treated as verified evidence",
    "- generic or motivational content without inspectable claims",
    "- local repository interpretation unless screened sources prove that meaning",
    "- final claims written before source inspection",
    "",
    "## Query Seeds",
    "",
    ..research_web_queries(topic).map(fn(query) { "- `\{query}`" }),
    "",
    "## Local Source Position",
    "",
    if is_external_domain_research_topic(topic) {
      "`SOURCE_HINTS.md` says no local repository is implied for this lane. Keep local evidence empty unless screened web evidence points to a concrete local artifact."
    } else {
      "Inspect local files only after web discovery has been recorded."
    },
  ].join("\n")
}

///|
fn research_search_log_seed_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "# Search Log",
    "",
    "## Seed Status",
    "",
    "Moontown created this starter log before MoonClaw source screening so the research trail is durable. It contains planned queries only; source screening must revise it with actual attempts, selected URLs, rejected URLs, blockers, and decisions.",
    "",
    "## Planned Queries",
    "",
    "| Query ID | Query | Purpose | Status |",
    "| --- | --- | --- | --- |",
    ..research_query_seed_rows(topic, display),
    "",
    "## Source Screening Rules",
    "",
    "- Use native web tools when available; otherwise use bounded command-line discovery such as `curl -L --max-time 12`.",
    "- Retry `{bad request}` once with a simpler query or URL before recording a blocker.",
    "- Use search pages only for discovery; do not cite them as evidence.",
    "- Prefer inspected source content, clear provenance, and claim-level extraction.",
    "- Keep blocked or weak sources visible in `\{@research_policy.source_screen_path()}` or `\{@research_policy.tool_blockers_path()}`.",
  ].join("\n")
}

///|
fn research_query_seed_rows(topic : String, display : String) -> Array[String] {
  let rows : Array[String] = []
  let queries = research_web_queries(topic)
  for index, query in queries {
    rows.push(
      "| Q\{index + 1} | `\{query}` | source discovery for \{display} | planned |",
    )
  }
  rows
}

///|
fn research_source_hints_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let web_queries = research_web_queries(topic)
  let local_paths = research_local_paths(topic)
  let reference_urls = research_reference_urls(topic)
  let lines : Array[String] = [
    "# Source Hints",
    "",
    "These are Moontown-generated hints for the \{display} research lane.",
    "",
  ]
  if is_external_domain_research_topic(topic) {
    lines.push("## Interpretation Guard")
    lines.push("")
    lines.push(
      "- Treat \{display} as an external domain research topic, not as a Vectie repository, MoonBit package, or local codebase unless source evidence proves otherwise.",
    )
    lines.push(
      "- Let the LLM choose the best current sources, but require screened web evidence before synthesis.",
    )
    lines.push(
      "- Prefer recent, reputable, source-backed material over search snippets, generic explainers, or run-log prose.",
    )
    lines.push("")
  }
  lines.push("## Web Search First")
  lines.push("")
  for query in web_queries {
    lines.push("- \{query}")
  }
  lines.push("")
  lines.push("## Optional Reference Style Inputs")
  lines.push("")
  lines.push(
    "- `raw/bootstrap/REFERENCE_STYLE.md`: if present, explains how to use user-supplied reference material as a style and quality target.",
  )
  lines.push(
    "- `raw/bootstrap/REFERENCE_OUTPUT.md`: if present, match its length class, section discipline, evidence density, tables, visualization style, and language when appropriate.",
  )
  lines.push(
    "- `raw/bootstrap/REFERENCE_SOURCE_HINTS.md`: if present, use it as a candidate lead sheet only. Every lead still needs source screening before it can support claims.",
  )
  lines.push(
    "- Reference files are not evidence for \{display}; use them to improve report craft, not to import facts.",
  )
  lines.push(
    "- If the reference report names candidate routes, comparison axes, or visual dimensions that fit the user's objective, use them as search hypotheses and independently screen sources for each adopted route.",
  )
  if !reference_urls.is_empty() {
    lines.push("")
    lines.push("## High-Signal URLs")
    lines.push("")
    for url in reference_urls {
      lines.push("- \{url}")
    }
  }
  if !local_paths.is_empty() {
    lines.push("")
    lines.push("## Local Repository Follow-Up")
    lines.push("")
    for path in local_paths {
      lines.push("- \{path}")
    }
  } else if is_external_domain_research_topic(topic) {
    lines.push("")
    lines.push("## Local Follow-Up")
    lines.push("")
    lines.push(
      "- No local repository is implied for this lane. Record `\{@research_policy.local_sources_path()}` as intentionally empty unless web evidence points to a concrete local artifact.",
    )
  }
  lines.push("")
  lines.push("## Materialization Target")
  lines.push("")
  lines.push(
    "- Turn screened evidence into topic-specific source, entity, concept, and synthesis pages.",
  )
  lines.push(
    "- Generic statements like `LLM Wiki is a maintained workspace` are not acceptable final coverage for this lane.",
  )
  lines.push(
    "- Candidate source lists are not enough. MoonBook now treats durable coverage as verified only after source pages digest inspected material with provenance.",
  )
  lines.join("\n")
}
