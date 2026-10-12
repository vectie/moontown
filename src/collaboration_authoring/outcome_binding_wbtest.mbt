///|
async test "retained outcome actual archive members reject same-size replacement after initial verification" {
  let escaped : Array[String] = []
  for member in ["draft", "source", "terminal", "report"] {
    let (store, _) = fixture()
    let saved = store.save(fixture_draft(), "", "2026-10-07T07:00:00Z")
    ignore(retain_outcome_fixture(store, saved, false))
    // Freeze the same verified values used by outcome_snapshot, then emulate a
    // non-cooperating filesystem writer before the export member reads.
    let saved = store.load_revision(saved.draft.draft_id, saved.revision)
    let work = store.retained_work(saved)
    let before = store.outcome_bound_members(saved, work)
    let root = store.draft_root(saved.draft.draft_id) +
      "/" +
      revision_prefix(saved)
    let (path, old, replacement) = match member {
      "draft" => (root + "draft.json", "Which evidence", "Whose evidence")
      "source" =>
        (root + "sources/water/raw/nested/source.bin", "exact", "other")
      "terminal" =>
        (
          root + "oneoff/produced/water/terminal.json",
          "Retained local fixture",
          "Modified local fixture",
        )
      _ =>
        (
          root + "oneoff/produced/water/report.md",
          "Exact contribution",
          "Other contribution",
        )
    }
    let original = read_bytes(path, 2097152)
    let changed = if member == "source" {
      b"other\x00source\xff\n"
    } else {
      @utf8.encode(text_bytes(original).replace_all(old~, new=replacement))
    }
    assert_eq(changed.length(), original.length(), msg=member)
    assert_true(changed != original, msg=member)
    @fs.write_file(path, changed)
    let refused = try {
      ignore(store.outcome_bound_members(saved, work))
      false
    } catch {
      CollaborationError(message) => message.contains("Export member")
      _ => false
    }
    if !refused {
      escaped.push(member)
    }
    @fs.write_file(path, original)
    assert_eq(store.outcome_bound_members(saved, work), before)
  }
  assert_eq(
    escaped,
    [],
    msg="Member classes exported despite same-size replacement after initial verification: " +
      escaped.join(", "),
  )
}
