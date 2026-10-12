///|
extern "js" fn picker_http_endpoint() -> String =
  #| () => globalThis.process?.env?.MOONTOWN_PICKER_HTTP_URL || ""

///|
extern "js" fn picker_http_fixture(
  phase : String,
  revision : String,
) -> @js.Promise =
  #| async (phase, revision) => {
  #|   const fs = await import("node:fs/promises");
  #|   const {createHash} = await import("node:crypto");
  #|   const root = process.env.MOONTOWN_PICKER_FIXTURE;
  #|   const state = process.env.MOONTOWN_PICKER_HTTP_STATE;
  #|   if (!root || !state) throw Error("Missing isolated picker fixtures");
  #|   const bytes = Buffer.from([99,117,114,114,101,110,116,0,255,10]);
  #|   const path = root + "/books/water/raw/nested/source.bin";
  #|   if (phase === "change-before-save") await fs.writeFile(path, bytes);
  #|   else if (phase === "change-after-save") await fs.writeFile(path, "newer live file");
  #|   else if (phase === "verify") {
  #|     const captured = await fs.readFile(state + "/collaboration-authoring/drafts/http-picker/revisions/" + revision + "/sources/water/raw/nested/source.bin");
  #|     if (!captured.equals(bytes)) throw Error("Captured bytes differ from save-time bytes");
  #|     if ((await fs.readFile(path, "utf8")) !== "newer live file") throw Error("Town changed live Book bytes");
  #|   }
  #|   return "sha256:" + createHash("sha256").update(bytes).digest("hex");
  #| }

///|
async fn picker_http_action(
  state : @collaboration.Client,
  action : String,
  id : String,
) -> @collaboration.Client {
  let pending = state.begin(action, id)
  let raw = collaboration_wait(
    collaboration_fetch(
      picker_http_endpoint(),
      collaboration_payload(pending, action, id, state.revision, ""),
    ),
  )
  let next = pending.settle(pending.generation, action, raw)
  assert_false(next.busy())
  return next
}

///|
async test "source picker actual native HTTP crosses compiled list select explicit save and reopen" {
  if picker_http_endpoint().is_empty() {
    println(
      "Native HTTP picker crossing not configured; set MOONTOWN_PICKER_HTTP_URL",
    )
    return
  }
  let listed = picker_http_action(@collaboration.Client::new(), "list", "")
  assert_eq(listed.books.length(), 2)
  let mut state = listed
    .toggle_book("water")
    .toggle_book("mobility")
    .edit("draft_id", "http-picker")
  for id in ["water", "mobility"] {
    state = picker_http_action(state.select_source_book(id), "source-list", id)
    let observation = state.source_listing.unwrap()
    assert_eq(observation.book_id, id)
    assert_true(observation.paths.contains("raw/nested/source.bin"))
    assert_false(observation.paths.contains("pipe"))
    state = state.toggle_source("raw/nested/source.bin")
    assert_true(state.sources.is_empty())
  }
  let expected = collaboration_wait(
    picker_http_fixture("change-before-save", ""),
  )
  let saved = picker_http_action(state, "save", "http-picker")
  assert_false(saved.dirty, msg=saved.notice)
  assert_eq(saved.sources.length(), 2)
  assert_eq(saved.sources[0].digest, expected)
  ignore(
    collaboration_wait(picker_http_fixture("change-after-save", saved.revision)),
  )
  let reopened = picker_http_action(saved, "load", "http-picker")
  assert_eq(reopened.revision, saved.revision)
  assert_eq(reopened.sources, saved.sources)
  assert_eq(
    collaboration_wait(picker_http_fixture("verify", reopened.revision)),
    expected,
  )
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, reopened)),
  )
  assert_true(html.contains(saved.revision))
  assert_true(html.contains(expected))
  println(
    "Actual native HTTP → compiled picker → explicit save → reopen: " +
    saved.revision +
    " captured " +
    expected,
  )
}
