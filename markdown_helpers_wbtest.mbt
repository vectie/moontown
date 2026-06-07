///|
test "markdown inline escapes table separators and newlines" {
  assert_eq(markdown_inline("alpha|beta\ngamma"), "alpha\\|beta gamma")
}

///|
test "first non-heading paragraph skips markdown scaffolding and stops at blank" {
  let markdown = [
    "# Report Title", "", "| Column |", "| --- |", "## Section", "", "First useful sentence.",
    "Second useful sentence.", "", "Later paragraph should not be included.",
  ].join("\n")
  assert_eq(
    first_non_heading_paragraph(markdown),
    "First useful sentence. Second useful sentence.",
  )
}

///|
test "first non-heading paragraph skips fenced code contents" {
  let markdown = [
    "# Report Title", "", "```moonbit", "let code = \"not prose\"", "```", "", "Actual prose.",
  ].join("\n")
  assert_eq(first_non_heading_paragraph(markdown), "Actual prose.")
}

///|
test "markdown bullets renders one trimmed list" {
  assert_eq(markdown_bullets(["alpha", "beta"]), "- alpha\n- beta")
  assert_eq(markdown_bullets([]), "")
}

///|
test "markdown excerpt handles limit boundaries" {
  assert_eq(markdown_excerpt(" short text ", 20), "short text")
  assert_eq(markdown_excerpt("abcdef", 3), "abc\n\n...")
  assert_eq(markdown_excerpt("abcdef", 0), "...")
  assert_eq(markdown_excerpt("abcdef", -1), "...")
}
