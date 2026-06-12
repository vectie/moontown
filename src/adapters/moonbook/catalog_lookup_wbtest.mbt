///|
test "catalog provider exposes book refs without leaking provider internals" {
  let entry = moonbook_adapter_catalog_entry(
    id="finance",
    name="Finance",
    purpose="Maintain private finance state",
    workspace_root="/tmp/finance",
    tags=["finance"],
    skills=["ledger"],
  )
  let provider = MoonbookCatalogProvider::new([entry])
  let refs = provider.book_refs()
  assert_eq(refs.length(), 1)
  assert_eq(refs[0].id, "finance")
  assert_eq(refs[0].workspace_root, "/tmp/finance")
  assert_true(refs[0].tags == ["finance"])
}

///|
test "book id lookup creates only valid dynamic research entries" {
  let catalog = default_catalog()
  match entry_for_book_id(catalog, "research-ai-hardware") {
    Some(entry) => {
      assert_eq(entry.id, "research-ai-hardware")
      assert_true(entry.tags.contains("topic:ai-hardware"))
    }
    None => fail("expected dynamic research entry")
  }
  assert_true(entry_for_book_id(catalog, "research-") == None)
  assert_true(entry_for_book_id(catalog, "unknown-book") == None)
}

///|
test "explicit research lookup honors existing catalog entries first" {
  let catalog = default_catalog()
  match entry_for_explicit_research_book(catalog, "coding", "research coding") {
    Some(entry) => assert_eq(entry.id, "coding")
    None => fail("expected existing catalog entry")
  }
}
