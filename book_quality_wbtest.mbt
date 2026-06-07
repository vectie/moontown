///|
async test "book doctor writes structural audit and AI review packets" {
  let root = cleaned_book_quality_test_root("/tmp/moontown-book-quality-wbtest")
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let coding_root = "\{root}/books/coding"
  let civic_root = "\{root}/books/wenyu-policy-hall"
  let catalog = [
    book_quality_catalog_entry(
      id="coding",
      name="Coding",
      purpose="coding operations",
      workspace_root=coding_root,
      tags=["operational"],
    ),
    book_quality_catalog_entry(
      id="wenyu-policy-hall",
      name="Policy Hall",
      purpose="policy service protocol",
      workspace_root=civic_root,
      tags=["civic-service"],
    ),
  ]
  @moonbook.save_catalog_file(catalog_path, catalog)
  let audit_path = "\{root}/book-quality/audit.json"
  let doctor = write_book_quality_audit(
    book_catalog_path=catalog_path,
    snapshot_path~,
    audit_path~,
  )
  assert_true(
    doctor.contains("Wrote book management audit for 2 registered book"),
  )
  assert_true(@fs.exists(audit_path))
  assert_true(@fs.exists("\{root}/book-quality/audit.md"))
  assert_true(@fs.exists("\{coding_root}/wiki/operations/review-policy.md"))
  let audit = render_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  assert_true(
    audit.contains(
      "|coding|operational-book|100 / world-class|pending|pending-ai-review|true|",
    ),
  )
  assert_true(
    audit.contains(
      "|wenyu-policy-hall|civic-protocol-support|0 / not-managed|pending|pending-ai-review|false|",
    ),
  )
  let review_dir = "\{root}/book-quality/ai-review-packets"
  let packets = write_book_quality_review_packets(
    book_catalog_path=catalog_path,
    snapshot_path~,
    review_dir~,
  )
  assert_true(packets.contains("AI quality review packet"))
  assert_true(@fs.exists("\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md"))
  assert_true(@fs.exists("\{review_dir}/coding.json"))
  assert_true(@fs.exists("\{review_dir}/wenyu-policy-hall.json"))
  let skill = read_text_or_empty("\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md")
  assert_true(
    skill.contains(
      "Do not score a book as world-class just because files exist",
    ),
  )
}

///|
async test "book quality includes live runtime books outside catalog" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-runtime-wbtest",
  )
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let catalog = [
    book_quality_catalog_entry(
      id="coding",
      name="Coding",
      purpose="coding operations",
      workspace_root="\{root}/books/coding",
      tags=["operational"],
    ),
  ]
  @moonbook.save_catalog_file(catalog_path, catalog)
  let state = @core.empty_state(
    @core.TownConfig::new(id="quality-test", name="Quality Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="OPC Research",
      purpose="Track One Person Company research over time.",
      workspace_root="\{root}/books/research-opc",
      tags=["research", "standing-watch"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  let audit = inspect_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  assert_true(audit.total == 2)
  assert_true(audit.scores.any(fn(score) { score.book_id == "research-opc" }))
  let rendered = render_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  assert_true(rendered.contains("|research-opc|research-book|"))
}
