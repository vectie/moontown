///|
fn initial_imported_outputs_state() -> ImportedOutputsState {
  {
    open: false,
    generation: 0,
    catalog: CatalogIdle,
    book_handle: "",
    artifact_id: "",
    selection: None,
    download_generation: 0,
    download: DownloadIdle,
    text: TextIdle,
    table: None,
    table_query: "",
    table_page: 0,
    table_show: true,
    table_view: initial_table_view(),
    agenda: initial_agenda(),
    geo: initial_geo(),
    places: initial_places(),
  }
}

///|
fn close_imported_outputs(state : ImportedOutputsState) -> ImportedOutputsState {
  { ..initial_imported_outputs_state(), generation: state.generation + 1, }
}

///|
fn imported_outputs_book(
  state : ImportedOutputsState,
) -> @imported_output_contract.Book? {
  guard state.catalog is CatalogReady(catalog) else { return None }
  for book in catalog.books {
    if book.handle == state.book_handle {
      return Some(book)
    }
  }
  None
}

///|
fn imported_outputs_output(
  state : ImportedOutputsState,
) -> @imported_output_contract.Output? {
  guard imported_outputs_book(state) is Some(book) else { return None }
  if book.state != "ready" {
    return None
  }
  for output in book.outputs {
    if output.artifact_id == state.artifact_id {
      return Some(output)
    }
  }
  None
}

///|
fn imported_outputs_selection(
  state : ImportedOutputsState,
  path : String,
) -> @imported_output_contract.Selection? {
  guard imported_outputs_book(state) is Some(book) else { return None }
  guard book.source is Some(source) else { return None }
  guard source.outputs_manifest_digest is Some(manifest_sha256) else {
    return None
  }
  guard imported_outputs_output(state) is Some(output) else { return None }
  if !output.included {
    return None
  }
  let matching = output.files.filter(file => file.path == path)
  guard matching is [file] else { return None }
  let selection : @imported_output_contract.Selection = {
    book_handle: book.handle,
    package_sha256: source.package_sha256,
    manifest_sha256,
    artifact_id: output.artifact_id,
    path: file.path,
    digest: file.digest,
    size_bytes: file.size_bytes,
  }
  if @imported_output_contract.selection_valid(selection) {
    Some(selection)
  } else {
    None
  }
}

