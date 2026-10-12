///|
fn safe(value : String) -> String {
  let builder = StringBuilder::new()
  // JSON spelling makes line breaks and controls visible; Markdown punctuation
  // is escaped so untrusted source text cannot create links, headings or HTML.
  for c in value.to_json().stringify() {
    if c
      is ('\\'
      | '`'
      | '*'
      | '_'
      | '{'
      | '}'
      | '['
      | ']'
      | '<'
      | '>'
      | '('
      | ')'
      | '#'
      | '+'
      | '-'
      | '.'
      | '!'
      | '|'
      | '&') {
      builder.write_char('\\')
    }
    builder.write_char(c)
  }
  builder.to_string()
}

///|
fn markdown(value : Comparison) -> String {
  let out = StringBuilder::new()
  out.write_string("# Cross-book claim comparison\n\nState: pending_review\n\n")
  out.write_string(value.policy + "\n\n")
  out.write_string(
    "Claim table: " +
    value.table_digest +
    " (" +
    value.table_size_bytes.to_string() +
    " bytes)\n\n",
  )
  for i, group in value.groups {
    out.write_string(
      "## Group " + (i + 1).to_string() + ": " + group.state + "\n\n",
    )
    out.write_string(
      "- Topic: " +
      safe(group.topic) +
      "\n- Context: " +
      safe(group.context) +
      "\n\n",
    )
    for claim in group.claims {
      out.write_string("### Claim " + safe(claim.claim_id) + "\n\n")
      out.write_string(
        "- Book label: " +
        safe(claim.book_id) +
        "\n- Value: " +
        safe(claim.value) +
        "\n- Source: " +
        safe(claim.source_path) +
        "\n- Exact quote: " +
        safe(claim.quote) +
        "\n\n",
      )
    }
  }
  out.write_string("## Captured source identities\n\n")
  for source in value.sources {
    out.write_string(
      "- " +
      safe(source.path) +
      ": " +
      source.digest +
      " (" +
      source.size_bytes.to_string() +
      " bytes)\n",
    )
  }
  out.to_string()
}
