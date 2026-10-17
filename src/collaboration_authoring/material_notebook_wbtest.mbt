///|
async fn material_fixture() -> (Store, String, @contract.MaterialNotebook) {
  let (store, root) = fixture()
  for
    (id, text) in [
      (
        "water", "# Water observations\nThe south plot stayed dry after rain.\nNo temperature was recorded.\n",
      ),
      (
        "mobility", "# Site observations\nThe south path has no shade at noon.\nThe north path was closed.\n",
      ),
    ] {
    @fs.write_file(
      root + "/books/" + id + "/raw/observations.md",
      text,
      create_mode=CreateNew,
    )
    @fs.write_file(
      root + "/books/" + id + "/raw/unselected.md",
      "Not relevant to this question.\n",
      create_mode=CreateNew,
    )
  }
  let selections : Array[@contract.MaterialSelection] = ["water", "mobility"].map(book_id => {
      book_id,
      source_paths: ["raw/observations.md", "raw/unselected.md"],
    },
  )
  let imported = store.import_material("shade-question", selections)
  assert_false(@fs.exists(store.root))
  assert_eq(imported.pages.length(), 4)
  assert_eq(imported.question, "")
  assert_true(imported.excerpts.is_empty())
  let notebook = {
    ..imported,
    title: "Does shade explain dry soil?",
    question: "Could shade and irrigation timing explain the south plot?",
    falsifier: "If equally irrigated shaded and exposed sensors stay equally dry, reject the shade hypothesis.",
    dissent: "The path observation may not describe the plot itself.",
    assumptions: "The observation dates and rainfall exposure are comparable.",
    reviewer_id: "alex",
    reviewer_name: "Alex Reviewer",
    objection_reviewer_id: "sam",
    objection_reviewer_name: "Sam Reviewer",
    excerpts: [
      {
        book_id: "water",
        source_path: "raw/observations.md",
        quote: "The south plot stayed dry after rain.",
        observation: "Dry soil after rain raises a possible exposure question.",
        challenge: "Check the actual rainfall and irrigation record.",
      },
      {
        book_id: "mobility",
        source_path: "raw/observations.md",
        quote: "The south path has no shade at noon.",
        observation: "Nearby shade observations suggest a test, not a causal conclusion.",
        challenge: "Check whether the path and plot share the same exposure.",
      },
    ],
  }
  (store, root, notebook)
}

///|
async test "material notebook imports explores edits saves reopens prepares and exports exact sources" {
  let (store, root, notebook) = material_fixture()
  let catalog_before = @fs.read_file(store.catalog_path).binary()
  let source_before = @fs.read_file(root + "/books/water/raw/observations.md").binary()
  let search = notebook.find("south")
  assert_eq(search.matched_lines, 2)
  assert_true(search.matches.all(m => m.line_number == 2))
  let saved = store.save_material_notebook(notebook, "2026-10-14T07:40:00Z")
  assert_eq(saved.sources.length(), 2)
  assert_eq(store.save_material_notebook(notebook, "later"), saved)
  assert_eq(store.load(notebook.draft_id), saved)
  let edited = store.save(
    { ..saved.draft, title: "Shade inquiry, edited", },
    saved.revision,
    "2026-10-14T07:41:00Z",
  )
  assert_eq(store.load(notebook.draft_id), edited)
  assert_eq(store.load(notebook.draft_id, revision=saved.revision), saved)
  let prepared = store.prepare(notebook.draft_id, edited.revision)
  let source = store.artifact(
    notebook.draft_id,
    edited.revision,
    revision_prefix(edited) + "sources/water/raw/observations.md",
  )
  assert_eq(source, source_before)
  let handoff_bytes = store.artifact(
    notebook.draft_id,
    edited.revision,
    revision_prefix(edited) + "handoff.json",
  )
  let handoff : @civic.CivicCommunicationScenarioHandoff = @json.from_json(
    @json.parse(@utf8.decode(handoff_bytes)),
  )
  assert_eq(handoff.scenario.ideas.length(), 0)
  assert_eq(handoff.scenario.review_gate, "named-human")
  assert_eq(handoff.scenario.interval_ms, None)
  assert_false(@utf8.decode(handoff_bytes).contains(root))
  let archive = store.export_tar(notebook.draft_id, edited.revision)
  assert_eq(store.export_tar(notebook.draft_id, edited.revision), archive)
  assert_eq(@fs.read_file(store.catalog_path).binary(), catalog_before)
  assert_eq(
    @fs.read_file(root + "/books/water/raw/observations.md").binary(),
    source_before,
  )
  assert_false(@fs.exists(root + "/books/water/review"))
  assert_false(@fs.exists(store.root + "/schedules"))
  if @env.get_env_var("MOONTOWN_MATERIAL_EVIDENCE") is Some(output) {
    @fs.mkdir(output, recursive=true)
    for
      (name, value) in [
        ("notebook", notebook.to_json()),
        ("search", search.to_json()),
        ("saved", saved.to_json()),
        ("edited", edited.to_json()),
        ("prepared", prepared.to_json()),
      ] {
      @fs.write_file(
        output + "/" + name + ".json",
        value.stringify(indent=2),
        create_mode=CreateNew,
      )
    }
    @fs.write_file(output + "/inquiry.tar", archive, create_mode=CreateNew)
    @fs.write_file(output + "/fixture-root.txt", root, create_mode=CreateNew)
  }
}

