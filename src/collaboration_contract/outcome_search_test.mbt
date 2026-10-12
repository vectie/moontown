///|
fn search_query(text : String) -> @collaboration_contract.OutcomeSearchQuery {
  {
    text,
    case_sensitive: false,
    book_id: "",
    review_status: "",
    selections: [],
  }
}

///|
test "search retrieves attributed contributions source identities and exact historical keys" {
  let outcome = comparison_fixture()
  let hit = @collaboration_contract.search_outcome(
    outcome,
    search_query("finding"),
  ).unwrap()
  assert_eq(hit.key, outcome.key)
  assert_eq(hit.archive_digest, outcome.archive_digest)
  assert_eq(hit.matches.map(m => m.book_id), ["water", "mobility"])
  assert_eq(hit.matches.map(m => m.field), ["contribution", "contribution"])
  assert_eq(hit.matches[0].digest, "sha256:output-water")
  let paths = @collaboration_contract.search_outcome(
    outcome,
    search_query("raw/claim.md"),
  ).unwrap()
  assert_eq(paths.matches.map(m => m.book_id), ["water", "mobility"])
  assert_eq(paths.matches[0].identity, "raw/claim.md")
  assert_eq(paths.matches[0].digest, "sha256:water")
  assert_eq(
    @collaboration_contract.search_outcome(
      outcome,
      search_query("no such phrase"),
    ),
    None,
  )
  assert_eq(
    @collaboration_contract.search_outcome(outcome, {
      ..search_query("finding"),
      case_sensitive: true,
    }),
    None,
  )
}

///|
test "Book filtering never misattributes a shared question or another Book contribution" {
  let outcome = comparison_fixture()
  let query = { ..search_query("finding"), book_id: "mobility", }
  let hit = @collaboration_contract.search_outcome(outcome, query).unwrap()
  assert_eq(hit.matches.length(), 1)
  assert_eq(hit.matches[0].book_id, "mobility")
  assert_eq(
    @collaboration_contract.search_outcome(outcome, {
      ..query,
      text: "What changed?",
    }),
    None,
  )
  assert_eq(
    @collaboration_contract.search_outcome(outcome, { ..query, text: "water", }),
    None,
  )
  assert_eq(
    @collaboration_contract.search_outcome(outcome, {
      ..query,
      review_status: "accepted",
    }),
    None,
  )
  assert_eq(
    @collaboration_contract.search_outcome(outcome, {
      ..query,
      selections: [{ ..outcome.key, review_version: 1, }],
    }),
    None,
  )
}

///|
test "search preserves failure diagnostics and selected decision rationale without inventing output" {
  let base = comparison_fixture()
  let outcome = {
    ..base,
    review_status: "deferred",
    work: {
      ..base.work,
      status: "partial",
      participants: [
        {
          ..base.work.participants[0],
          status: "failed",
          detail: "Contradictory dates",
          output_text: "",
          output_digest: "",
        },
      ],
      decisions: [
        {
          ..base.work.decisions[0],
          decision: "defer",
          rationale: "Contradictory dates need review",
        },
      ],
    },
  }
  let hit = @collaboration_contract.search_outcome(
    outcome,
    search_query("contradictory"),
  ).unwrap()
  assert_eq(hit.outcome_status, "partial")
  assert_eq(hit.review_status, "deferred")
  assert_eq(hit.matches.map(m => m.field), [
    "participant.detail", "decision.rationale",
  ])
  assert_eq(hit.matches[0].digest, "")
  assert_eq(hit.matches[1].identity, "review-result")
}

///|
test "search Unicode excerpts retain original offsets and first occurrence with safe boundaries" {
  let base = comparison_fixture()
  let text = "a".repeat(65) +
    "🚲" +
    "x".repeat(63) +
    "NEEDLE" +
    "x".repeat(63) +
    "🚲" +
    " tail NEEDLE"
  let outcome = {
    ..base,
    work: {
      ..base.work,
      participants: [{ ..base.work.participants[0], output_text: text, }],
    },
  }
  let hit = @collaboration_contract.search_outcome(
    outcome,
    search_query("needle"),
  ).unwrap()
  assert_eq(hit.matches.length(), 1)
  let found = hit.matches[0]
  assert_eq(found.match_offset, 130)
  assert_eq(found.excerpt_offset, 65)
  assert_eq(found.field_length, text.length())
  assert_true(found.excerpt.has_prefix("🚲"))
  assert_true(found.excerpt.has_suffix("🚲"))
  assert_eq(found.excerpt.length(), 136)
  let unicode = {
    ..outcome,
    work: {
      ..outcome.work,
      participants: [
        { ..base.work.participants[0], output_text: "水 Café İ 🚲", },
      ],
    },
  }
  assert_true(
    @collaboration_contract.search_outcome(
      unicode,
      search_query("水 café İ 🚲"),
    )
    is Some(_),
  )
  assert_eq(
    @collaboration_contract.search_outcome(
      unicode,
      search_query("水 CAFÉ İ 🚲"),
    ),
    None,
  )
}

///|
test "search Markdown keeps arbitrary stored text literal and JSON roundtrips exact bytes" {
  let base = comparison_fixture()
  let text = "水\r<script>alert(1)</script>\r\n# fake\n```\n[link](evil)"
  let outcome = {
    ..base,
    saved: { ..base.saved, draft: { ..base.saved.draft, title: text, }, },
  }
  let query = search_query("水")
  let hit = @collaboration_contract.search_outcome(outcome, query).unwrap()
  let result = {
    ..@collaboration_contract.empty_outcome_search(query),
    candidate_count: 1,
    searched_count: 1,
    hits: [hit],
  }
  let decoded : @collaboration_contract.OutcomeSearch = @json.from_json(
    @json.parse(result.json_text()),
  )
  assert_eq(decoded, result)
  let md = result.markdown()
  assert_true(md.contains("    <script>alert(1)</script>\n    # fake\n    ```"))
  assert_false(md.contains("\n# fake"))
  assert_false(md.contains("\r"))
  assert_eq(result.hits[0].title, text)
}

///|
test "search rejects invalid queries duplicate pins and mismatched outcome identities" {
  for text in ["", " \n\t", "x".repeat(129)] {
    assert_true((try? search_query(text).validate()) is Err(_))
  }
  let query = search_query("x")
  assert_true((try? { ..query, book_id: "../book", }.validate()) is Err(_))
  assert_true(
    (try? { ..query, review_status: "approved", }.validate()) is Err(_),
  )
  assert_true(
    (try? { ..query, selections: [outcome_key(), outcome_key()], }.validate())
    is Err(_),
  )
  let base = comparison_fixture()
  assert_true(
    (try? @collaboration_contract.search_outcome(
      { ..base, key: { ..base.key, revision: "wrong", }, },
      query,
    ))
    is Err(_),
  )
}

///|
test "search output and per-outcome field bounds fail explicitly rather than truncating" {
  let base = comparison_fixture()
  let sources = Array::makei(257, i => {
    ..base.saved.sources[0],
    source_path: "raw/match-" + i.to_string(),
  })
  assert_true(
    (try? @collaboration_contract.search_outcome(
      { ..base, saved: { ..base.saved, sources, }, },
      search_query("raw/match"),
    ))
    is Err(_),
  )
  let result = {
    ..@collaboration_contract.empty_outcome_search(search_query("x")),
    gaps: [
      {
        draft_id: "draft",
        revision: "r1",
        review_version: 0,
        status: "unavailable",
        detail: "x".repeat(4194304),
      },
    ],
  }
  assert_true((try? result.json_text()) is Err(_))
  assert_true((try? result.markdown()) is Err(_))
}
