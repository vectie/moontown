///|
pub fn with_pdf_watch(policy : BookPolicy) -> BookPolicy {
  policy
  |> with_skill(
    skill(
      "pdf-watch",
      execute_lane(),
      "standing-watch-cadence",
      "Discover, fetch, extract, and screen PDF sources before durable analysis.",
    ),
  )
  |> with_skill(
    skill(
      "pdf-analysis",
      execute_lane(),
      "on-accepted-pdf-change",
      "Extract tables, claims, and deltas from accepted PDF evidence packets.",
    ),
  )
  |> with_file(file("raw/pdf/", true, "downloaded or staged PDF evidence"))
  |> with_file(
    file("wiki/sources/pdf-index.md", true, "accepted PDF source index"),
  )
}

///|
pub fn with_web_tool_surface(
  policy : BookPolicy,
  contract? : String = "moontown.book.tool.v1",
  projection_path? : String = "book/site/generated/tool.html",
) -> BookPolicy {
  policy
  |> with_skill(
    skill(
      "tool-projection",
      execute_lane(),
      "on-accepted-data-change",
      "Build or refresh the book-owned usable web tool from accepted data and analysis.",
    ),
  )
  |> with_skill(
    skill(
      "tool-review",
      tend_lane(),
      "review-cadence",
      "Review whether the generated tool remains safe, useful, and faithful to the book.",
    ),
  )
  |> with_file(file("tool/manifest.json", true, "book-owned tool manifest"))
  |> with_file(file("tool/src/", true, "book-owned tool source"))
  |> with_output(output("web-tool", contract, projection_path))
}

///|
pub fn with_standing_watch(policy : BookPolicy) -> BookPolicy {
  policy
  |> with_skill(
    skill(
      "standing-watch",
      execute_lane(),
      "every-due-tick",
      "Check current sources against the book baseline and emit meaningful deltas only.",
    ),
  )
  |> with_file(file("wiki/history/standing-watch.md", true, "watch decisions"))
}
