///|
fn imported_fixture_digest(mark : String) -> String {
  "sha256:" + mark.repeat(64)
}

///|
fn imported_fixture_catalog(
  size_bytes? : Int = 42,
) -> @imported_output_contract.Catalog {
  let files : Array[@imported_output_contract.OutputFile] = [
    {
      path: "portable/outputs/result/one 学习.txt",
      digest: "sha256:2b2573d5ea0b352e24bebd015f3fe83693a5b81a6252cf811b65dcf6a5037def",
      size_bytes,
    },
    {
      path: "portable/outputs/result/two.txt",
      digest: "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      size_bytes: 0,
    },
  ]
  let output : @imported_output_contract.Output = {
    artifact_id: "result",
    label: "Accepted <result>",
    mime_type: "text/plain",
    included: true,
    reference: None,
    declared_digest: None,
    files,
    preview_path: Some(files[0].path),
    app_entrypoint: None,
  }
  let source : @imported_output_contract.Source = {
    agent_id: "producer",
    agent_version: "1",
    package_sha256: imported_fixture_digest("c"),
    outputs_manifest_digest: Some(imported_fixture_digest("d")),
  }
  let book : @imported_output_contract.Book = {
    handle: "book-" + "1".repeat(64),
    book_id: "book-one",
    name: "Imported Book",
    state: "ready",
    message: "",
    source: Some(source),
    outputs: [
      output,
      {
        ..output,
        artifact_id: "ref",
        label: "Reference",
        included: false,
        files: [],
        preview_path: None,
        reference: Some("https://untrusted.example/<script>"),
      },
    ],
  }
  {
    contract: "moontown.imported_outputs.v1",
    state: "ready",
    message: "",
    books: [
      book,
      {
        ..book,
        handle: "book-" + "2".repeat(64),
        book_id: "book-two",
        name: "Second Book",
      },
    ],
  }
}

///|
fn imported_fixture_ready(size_bytes? : Int = 42) -> ImportedOutputsState {
  let (loading, _) = imported_outputs_transition(
    initial_imported_outputs_state(),
    OpenImportedOutputs,
  )
  let (loaded, _) = imported_outputs_transition(
    loading,
    ImportedCatalogLoaded(
      loading.generation,
      imported_fixture_catalog(size_bytes~).to_json().stringify(),
    ),
  )
  let (book, _) = imported_outputs_transition(
    loaded,
    ChooseImportedBook("book-" + "1".repeat(64)),
  )
  imported_outputs_transition(book, ChooseImportedOutput("result")).0
}

///|
fn imported_fixture_reply(
  selection : @imported_output_contract.Selection,
  content : String,
) -> String {
  let reply : @imported_output_contract.TextReply = {
    contract: "moontown.imported_output_text.v1",
    state: "ready",
    message: "",
    selection,
    content: Some(content),
  }
  reply.to_json().stringify()
}

///|
fn imported_fixture_render(state : ImportedOutputsState) -> String {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  @rabbita.render_to_string(
    @rabbita.static_cell(render_imported_outputs_drawer(dispatch, state)),
  )
}

///|
test "imported outputs close refresh and reopen fence stale catalog responses" {
  let (a, _) = imported_outputs_transition(
    initial_imported_outputs_state(),
    OpenImportedOutputs,
  )
  let (closed, _) = imported_outputs_transition(a, CloseImportedOutputs)
  let (b, _) = imported_outputs_transition(closed, OpenImportedOutputs)
  let raw = imported_fixture_catalog().to_json().stringify()
  assert_eq(
    imported_outputs_transition(b, ImportedCatalogLoaded(a.generation, raw)).0,
    b,
  )
  let (c, _) = imported_outputs_transition(b, RefreshImportedOutputs)
  assert_eq(
    imported_outputs_transition(c, ImportedCatalogLoaded(b.generation, raw)).0,
    c,
  )
  assert_eq(
    imported_outputs_transition(
      closed,
      ImportedCatalogLoaded(a.generation, raw),
    ).0,
    closed,
  )
  assert_true(
    imported_outputs_transition(c, ImportedCatalogLoaded(c.generation, raw)).0.catalog
    is CatalogReady(_),
  )
}

