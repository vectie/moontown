///|
extern "js" fn imported_download_test_result(
  bytes : Bytes,
) -> ImportedOutputDownload =
  #| bytes => ({ ok: true, message: "", bytes })

///|
fn imported_download_pending_from_catalog(
  catalog_raw : String,
  selection : @imported_output_contract.Selection,
) -> Model raise {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, base) = update(
    dispatch,
    ImportedOutputsEvent(OpenImportedOutputs),
    init_model(),
  )
  let state = base.imported_outputs
  let (catalog, _) = imported_outputs_transition(
    state,
    ImportedCatalogLoaded(state.generation, catalog_raw),
  )
  let (book, _) = imported_outputs_transition(
    catalog,
    ChooseImportedBook(selection.book_handle),
  )
  let (output, _) = imported_outputs_transition(
    book,
    ChooseImportedOutput(selection.artifact_id),
  )
  let (file, _) = imported_outputs_transition(
    output,
    ChooseImportedFile(selection.path),
  )
  assert_eq(file.selection, Some(selection))
  let (pending, _) = imported_outputs_transition(file, DownloadImportedFile)
  { ..base, imported_outputs: pending, }
}

///|
fn imported_download_synthetic_catalog(
  selection : @imported_output_contract.Selection,
) -> String {
  let catalog : @imported_output_contract.Catalog = {
    contract: "moontown.imported_outputs.v1",
    state: "ready",
    message: "",
    books: [
      {
        handle: selection.book_handle,
        book_id: "download-fixture",
        name: "Download fixture",
        state: "ready",
        message: "",
        source: Some({
          agent_id: "fixture",
          agent_version: "1",
          package_sha256: selection.package_sha256,
          outputs_manifest_digest: Some(selection.manifest_sha256),
        }),
        outputs: [
          {
            artifact_id: selection.artifact_id,
            label: "Exact download",
            mime_type: "application/octet-stream",
            included: true,
            reference: None,
            declared_digest: None,
            preview_path: None,
            app_entrypoint: None,
            files: [
              {
                path: selection.path,
                size_bytes: selection.size_bytes,
                digest: selection.digest,
              },
            ],
          },
        ],
      },
    ],
  }
  catalog.to_json().stringify()
}

///|
fn imported_download_assert_gate(
  before : Model,
  result : ImportedOutputDownload,
  expected : Bool,
) -> Unit raise {
  let state = before.imported_outputs
  let key = state.selection.unwrap()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let event = ImportedDownloadReceived(
    state.generation,
    state.download_generation,
    key,
    result,
  )
  let (command, after) = update_non_form_message(dispatch, event, before)
  let scheduler = ImportedSurfaceScheduler::{ effects: 0, }
  @cmd.Scheduler::add(scheduler, command)
  assert_true(before.imported_outputs.open)
  assert_true(after.imported_outputs.open)
  if expected {
    assert_eq(scheduler.effects, 1)
    assert_true(after.imported_outputs.download is DownloadReady)
    assert_true(
      @imported_output_contract.selection_bytes_match(
        key,
        imported_output_download_bytes(result),
      ),
    )
    // The exact same valid response must not save after reverse navigation.
    let (_, moved) = update(dispatch, TogglePhone, before)
    let (late, _) = update(dispatch, event, moved)
    let stale_scheduler = ImportedSurfaceScheduler::{ effects: 0, }
    @cmd.Scheduler::add(stale_scheduler, late)
    assert_eq(stale_scheduler.effects, 0)
  } else {
    assert_eq(scheduler.effects, 0)
    assert_true(after.imported_outputs.download is DownloadUnavailable(_))
  }
}

///|
test "imported download uses actual held bytes rather than matching digest hints" {
  let before = imported_surface_pending_model()
  let good = @utf8.encode("x".repeat(42))
  imported_download_assert_gate(
    before,
    imported_download_test_result(good),
    true,
  )
  imported_download_assert_gate(
    before,
    imported_download_test_result(@utf8.encode("y" + "x".repeat(41))),
    false,
  )
  imported_download_assert_gate(
    before,
    imported_download_test_result(@utf8.encode("x".repeat(41))),
    false,
  )
  imported_download_assert_gate(
    before,
    imported_download_test_result(@utf8.encode("x".repeat(43))),
    false,
  )
}

///|
test "imported download empty bytes retain a genuine current-save control" {
  let before = imported_surface_pending_model()
  let (empty, _) = imported_outputs_transition(
    before.imported_outputs,
    ChooseImportedFile("portable/outputs/result/two.txt"),
  )
  let (pending, _) = imported_outputs_transition(empty, DownloadImportedFile)
  imported_download_assert_gate(
    { ..before, imported_outputs: pending, },
    imported_download_test_result(b""),
    true,
  )
}

///|
/// Evidence wrappers run this serially and require a final completion marker,
/// so the test cannot pass merely because detached async work never completed.
extern "js" fn imported_download_mock_response(
  bytes : Bytes,
  headers_json : String,
  status : Int,
  null_body : Bool,
  endpoint : String,
  run : () -> @js.Promise,
) -> @js.Promise =
  #| async (bytes, headersJson, status, nullBody, endpoint, run) => {
  #|   const previous = globalThis.fetch;
  #|   globalThis.fetch = async url => {
  #|     if (url !== endpoint) throw new Error("Unexpected endpoint");
  #|     return new Response(nullBody ? null : bytes, { status, headers: JSON.parse(headersJson) });
  #|   };
  #|   try { return await run(); } finally { globalThis.fetch = previous; }
  #| }

///|
async fn imported_download_assert_transport(
  catalog_raw : String,
  selection : @imported_output_contract.Selection,
  bytes : Bytes,
  headers : Map[String, String],
  expected : Bool,
  endpoint : String,
  status? : Int = 200,
  null_body? : Bool = false,
) -> Unit {
  let before = imported_download_pending_from_catalog(catalog_raw, selection)
  let result = wait_imported_output_download(
    imported_download_mock_response(
      bytes,
      headers.to_json().stringify(),
      status,
      null_body,
      endpoint,
      () => {
        fetch_imported_output_download(
          endpoint,
          selection.size_bytes,
          selection.digest,
        )
      },
    ),
  )
  imported_download_assert_gate(before, result, expected)
  if expected {
    assert_eq(imported_output_download_bytes(result), bytes)
  }
}
