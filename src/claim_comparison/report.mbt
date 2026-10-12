///|
fn digest(bytes : Bytes) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn compare(claims : Array[Claim]) -> Array[Group] {
  let groups : Array[Array[Claim]] = []
  for claim in claims {
    let mut found = false
    for group in groups {
      if group[0].topic == claim.topic && group[0].context == claim.context {
        group.push(claim)
        found = true
        break
      }
    }
    if !found {
      groups.push([claim])
    }
  }
  groups.map(claims => {
    let books : Array[String] = []
    let values : Array[String] = []
    for claim in claims {
      if !books.contains(claim.book_id) {
        books.push(claim.book_id)
      }
      if !values.contains(claim.value) {
        values.push(claim.value)
      }
    }
    {
      topic: claims[0].topic,
      context: claims[0].context,
      state: if books.length() < 2 {
        "single_book"
      } else if values.length() == 1 {
        "same_value"
      } else {
        "different_values"
      },
      books,
      claims,
    }
  })
}

///|
/// Compare operator-labelled values only within identical topic/context cells.
/// Every quote must occur literally in the supplied exact UTF-8 source bytes.
/// Inputs are explicit snapshots; this function neither fetches sources nor updates Books.
pub fn report(
  table_bytes : Bytes,
  delimiter : Char,
  sources : Map[String, Bytes],
  format~ : String,
) -> Result[String, String] {
  try {
    guard format == "json" || format == "markdown" else {
      fail("Choose json or markdown")
    }
    let claims = parse(table_bytes, delimiter)
    let selected = paths(claims)
    guard sources.length() == selected.length() else {
      fail("Supply exactly the selected source files")
    }
    let text : Map[String, String] = {}
    let evidence : Array[Source] = []
    let mut total = 0
    for path in selected {
      guard sources.get(path) is Some(bytes) else {
        fail("Missing source: " + path)
      }
      total += bytes.length()
      guard total <= 8 * 1048576 else { fail("Sources exceed 8 MiB in total") }
      text[path] = decode(bytes, 262144, "Source " + path)
      evidence.push({ path, digest: digest(bytes), size_bytes: bytes.length(), })
    }
    for claim in claims {
      guard text[claim.source_path].contains(claim.quote) else {
        fail("Quote not found for claim_id: " + claim.claim_id)
      }
    }
    let value : Comparison = {
      contract: "moontown.claim-comparison.v1",
      state: "pending_review",
      policy: "Operator-labelled topic, context, value and book identity. Groups match topic and context exactly; values compare as exact text. different_values is a candidate difference, not an inferred contradiction. same_value is textual agreement, not verified truth. Different contexts remain separate; single_book lacks a cross-book comparison. Quotes are checked against captured UTF-8 bytes and sources are hashed; no source ownership, semantic entailment, freshness or Book acceptance is asserted. No source or Book is changed.",
      table_digest: digest(table_bytes),
      table_size_bytes: table_bytes.length(),
      sources: evidence,
      groups: compare(claims),
    }
    let output = if format == "json" {
      value.to_json().stringify() + "\n"
    } else {
      markdown(value)
    }
    guard @utf8.encode(output).length() <= 2 * 1048576 else {
      fail("Comparison exceeds 2 MiB; narrow the inputs")
    }
    output
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}
