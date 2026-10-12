///|
fn picker_reply(state : @collaboration.Client, book : String) -> String {
  let reply : @collaboration.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: state.generation.to_string(),
    action: "source-list",
    ok: true,
    error: "",
    books: [],
    drafts: [],
    saved: None,
    prepared: None,
    work: None,
    outcomes: [],
    outcome: None,
    source_listing: Some({
      book_id: book,
      paths: ["raw/nested/source.bin", "raw/研究.txt"],
      scanned_entries: 4,
      excluded_entries: 0,
      unreadable_entries: 1,
      truncated: true,
      detail: "Listing truncated and incomplete; unreadable entries: 1. Paths only, save captures bytes.",
    }),
  }
  reply.to_json().stringify()
}

///|
test "source picker compiled controls select paths without capture search and fence stale Book callbacks" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let initial = collaboration_test_state()
    .select_source_book("water")
    .begin("source-list", "water")
  let ready = initial.settle(
    initial.generation,
    "source-list",
    picker_reply(initial, "water"),
  )
  assert_eq(ready.source_listing.unwrap().book_id, "water")
  let selected = ready.toggle_source("raw/nested/source.bin")
  assert_true(selected.dirty)
  assert_true(selected.sources.is_empty())
  assert_eq(selected.draft.participants[0].source_paths, [
    "raw/nested/source.bin",
  ])
  assert_true(selected.draft.participants[1].source_paths.is_empty())
  let searched = selected.edit("source_filter", "研究")
  assert_eq(searched.visible_source_paths(), ["raw/研究.txt"])
  assert_eq(
    searched.toggle_source("raw/nested/source.bin").draft,
    selected.draft,
  )
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, searched)),
  )
  for
    text in [
      "Search observed paths", "Listing truncated and incomplete", "Save draft and capture sources",
      "raw/nested/source.bin", "研究.txt",
    ] {
    assert_true(html.contains(text), msg=text)
  }
  let other = initial.select_source_book("mobility")
  assert_false(other.busy())
  assert_eq(
    other.settle(
      initial.generation,
      "source-list",
      picker_reply(initial, "water"),
    ).source_book,
    "mobility",
  )
  assert_true(other.source_listing is None)
  let wrong = initial.settle(
    initial.generation,
    "source-list",
    picker_reply(initial, "mobility"),
  )
  assert_true(wrong.source_listing is None)
  assert_true(wrong.notice.contains("did not match"))
  assert_true(ready.toggle_book("water").source_listing is None)
  let payload : Json = @json.parse(
    collaboration_payload(initial, "source-list", "water", "", ""),
  )
  assert_true(payload is { "payload": { "book_id": "water", .. }, .. })
  assert_true(payload is { "draft": Null, .. })
  let spaced_listing = {
    ..ready.source_listing.unwrap(),
    paths: ["raw/ exact space "],
  }
  let spaced = { ..ready, source_listing: Some(spaced_listing), }.toggle_source(
    "raw/ exact space ",
  )
  assert_eq(spaced.draft.participants[0].source_paths, ["raw/ exact space "])
  let many = {
    ..ready,
    source_listing: Some({
      ..spaced_listing,
      paths: Array::makei(17, i => "raw/" + i.to_string()),
    }),
  }
  let mut many = many
  for i in 0..<17 {
    many = many.toggle_source("raw/" + i.to_string())
  }
  assert_eq(many.draft.participants[0].source_paths.length(), 16)
  assert_true(many.notice.contains("at most 16"))
}

///|
extern "js" fn native_picker_evidence() -> @js.Promise =
  #| async () => {
  #|   const path = globalThis.process?.env?.MOONTOWN_PICKER_EVIDENCE;
  #|   if (!path) return "";
  #|   return await (await import("node:fs/promises")).readFile(path, "utf8");
  #| }

///|
/// Crossing from actual native capture evidence into the compiled composer.
async test "source picker native listing and saved immutable revision cross compiled UI" {
  let raw = collaboration_wait(native_picker_evidence())
  if raw.is_empty() {
    println(
      "Native picker crossing not configured; set MOONTOWN_PICKER_EVIDENCE",
    )
    return
  }
  let evidence = @json.parse(raw)
  guard evidence
    is {
      "listing": listing_json,
      "saved": saved_json,
      "captured_digest": String(digest),
      ..
    } else {
    fail("native evidence missing")
  }
  let listing : @collaboration.SourceListing = @json.from_json(listing_json)
  let saved : @collaboration.SavedDraft = @json.from_json(saved_json)
  let initial = collaboration_test_state()
    .select_source_book("water")
    .begin("source-list", "water")
  let observed_json : Json = @json.parse(picker_reply(initial, "water"))
  let observed : @collaboration.Reply = @json.from_json(observed_json)
  let observed = { ..observed, source_listing: Some(listing), }
  let selected = initial
    .settle(initial.generation, "source-list", observed.to_json().stringify())
    .toggle_source("raw/nested/source.bin")
  assert_eq(
    selected.draft.participants[0].source_paths,
    saved.draft.participants[0].source_paths,
  )
  assert_true(selected.sources.is_empty())
  let opening = selected.begin("load", saved.draft.draft_id)
  let reply = {
    ..observed,
    action: "load",
    request_id: opening.generation.to_string(),
    source_listing: None,
    saved: Some(saved),
  }
  let reopened = opening.settle(
    opening.generation,
    "load",
    reply.to_json().stringify(),
  )
  assert_false(reopened.dirty)
  assert_eq(reopened.revision, saved.revision)
  assert_eq(reopened.sources[0].digest, digest)
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, reopened)),
  )
  assert_true(html.contains(saved.revision))
  assert_true(html.contains(digest))
  println(
    "Native list/select/save/reopen evidence crossed compiled picker and exact revision rendering: " +
    saved.revision,
  )
}