///|
async test "material save checks selected exact buffers and leaves changed sources for reimport" {
  let (store, root, notebook) = material_fixture()
  @fs.write_file(
    root + "/books/water/raw/observations.md",
    "Changed after import\n",
  )
  try store.save_material_notebook(notebook, "now") catch {
    CollaborationError(message) =>
      assert_true(message.contains("changed or was edited"))
    error => raise error
  } noraise {
    _ => fail("changed source accepted")
  }
  assert_true(store.list().is_empty())
  assert_eq(
    @fs.read_file(root + "/books/water/raw/observations.md").text(),
    "Changed after import\n",
  )
}

///|
async test "material save rejects edited imported text and forged digest" {
  let (store, _, notebook) = material_fixture()
  let pages = notebook.pages.copy()
  let original = pages[0]
  let text = original.text + "Extra assertion\n"
  pages[0] = { ..original, text, size_bytes: @utf8.encode(text).length(), }
  try store.save_material_notebook({ ..notebook, pages, }, "now") catch {
    CollaborationError(_) => ()
    error => raise error
  } noraise {
    _ => fail("edited source copy accepted")
  }
  pages[0] = {
    ..original,
    digest: "sha256:0000000000000000000000000000000000000000000000000000000000000000",
  }
  try store.save_material_notebook({ ..notebook, pages, }, "now") catch {
    CollaborationError(_) => ()
    error => raise error
  } noraise {
    _ => fail("forged digest accepted")
  }
  assert_true(store.list().is_empty())
}

///|
async test "unselected imported material may change without becoming captured evidence" {
  let (store, root, notebook) = material_fixture()
  @fs.write_file(
    root + "/books/water/raw/unselected.md",
    "Unselected changed\n",
  )
  let saved = store.save_material_notebook(notebook, "now")
  assert_eq(saved.sources.length(), 2)
  assert_true(saved.sources.all(s => s.source_path == "raw/observations.md"))
  assert_false(saved.draft.question.contains("Unselected changed"))
}

///|
async test "material import refuses missing hidden traversal binary oversized and symlink sources" {
  let (store, root) = fixture()
  @fs.write_file(
    root + "/books/water/raw/text.md",
    "text",
    create_mode=CreateNew,
  )
  @fs.symlink(
    target=root + "/books/water/raw/text.md",
    root + "/books/water/raw/link.md",
  )
  @fs.write_file(
    root + "/books/water/raw/large.md",
    Bytes::make(65537, b'a'),
    create_mode=CreateNew,
  )
  for
    path in [
      "missing.md", ".private", "../outside", "raw/nested/source.bin", "raw/link.md",
      "raw/large.md",
    ] {
    try
      store.import_material("example", [
        { book_id: "water", source_paths: [path], },
      ])
    catch {
      _ => ()
    } noraise {
      _ => fail("unexpected source import: " + path)
    }
  }
  assert_false(@fs.exists(store.root))
  try
    store.import_material("example", [
      { book_id: "unknown", source_paths: ["raw/text.md"], },
    ])
  catch {
    _ => ()
  } noraise {
    _ => fail("unknown Book imported")
  }
}