///|
test "imported outputs exact key and generation fence A after B and repeated clicks" {
  let ready = imported_fixture_ready()
  let (a, request_a) = imported_outputs_transition(
    ready,
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  guard request_a is Some(FetchImportedText(gen_a, key_a)) else {
    fail("missing text request")
  }
  let (b, request_b) = imported_outputs_transition(
    a,
    ChooseImportedFile("portable/outputs/result/two.txt"),
  )
  guard request_b is Some(FetchImportedText(gen_b, key_b)) else {
    fail("missing second request")
  }
  assert_eq(
    imported_outputs_transition(
      b,
      ImportedTextLoaded(gen_a, key_a, imported_fixture_reply(key_a, "old A")),
    ).0,
    b,
  )
  assert_eq(
    imported_outputs_transition(
      b,
      ImportedTextLoaded(
        gen_b,
        key_a,
        imported_fixture_reply(key_a, "wrong key"),
      ),
    ).0,
    b,
  )
  let (repeat, _) = imported_outputs_transition(
    b,
    ChooseImportedFile(key_b.path),
  )
  assert_eq(
    imported_outputs_transition(
      repeat,
      ImportedTextLoaded(
        gen_b,
        key_b,
        imported_fixture_reply(key_b, "old repeated click"),
      ),
    ).0,
    repeat,
  )
  let (settled, _) = imported_outputs_transition(
    b,
    ImportedTextLoaded(gen_b, key_b, imported_fixture_reply(key_b, "")),
  )
  assert_eq(settled.text, TextReady(""))
  assert_eq(
    imported_outputs_transition(
      settled,
      ImportedTextLoaded(
        gen_b,
        key_b,
        imported_fixture_reply(key_b, "duplicate"),
      ),
    ).0,
    settled,
  )
  for
    event in [
      RefreshImportedOutputs,
      CloseImportedOutputs,
      ChooseImportedBook("book-" + "2".repeat(64)),
      ChooseImportedOutput("ref"),
    ] {
    let (changed, _) = imported_outputs_transition(a, event)
    assert_eq(
      imported_outputs_transition(
        changed,
        ImportedTextLoaded(gen_a, key_a, imported_fixture_reply(key_a, "late")),
      ).0,
      changed,
    )
    assert_eq(changed.selection, None)
    assert_eq(changed.text, TextIdle)
  }
}

///|
test "imported outputs body reply identity source and digest drift fail closed" {
  let (loading, _) = imported_outputs_transition(
    imported_fixture_ready(),
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  let key = loading.selection.unwrap()
  for
    changed in [
      { ..key, package_sha256: imported_fixture_digest("e"), },
      { ..key, manifest_sha256: imported_fixture_digest("e"), },
      { ..key, digest: imported_fixture_digest("e"), },
      { ..key, size_bytes: 43, },
      { ..key, book_handle: "book-" + "2".repeat(64), },
    ] {
    let (blocked, _) = imported_outputs_transition(
      loading,
      ImportedTextLoaded(
        loading.generation,
        key,
        imported_fixture_reply(changed, "must not display"),
      ),
    )
    assert_true(blocked.text is TextUnavailable(_))
    assert_false(imported_fixture_render(blocked).contains("must not display"))
  }
  for raw in ["<html>static host</html>", "{}", "not JSON"] {
    let (blocked, _) = imported_outputs_transition(
      loading,
      ImportedTextLoaded(loading.generation, key, raw),
    )
    assert_true(blocked.text is TextUnavailable(_))
  }
}

///|
test "imported outputs full text is escaped with Unicode BOM CRLF markup and empty retained" {
  let content = "\uFEFF学习 😀\r\n<script>alert('x')</script><svg onload='x'>& full text\r\n"
  let (loading, _) = imported_outputs_transition(
    imported_fixture_ready(size_bytes=@utf8.encode(content).length()),
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  let key = loading.selection.unwrap()
  let (ready, _) = imported_outputs_transition(
    loading,
    ImportedTextLoaded(
      loading.generation,
      key,
      imported_fixture_reply(key, content),
    ),
  )
  assert_eq(ready.text, TextReady(content))
  let html = imported_fixture_render(ready)
  assert_true(html.contains("学习 😀\r\n"))
  assert_true(html.contains("&lt;script&gt;"))
  assert_true(html.contains("&lt;svg"))
  assert_false(html.contains("<script>"))
  assert_false(html.contains("<svg"))
  assert_true(html.contains("&amp; full text"))
  assert_true(html.contains("Verified full text"))
  assert_true(
    @imported_output_contract.content_path(key, mode="download").contains(
      "mode=download",
    ),
  )
  assert_true(
    @imported_output_contract.content_path(key, mode="download").contains(
      "one%20%E5%AD%A6%E4%B9%A0.txt",
    ),
  )
  let (empty_loading, _) = imported_outputs_transition(
    loading,
    ChooseImportedFile("portable/outputs/result/two.txt"),
  )
  let empty_key = empty_loading.selection.unwrap()
  let (empty, _) = imported_outputs_transition(
    empty_loading,
    ImportedTextLoaded(
      empty_loading.generation,
      empty_key,
      imported_fixture_reply(empty_key, ""),
    ),
  )
  assert_eq(empty.text, TextReady(""))
  assert_true(imported_fixture_render(empty).contains("empty text file"))
}

///|
test "imported outputs reference only and no included files have no fetch command" {
  let (reference, _) = imported_outputs_transition(
    imported_fixture_ready(),
    ChooseImportedOutput("ref"),
  )
  let (unchanged, request) = imported_outputs_transition(
    reference,
    ChooseImportedFile("portable/outputs/ref/fake.txt"),
  )
  assert_eq(unchanged, reference)
  assert_eq(request, None)
  let html = imported_fixture_render(reference)
  assert_true(html.contains("Reference-only"))
  assert_true(html.contains("https://untrusted.example/&lt;script&gt;"))
  assert_false(html.contains("href=\"https://untrusted"))
  assert_false(html.contains("Download exact file"))
  let catalog = imported_fixture_catalog()
  let book = catalog.books[0]
  let output = { ..book.outputs[0], files: [], preview_path: None, }
  let nofiles = {
    ..reference,
    artifact_id: "result",
    catalog: CatalogReady({
      ..catalog,
      books: [{ ..book, outputs: [output], }],
    }),
  }
  assert_true(imported_fixture_render(nofiles).contains("no included files"))
}

///|
test "imported outputs visible unavailable empty opaque too large and changed states" {
  let (loading, _) = imported_outputs_transition(
    initial_imported_outputs_state(),
    OpenImportedOutputs,
  )
  assert_true(
    imported_fixture_render(loading).contains("Loading imported outputs"),
  )
  let (static_host, _) = imported_outputs_transition(
    loading,
    ImportedCatalogLoaded(loading.generation, "<html>static</html>"),
  )
  assert_true(
    imported_fixture_render(static_host).contains("unavailable on this host"),
  )
  let empty : @imported_output_contract.Catalog = {
    ..imported_fixture_catalog(),
    state: "empty",
    books: [],
  }
  let (none, _) = imported_outputs_transition(
    loading,
    ImportedCatalogLoaded(loading.generation, empty.to_json().stringify()),
  )
  assert_true(imported_fixture_render(none).contains("No imported Books"))
  let (file, _) = imported_outputs_transition(
    imported_fixture_ready(),
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  let key = file.selection.unwrap()
  for status in ["unavailable", "opaque", "too_large"] {
    let reply : @imported_output_contract.TextReply = {
      contract: "moontown.imported_output_text.v1",
      state: status,
      message: "File changed or download required: " + status,
      selection: key,
      content: None,
    }
    let (blocked, _) = imported_outputs_transition(
      file,
      ImportedTextLoaded(file.generation, key, reply.to_json().stringify()),
    )
    assert_true(imported_fixture_render(blocked).contains(reply.message))
    assert_true(
      imported_fixture_render(blocked).contains("Download exact file"),
    )
  }
  let catalog = imported_fixture_catalog()
  let unsupported : @imported_output_contract.Catalog = {
    ..catalog,
    books: [
      {
        ..catalog.books[0],
        state: "unsupported",
        outputs: [],
        source: None,
        message: "No exact receipt.",
      },
    ],
  }
  let ready = {
    ..imported_fixture_ready(),
    catalog: CatalogReady(unsupported),
  }
  assert_true(
    imported_fixture_render(ready).contains(
      "Unsupported ordinary import provenance",
    ),
  )
}

///|
test "imported outputs drawer accessible and canonical toolbar integrated without execution" {
  let ready = imported_fixture_ready()
  let html = imported_fixture_render(ready)
  assert_true(html.contains("role=\"dialog\""))
  assert_true(html.contains("aria-labelledby=\"imported-outputs-title\""))
  assert_true(html.contains("Close imported outputs"))
  assert_true(html.contains("aria-pressed=\"true\""))
  assert_true(html.contains("Refresh"))
  assert_false(html.contains("<iframe"))
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let model = { ..init_model(), imported_outputs: ready, }
  let toolbar = @rabbita.render_to_string(
    @rabbita.static_cell(render_town_action_rail(dispatch, model, false, 5)),
  )
  assert_true(toolbar.contains("aria-controls=\"imported-outputs-panel\""))
  assert_true(toolbar.contains("Imported outputs"))
  let canonical = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_surface_for_route(CanonicalEnergyValley, dispatch, model),
    ),
  )
  assert_true(canonical.contains("id=\"imported-outputs-panel\""))
  assert_true(canonical.contains("Accepted &lt;result&gt;"))
  let (_, opened) = update_non_form_message(
    dispatch,
    ImportedOutputsEvent(OpenImportedOutputs),
    { ..init_model(), resident_explorer_open: true, },
  )
  assert_true(opened.imported_outputs.open)
  assert_true(opened.imported_outputs.catalog is CatalogLoading)
  assert_false(opened.resident_explorer_open)
  assert_false(close_town_transient_surfaces(model).imported_outputs.open)
  assert_eq(
    close_town_transient_surfaces(model).imported_outputs.text,
    TextIdle,
  )
}

///|
test "imported outputs stale downloads never save after repeat close refresh or selection changes" {
  let (file, _) = imported_outputs_transition(
    imported_fixture_ready(),
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  let (pending, request) = imported_outputs_transition(
    file,
    DownloadImportedFile,
  )
  guard request is Some(FetchImportedDownload(generation, serial, key)) else {
    fail("missing download")
  }
  assert_true(
    imported_outputs_accepts_download(pending, generation, serial, key),
  )
  for
    event in [
      DownloadImportedFile,
      RefreshImportedOutputs,
      CloseImportedOutputs,
      ChooseImportedBook("book-" + "2".repeat(64)),
      ChooseImportedOutput("ref"),
      ChooseImportedFile("portable/outputs/result/two.txt"),
    ] {
    let (changed, _) = imported_outputs_transition(pending, event)
    assert_false(
      imported_outputs_accepts_download(changed, generation, serial, key),
    )
    assert_eq(
      imported_outputs_transition(
        changed,
        ImportedDownloadStatus(generation, serial, key, true, ""),
      ).0,
      changed,
    )
  }
  let wrong = { ..key, digest: imported_fixture_digest("f"), }
  assert_false(
    imported_outputs_accepts_download(pending, generation, serial, wrong),
  )
  let (failed, _) = imported_outputs_transition(
    pending,
    ImportedDownloadStatus(
      generation, serial, key, false, "File changed. Refresh.",
    ),
  )
  assert_true(
    imported_fixture_render(failed).contains("File changed. Refresh."),
  )
  assert_false(
    imported_outputs_accepts_download(failed, generation, serial, key),
  )
  assert_true(failed.open)
  let (ready, _) = imported_outputs_transition(
    pending,
    ImportedDownloadStatus(generation, serial, key, true, ""),
  )
  assert_true(ready.download is DownloadReady)
  assert_false(
    imported_outputs_accepts_download(ready, generation, serial, key),
  )
}

///|
test "imported outputs maximum full text is untruncated and over limit rejected" {
  let limit = @imported_output_contract.text_preview_limit()
  let suffix = " END 学习😀"
  let content = "x".repeat(limit - @utf8.encode(suffix).length()) + suffix
  let (loading, _) = imported_outputs_transition(
    imported_fixture_ready(size_bytes=limit),
    ChooseImportedFile("portable/outputs/result/one 学习.txt"),
  )
  let key = loading.selection.unwrap()
  let (ready, _) = imported_outputs_transition(
    loading,
    ImportedTextLoaded(
      loading.generation,
      key,
      imported_fixture_reply(key, content),
    ),
  )
  assert_eq(ready.text, TextReady(content))
  let html = imported_fixture_render(ready)
  assert_true(html.contains(suffix))
  assert_true(html.length() > content.length())
  let oversized = { ..key, size_bytes: limit + 1, }
  assert_eq(
    @imported_output_contract.parse_text_reply(
      imported_fixture_reply(oversized, content + "x"),
    ),
    None,
  )
}