///|
/// Generation fences include every selection, refresh and close, even repeated
/// choices. The host still revalidates all pins before reading any file.
fn imported_outputs_transition(
  state : ImportedOutputsState,
  msg : ImportedOutputsMsg,
) -> (ImportedOutputsState, ImportedOutputsRequest?) {
  match msg {
    OpenImportedOutputs | RefreshImportedOutputs => {
      if msg is RefreshImportedOutputs && !state.open {
        return (state, None)
      }
      let generation = state.generation + 1
      (
        {
          ..initial_imported_outputs_state(),
          open: true,
          generation,
          catalog: CatalogLoading,
        },
        Some(FetchImportedCatalog(generation)),
      )
    }
    CloseImportedOutputs => (close_imported_outputs(state), None)
    ImportedCatalogLoaded(generation, raw) => {
      if !state.open ||
        generation != state.generation ||
        !(state.catalog is CatalogLoading) {
        return (state, None)
      }
      let catalog = match @imported_output_contract.parse_catalog(raw) {
        Some(value) if value.state != "unavailable" => CatalogReady(value)
        Some(value) => CatalogUnavailable(value.message)
        None =>
          CatalogUnavailable(
            "Imported outputs are unavailable on this host. Open Town from its local server and refresh.",
          )
      }
      ({ ..state, catalog, }, None)
    }
    ChooseImportedBook(handle) => {
      if !state.open {
        return (state, None)
      }
      guard state.catalog is CatalogReady(catalog) else { return (state, None) }
      if !catalog.books.any(book => book.handle == handle) {
        return (state, None)
      }
      (
        {
          ..state,
          generation: state.generation + 1,
          book_handle: handle,
          artifact_id: "",
          selection: None,
          download_generation: 0,
          download: DownloadIdle,
          text: TextIdle,
          table: None,
          table_query: "",
          table_page: 0,
          table_show: true,
          table_view: initial_table_view(),
          agenda: initial_agenda(),
          geo: initial_geo(),
          places: initial_places(),
        },
        None,
      )
    }
    ChooseImportedOutput(artifact_id) => {
      if !state.open {
        return (state, None)
      }
      guard imported_outputs_book(state) is Some(book) else {
        return (state, None)
      }
      if book.state != "ready" ||
        !book.outputs.any(output => output.artifact_id == artifact_id) {
        return (state, None)
      }
      (
        {
          ..state,
          generation: state.generation + 1,
          artifact_id,
          selection: None,
          download_generation: 0,
          download: DownloadIdle,
          text: TextIdle,
          table: None,
          table_query: "",
          table_page: 0,
          table_show: true,
          table_view: initial_table_view(),
          agenda: initial_agenda(),
          geo: initial_geo(),
          places: initial_places(),
        },
        None,
      )
    }
    ChooseImportedFile(path) => {
      if !state.open {
        return (state, None)
      }
      guard imported_outputs_selection(state, path) is Some(selection) else {
        return (state, None)
      }
      let generation = state.generation + 1
      (
        {
          ..state,
          generation,
          selection: Some(selection),
          download: DownloadIdle,
          text: TextLoading,
          table: None,
          table_query: "",
          table_page: 0,
          table_show: true,
          table_view: initial_table_view(),
          agenda: initial_agenda(),
          geo: initial_geo(),
          places: initial_places(),
        },
        Some(FetchImportedText(generation, selection)),
      )
    }
    AgendaEvent(message) => agenda_transition(state, message)
    GeoEvent(message) => geo_transition(state, message)
    PlacesEvent(message) => places_transition(state, message)
    TableViewEvent(message) => table_view_transition(state, message)
    SearchImportedTable(query) => {
      if !state.open || !(state.table is Some(Ok(_))) {
        return (state, None)
      }
      ({ ..state, table_query: query, table_page: 0, }, None)
    }
    PageImportedTable(page) => {
      guard state.open && state.table is Some(Ok(table)) else {
        return (state, None)
      }
      let count = imported_table_view_rows(state, table).length()
      if page < 0 || page >= (count + 24) / 25 {
        return (state, None)
      }
      ({ ..state, table_page: page, }, None)
    }
    ShowImportedTable(show) => {
      if !state.open || !(state.table is Some(Ok(_))) {
        return (state, None)
      }
      (
        { ..state, table_show: show, places: { ..state.places, show: false, }, },
        None,
      )
    }
    DownloadFilteredTable => {
      guard state.open &&
        state.table is Some(Ok(table)) &&
        state.selection is Some(_) else {
        return (state, None)
      }
      match
        table.view_csv(
          imported_table_view_rows(state, table),
          imported_table_view_columns(state, table),
        ) {
        Ok(csv) => (state, Some(SaveFilteredTable(csv, "table-view.csv")))
        Err(_) => (state, None)
      }
    }
    DownloadImportedFile => {
      guard state.open && state.selection is Some(selection) else {
        return (state, None)
      }
      let download_generation = state.download_generation + 1
      (
        { ..state, download_generation, download: DownloadLoading, },
        Some(
          FetchImportedDownload(
            state.generation,
            download_generation,
            selection,
          ),
        ),
      )
    }
    ImportedDownloadStatus(
      generation,
      download_generation,
      selection,
      ok,
      message
    ) => {
      if !imported_outputs_accepts_download(
          state, generation, download_generation, selection,
        ) {
        return (state, None)
      }
      (
        {
          ..state,
          download: if ok {
            DownloadReady
          } else {
            DownloadUnavailable(message)
          },
        },
        None,
      )
    }
    ImportedTextLoaded(generation, expected, raw) => {
      if !state.open ||
        generation != state.generation ||
        state.selection != Some(expected) ||
        !(state.text is TextLoading) {
        return (state, None)
      }
      let geo_file = match imported_outputs_output(state) {
        Some(output) =>
          @imported_output_contract.geojson_file(
            expected.path,
            output.mime_type,
          )
        None => false
      }
      let text = match @imported_output_contract.parse_text_reply(raw) {
        Some(reply) if reply.selection == expected =>
          if reply.state == "ready" {
            match reply.content {
              Some(content) =>
                // The host verifies every read. GeoJSON additionally binds the
                // derived feature model to the exact pinned UTF-8 bytes here.
                if geo_file &&
                  !@imported_output_contract.selection_bytes_match(
                    expected,
                    @utf8.encode(content),
                  ) {
                  TextUnavailable(
                    "GeoJSON bytes do not match the selected file. Refresh imported outputs before reading again.",
                  )
                } else {
                  TextReady(content)
                }
              None =>
                TextUnavailable(
                  "The host did not return verified text. Refresh to check this file again.",
                )
            }
          } else {
            TextUnavailable(reply.message)
          }
        _ =>
          TextUnavailable(
            "The file or response changed. Refresh the imported outputs before reading again.",
          )
      }
      let table = match text {
        TextReady(content) =>
          match imported_outputs_output(state) {
            Some(output) =>
              match
                @imported_output_contract.table_delimiter(
                  expected.path,
                  output.mime_type,
                ) {
                Some(delimiter) =>
                  Some(
                    @imported_output_contract.parse_data_table(
                      content, delimiter,
                    ),
                  )
                None => None
              }
            None => None
          }
        _ => None
      }
      let agenda = match text {
        TextReady(content) =>
          match imported_outputs_output(state) {
            Some(output) if @imported_output_contract.calendar_file(
                expected.path,
                output.mime_type,
              ) =>
              {
                ..initial_agenda(),
                events: Some(@imported_output_contract.parse_calendar(content)),
              }
            _ => initial_agenda()
          }
        _ => initial_agenda()
      }
      let geo = match text {
        TextReady(content) if geo_file =>
          {
            ..initial_geo(),
            features: Some(@imported_output_contract.parse_geojson(content)),
          }
        _ => initial_geo()
      }
      ({ ..state, text, table, agenda, geo, }, None)
    }
  }
}

///|
fn imported_outputs_accepts_download(
  state : ImportedOutputsState,
  generation : Int,
  download_generation : Int,
  selection : @imported_output_contract.Selection,
) -> Bool {
  state.open &&
  state.generation == generation &&
  state.download_generation == download_generation &&
  state.selection == Some(selection) &&
  state.download is DownloadLoading
}
