///|
fn render_imported_data_content(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
  content : String,
) -> @rabbita.Html {
  if state.geo.features is Some(_) && state.table is None {
    return render_imported_geo(dispatch, state, content)
  }
  if state.agenda.events is Some(_) {
    return render_imported_agenda(dispatch, state, content)
  }
  let controls = match state.table {
    Some(Ok(_)) =>
      @html.div(class="imported-outputs-actions", [
        @html.button(
          class="square-action",
          on_click=dispatch(ImportedOutputsEvent(ShowImportedTable(true))),
          attrs=@html.Attrs::build().aria_pressed(
            if state.table_show {
              "true"
            } else {
              "false"
            },
          ),
          "Table view",
        ),
        @html.button(
          class="square-action",
          on_click=dispatch(ImportedOutputsEvent(ShowImportedTable(false))),
          attrs=@html.Attrs::build().aria_pressed(
            if state.table_show {
              "false"
            } else {
              "true"
            },
          ),
          "Raw text",
        ),
      ])
    Some(Err(message)) =>
      imported_output_status(
        "Table view unavailable: " + message + ". Raw text remains below.",
      )
    None => @html.nothing
  }
  @html.div([
    controls,
    match state.table {
      Some(Ok(table)) => render_places_mapping(dispatch, state, table)
      _ => @html.nothing
    },
    match state.table {
      Some(Ok(_)) if state.places.show =>
        render_imported_geo(dispatch, state, content)
      Some(Ok(table)) if state.table_show =>
        render_imported_data_table(dispatch, state, table)
      _ =>
        if content.is_empty() {
          imported_output_status("This is an empty text file (0 bytes).")
        } else {
          // Both views create only escaped text nodes, never active content.
          @html.pre(
            class="imported-outputs-text",
            attrs=@html.Attrs::build().aria_label("Verified full text"),
            content,
          )
        }
    },
  ])
}

///|
fn render_imported_data_table(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
  table : @imported_output_contract.DataTable,
) -> @rabbita.Html {
  let matches = imported_table_view_rows(state, table)
  let columns = imported_table_view_columns(state, table)
  let start = (state.table_page * 25).min(matches.length())
  let end = (start + 25).min(matches.length())
  let visible = matches[start:end].to_owned()
  @html.section(class="imported-data-table", [
    @html.h3("Explore table"),
    @html.p(
      "First record is the header. Values stay text; source data-row numbers remain attached when sorting and filtering.",
    ),
    @html.label(for_="imported-table-search", "Search text"),
    @html.input(
      id="imported-table-search",
      class="request-input",
      value=state.table_query,
      placeholder="Filter rows by text…",
      on_input=query => {
        dispatch(ImportedOutputsEvent(SearchImportedTable(query)))
      },
    ),
    render_table_view_controls(dispatch, state, table),
    imported_output_status(
      matches.length().to_string() +
      " of " +
      table.rows.length().to_string() +
      " data rows · " +
      columns.length().to_string() +
      " of " +
      table.headers.length().to_string() +
      " columns included",
    ),
    @html.div(class="imported-outputs-actions", [
      @html.button(
        class="square-action",
        attrs=@html.Attrs::build().disabled(state.table_page == 0),
        on_click=dispatch(
          ImportedOutputsEvent(PageImportedTable(state.table_page - 1)),
        ),
        "Previous rows",
      ),
      @html.button(
        class="square-action",
        attrs=@html.Attrs::build().disabled(end >= matches.length()),
        on_click=dispatch(
          ImportedOutputsEvent(PageImportedTable(state.table_page + 1)),
        ),
        "Next rows",
      ),
      @html.button(
        class="square-action",
        attrs=@html.Attrs::build().disabled(columns.is_empty()),
        on_click=dispatch(ImportedOutputsEvent(DownloadFilteredTable)),
        "Download matching rows (.csv)",
      ),
    ]),
    @html.p(
      "Derived CSV includes every matching row in this sort order, only included columns, and a first source_data_row provenance column. Formula-leading cells are prefixed by an apostrophe for spreadsheet safety. Exact file download preserves all original bytes.",
    ),
    if matches.is_empty() {
      imported_output_status(
        if table.rows.is_empty() {
          "This file contains headers only."
        } else {
          "No rows match this search."
        },
      )
    } else {
      @html.div(style=["overflow:auto", "max-height:28rem"], [
        @html.table(style=["border-collapse:collapse", "width:100%"], [
          @html.caption(
            "Matching rows " +
            (start + 1).to_string() +
            "–" +
            end.to_string() +
            " of " +
            matches.length().to_string(),
          ),
          @html.thead(
            @html.tr(
              [@html.th("Source row")] +
              columns.map(index => {
                let title = table.headers[index]
                @html.th(
                  style=[
                    "text-align:left", "padding:8px", "border-bottom:1px solid #ccd5dc",
                  ],
                  if title.is_empty() {
                    "Column " + (index + 1).to_string()
                  } else {
                    title
                  },
                )
              }),
            ),
          ),
          @html.tbody(
            visible.map(index => {
              @html.tr(
                [@html.th((index + 1).to_string())] +
                columns.map(column => {
                  let cell = table.rows[index][column]
                  @html.td(
                    style=[
                      "padding:8px", "border-bottom:1px solid #e4e8ec", "white-space:pre-wrap",
                      "overflow-wrap:anywhere", "min-width:5rem", "max-width:24rem",
                    ],
                    cell,
                  )
                }),
              )
            }),
          ),
        ]),
      ])
    },
  ])
}
