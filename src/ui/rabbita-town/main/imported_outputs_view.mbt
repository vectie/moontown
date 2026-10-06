///|
fn imported_output_status(message : String) -> @rabbita.Html {
  @html.p(
    class="imported-outputs-status",
    attrs=@html.Attrs::build().role("status").aria_live("polite"),
    message,
  )
}

///|
fn render_imported_outputs_drawer(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
) -> @rabbita.Html {
  if !state.open {
    return @html.nothing
  }
  @html.section(
    id="imported-outputs-panel",
    class="resident-explorer imported-outputs-drawer pointer-events-auto",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("false")
      .aria_labelledby("imported-outputs-title")
      .on_keydown(event => {
        if event.key() == "Escape" {
          dispatch(ImportedOutputsEvent(CloseImportedOutputs))
        } else {
          @rabbita.none
        }
      }),
    [
      @html.header(class="resident-explorer-head", [
        @html.div(class="resident-explorer-heading", [
          @html.p(class="resident-explorer-eyebrow", "IMPORTED BOOK FILES"),
          @html.h2(id="imported-outputs-title", "Imported outputs"),
          @html.p(
            "Choose a Book, an output and an included file. Read-only; the host verifies every read and download.",
          ),
        ]),
        @html.button(
          class="resident-explorer-close",
          autofocus=true,
          on_click=dispatch(ImportedOutputsEvent(CloseImportedOutputs)),
          attrs=@html.Attrs::build().aria_label("Close imported outputs"),
          "✕",
        ),
      ]),
      @html.div(class="imported-outputs-actions", [
        @html.button(
          class="square-action",
          on_click=dispatch(ImportedOutputsEvent(RefreshImportedOutputs)),
          "Refresh",
        ),
      ]),
      @html.div(class="imported-outputs-body", [
        match state.catalog {
          CatalogIdle =>
            imported_output_status("Choose Refresh to load imported outputs.")
          CatalogLoading =>
            imported_output_status("Loading imported outputs…")
          CatalogUnavailable(message) => imported_output_status(message)
          CatalogReady(catalog) =>
            if catalog.books.is_empty() {
              imported_output_status("No imported Books are available.")
            } else {
              @html.div([
                @html.h3("1 · Book"),
                @html.div(
                  class="imported-outputs-choices",
                  catalog.books.map(book => {
                    @html.button(
                      class="square-action",
                      attrs=@html.Attrs::build().aria_pressed(
                        if state.book_handle == book.handle {
                          "true"
                        } else {
                          "false"
                        },
                      ),
                      on_click=dispatch(
                        ImportedOutputsEvent(ChooseImportedBook(book.handle)),
                      ),
                      book.name + " · " + book.book_id,
                    )
                  }),
                ),
                render_imported_outputs_book(dispatch, state),
              ])
            }
        },
      ]),
    ],
  )
}

///|
fn render_imported_outputs_book(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
) -> @rabbita.Html {
  guard imported_outputs_book(state) is Some(book) else {
    return imported_output_status("Select an imported Book.")
  }
  if book.state != "ready" {
    return imported_output_status(
      if book.state == "unsupported" {
        "Unsupported ordinary import provenance. " + book.message
      } else if book.state == "empty" {
        "No imported outputs. " + book.message
      } else {
        book.message
      },
    )
  }
  @html.div([
    match book.source {
      Some(source) =>
        @html.div(class="imported-outputs-provenance", [
          @html.p("Source: " + source.agent_id + " · " + source.agent_version),
          @html.p("Package SHA-256: " + source.package_sha256),
          @html.p(
            "Outputs manifest: " +
            source.outputs_manifest_digest.unwrap_or("unavailable"),
          ),
        ])
      None => imported_output_status("Import provenance is unavailable.")
    },
    @html.h3("2 · Output"),
    if book.outputs.is_empty() {
      imported_output_status("No imported outputs.")
    } else {
      @html.div(
        class="imported-outputs-choices",
        book.outputs.map(output => {
          @html.button(
            class="square-action",
            attrs=@html.Attrs::build().aria_pressed(
              if state.artifact_id == output.artifact_id {
                "true"
              } else {
                "false"
              },
            ),
            on_click=dispatch(
              ImportedOutputsEvent(ChooseImportedOutput(output.artifact_id)),
            ),
            output.label + " · " + output.artifact_id,
          )
        }),
      )
    },
    render_imported_output_files(dispatch, state),
  ])
}

///|
fn render_imported_output_files(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
) -> @rabbita.Html {
  guard imported_outputs_output(state) is Some(output) else {
    return @html.nothing
  }
  @html.div([
    @html.p("Declared type: " + output.mime_type),
    if !output.included {
      @html.div([
        imported_output_status(
          "Reference-only output. No file content is included or fetched.",
        ),
        @html.p(
          class="imported-outputs-reference",
          output.reference.unwrap_or("No reference provided."),
        ),
      ])
    } else if output.files.is_empty() {
      imported_output_status("This output has no included files.")
    } else {
      @html.div([
        @html.h3("3 · Included file"),
        @html.div(
          class="imported-outputs-choices",
          output.files.map(file => {
            @html.button(
              class="square-action",
              attrs=@html.Attrs::build().aria_pressed(
                if state.selection is Some(selection) &&
                  selection.path == file.path {
                  "true"
                } else {
                  "false"
                },
              ),
              on_click=dispatch(
                ImportedOutputsEvent(ChooseImportedFile(file.path)),
              ),
              file.path + " · " + file.size_bytes.to_string() + " bytes",
            )
          }),
        ),
        render_imported_output_text(dispatch, state),
      ])
    },
  ])
}

///|
fn render_imported_output_text(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
) -> @rabbita.Html {
  guard state.selection is Some(selection) else {
    return imported_output_status("Select an included file.")
  }
  @html.div([
    @html.p(
      class="imported-outputs-provenance",
      "File SHA-256: " + selection.digest,
    ),
    @html.button(
      class="square-action imported-outputs-download",
      on_click=dispatch(ImportedOutputsEvent(DownloadImportedFile)),
      "Download exact file",
    ),
    match state.download {
      DownloadIdle => @html.nothing
      DownloadLoading =>
        imported_output_status("Verifying exact file for download…")
      DownloadReady =>
        imported_output_status(
          "Download prepared. Check your browser’s downloads.",
        )
      DownloadUnavailable(message) => imported_output_status(message)
    },
    match state.text {
      TextIdle => @html.nothing
      TextLoading =>
        imported_output_status("Verifying and loading full text…")
      TextUnavailable(message) => imported_output_status(message)
      TextReady(content) =>
        if content.is_empty() {
          imported_output_status("This is an empty text file (0 bytes).")
        } else {
          // Rabbita creates a text node. Never insert innerHTML, Markdown,
          // iframe content or an active-document preview here.
          @html.pre(
            class="imported-outputs-text",
            attrs=@html.Attrs::build().aria_label("Verified full text"),
            content,
          )
        }
    },
  ])
}
