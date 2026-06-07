///|
test "book quality review root helpers trim only known suffixes" {
  assert_eq(
    book_quality_review_root("/tmp/town/book-quality/ai-review-packets"),
    "/tmp/town/book-quality",
  )
  assert_eq(
    book_quality_review_root_from_run_path(
      "/tmp/town/book-quality/ai-review-runs.json",
    ),
    "/tmp/town/book-quality",
  )
  assert_eq(
    book_quality_root_from_suffixed_path(
      "/tmp/town/book-quality/unknown.json",
      book_quality_review_run_ledger_suffix(),
    ),
    default_book_quality_review_root(),
  )
  assert_eq(
    book_quality_external_packet_path(
      "/tmp/town/book-quality/ai-review-packets", "research-opc",
    ),
    "/tmp/town/book-quality/moonclaw-packets/book-quality-ai-review-research-opc.json",
  )
  assert_eq(default_book_quality_moonclaw_home(), ".moonclaw")
  assert_eq(
    book_quality_moonclaw_home("/tmp/town/book-quality/ai-review-packets"),
    default_book_quality_moonclaw_home(),
  )
  assert_eq(
    book_quality_moonclaw_home_from_run_path(
      "/tmp/town/book-quality/ai-review-runs.json",
    ),
    default_book_quality_moonclaw_home(),
  )
}

///|
async test "book quality review ledger append replaces matching book and run slot" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-append-ledger-wbtest",
  )
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let original = book_quality_review_run_fixture(
    "book-a",
    "\{root}/packet-old.json",
    "\{root}/result-old.md",
    Some("proposal-old"),
    Some("run-a"),
    book_quality_review_run_dispatched_status(),
    "old",
    1UL,
  )
  let replacement = book_quality_review_run_update(
    original,
    packet_path=Some("\{root}/packet-new.json"),
    result_path=Some("\{root}/result-new.md"),
    summary=Some("new"),
    generated_at_ms=Some(2UL),
  )
  let other = book_quality_review_run_update(
    original,
    book_id=Some("book-b"),
    packet_path=Some("\{root}/packet-other.json"),
    result_path=Some("\{root}/result-other.md"),
    run_id=Some("run-b"),
    summary=Some("other"),
  )
  assert_true(book_quality_review_run_same_ledger_slot(original, replacement))
  assert_false(book_quality_review_run_same_ledger_slot(original, other))
  append_book_quality_review_run(run_path, original)
  append_book_quality_review_run(run_path, other)
  append_book_quality_review_run(run_path, replacement)
  let ledger = load_book_quality_review_run_ledger(run_path)
  assert_eq(ledger.runs.length(), 2)
  assert_eq(ledger.runs[0].book_id, "book-b")
  assert_eq(ledger.runs[1].book_id, "book-a")
  assert_eq(ledger.runs[1].summary, "new")
}

///|
test "book quality review ledger merge replaces matching slot without io" {
  let original = book_quality_review_run_fixture(
    "book-a",
    "/tmp/packet-old.json",
    "/tmp/result-old.md",
    Some("proposal-old"),
    Some("run-a"),
    book_quality_review_run_dispatched_status(),
    "old",
    1UL,
  )
  let replacement = book_quality_review_run_update(
    original,
    packet_path=Some("/tmp/packet-new.json"),
    result_path=Some("/tmp/result-new.md"),
    summary=Some("new"),
    generated_at_ms=Some(2UL),
  )
  let other = book_quality_review_run_update(
    original,
    book_id=Some("book-b"),
    packet_path=Some("/tmp/packet-other.json"),
    result_path=Some("/tmp/result-other.md"),
    run_id=Some("run-b"),
    summary=Some("other"),
  )
  let merged = book_quality_review_run_ledger_with_appended_run(
    BookQualityReviewRunLedger::{ runs: [original, other] },
    replacement,
  )
  assert_eq(merged.runs.length(), 2)
  assert_eq(merged.runs[0].book_id, "book-b")
  assert_eq(merged.runs[0].summary, "other")
  assert_eq(merged.runs[1].book_id, "book-a")
  assert_eq(merged.runs[1].summary, "new")
}

///|
test "book quality review ledger parser handles valid and invalid text" {
  let run = book_quality_review_run_fixture(
    "book-a",
    "/tmp/packet.json",
    "/tmp/result.md",
    Some("proposal-a"),
    Some("run-a"),
    book_quality_review_run_dispatched_status(),
    "summary",
    1UL,
  )
  let text = BookQualityReviewRunLedger::{ runs: [run] }
    .to_json()
    .stringify(indent=2)
  let parsed = book_quality_review_run_ledger_from_text(text)
  assert_eq(parsed.runs.length(), 1)
  assert_eq(parsed.runs[0].book_id, "book-a")
  assert_eq(parsed.runs[0].summary, "summary")

  let malformed = book_quality_review_run_ledger_from_text("{not valid json")
  assert_eq(malformed.runs.length(), 0)
  let wrong_schema = book_quality_review_run_ledger_from_text(
    "{\"runs\":\"not an array\"}",
  )
  assert_eq(wrong_schema.runs.length(), 0)
}

///|
test "book quality review ledger serializer roundtrips through parser" {
  let run = book_quality_review_run_fixture(
    "book-roundtrip",
    "/tmp/packet.json",
    "/tmp/result.md",
    Some("proposal-roundtrip"),
    Some("run-roundtrip"),
    book_quality_review_run_written_status(),
    "roundtrip summary",
    7UL,
  )
  let text = book_quality_review_run_ledger_to_text(BookQualityReviewRunLedger::{
    runs: [run],
  })
  assert_true(text.contains("\"runs\""))
  assert_true(text.contains("\"book_id\": \"book-roundtrip\""))
  let parsed = book_quality_review_run_ledger_from_text(text)
  assert_eq(parsed.runs.length(), 1)
  assert_eq(parsed.runs[0].book_id, "book-roundtrip")
  assert_eq(parsed.runs[0].summary, "roundtrip summary")
}

///|
async test "book quality review ledger loader falls back to empty ledger" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-load-ledger-wbtest",
  )
  let missing_path = "\{root}/book-quality/missing-runs.json"
  let missing = load_book_quality_review_run_ledger(missing_path)
  assert_eq(missing.runs.length(), 0)

  let malformed_path = "\{root}/book-quality/malformed-runs.json"
  write_text_file(malformed_path, "{not valid json")
  let malformed = load_book_quality_review_run_ledger(malformed_path)
  assert_eq(malformed.runs.length(), 0)

  let wrong_schema_path = "\{root}/book-quality/wrong-schema-runs.json"
  write_text_file(wrong_schema_path, "{\"runs\":\"not an array\"}")
  let wrong_schema = load_book_quality_review_run_ledger(wrong_schema_path)
  assert_eq(wrong_schema.runs.length(), 0)
}
