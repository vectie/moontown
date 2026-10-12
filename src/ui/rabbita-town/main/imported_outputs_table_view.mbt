///|
priv struct TableViewState {
  column : Int
  exact : Bool
  sort_column : Int
  descending : Bool
  columns : Array[Int]?
} derive(Debug, Eq)

///|
priv enum TableViewMsg {
  FilterColumn(String)
  MatchMode(Bool)
  SortColumn(String)
  SortDescending(Bool)
  ToggleColumn(Int)
  Reset
}

///|
fn initial_table_view() -> TableViewState {
  {
    column: -1,
    exact: false,
    sort_column: -1,
    descending: false,
    columns: None,
  }
}

///|
fn imported_table_view_columns(
  state : ImportedOutputsState,
  table : @imported_output_contract.DataTable,
) -> Array[Int] {
  state.table_view.columns.unwrap_or_else(() => table.headers.mapi((i, _) => i))
}

///|
fn imported_table_view_rows(
  state : ImportedOutputsState,
  table : @imported_output_contract.DataTable,
) -> Array[Int] {
  let view = state.table_view
  table
  .view_rows(
    state.table_query,
    column?=if view.column == -1 { None } else { Some(view.column) },
    exact=view.exact,
    sort_column?=if view.sort_column == -1 {
      None
    } else {
      Some(view.sort_column)
    },
    descending=view.descending,
  )
  .unwrap_or([])
}

///|
fn table_view_transition(
  state : ImportedOutputsState,
  message : TableViewMsg,
) -> (ImportedOutputsState, ImportedOutputsRequest?) {
  guard state.open && state.table is Some(Ok(table)) else {
    return (state, None)
  }
  let view = state.table_view
  let next = match message {
    FilterColumn(value) | SortColumn(value) => {
      let column = if value == "" {
        -1
      } else {
        match
          table.headers.mapi((i, _) => i).filter(i => i.to_string() == value) {
          [i] => i
          _ => return (state, None)
        }
      }
      if message is FilterColumn(_) {
        { ..view, column, }
      } else {
        { ..view, sort_column: column, }
      }
    }
    MatchMode(exact) => { ..view, exact, }
    SortDescending(descending) => { ..view, descending, }
    ToggleColumn(column) => {
      if column < 0 || column >= table.headers.length() {
        return (state, None)
      }
      let current = imported_table_view_columns(state, table)
      let columns = if current.contains(column) {
        current.filter(c => c != column)
      } else {
        table.headers
        .mapi((i, _) => i)
        .filter(c => c == column || current.contains(c))
      }
      { ..view, columns: Some(columns), }
    }
    Reset =>
      return (
        {
          ..state,
          table_query: "",
          table_page: 0,
          table_view: initial_table_view(),
        },
        None,
      )
  }
  ({ ..state, table_page: 0, table_view: next, }, None)
}

///|
fn render_table_view_controls(
  dispatch : Dispatch[Msg],
  state : ImportedOutputsState,
  table : @imported_output_contract.DataTable,
) -> @rabbita.Html {
  let view = state.table_view
  let columns = imported_table_view_columns(state, table)
  @html.section([
    @html.h4("Column filter, sort and export fields"),
    @html.p(
      "Search and sort use ASCII-only case folding: A/a match, but é/É stay distinct. Exact match with an empty search finds blank cells. Sort uses UTF-16 text order, not numeric, date or locale order; ties keep source order.",
    ),
    @html.div(
      [false, true].map(sort => {
        let id = if sort { "table-sort-column" } else { "table-filter-column" }
        let chosen = if sort { view.sort_column } else { view.column }
        @html.div([
          @html.label(
            for_=id,
            if sort {
              "Sort by column"
            } else {
              "Search in column"
            },
          ),
          @html.select(
            id~,
            class="request-input",
            on_change=value => {
              dispatch(
                ImportedOutputsEvent(
                  TableViewEvent(
                    if sort {
                      SortColumn(value)
                    } else {
                      FilterColumn(value)
                    },
                  ),
                ),
              )
            },
            [
              @html.option(
                value="",
                selected=chosen == -1,
                if sort {
                  "Source row order"
                } else {
                  "All columns"
                },
              ),
            ] +
            table.headers.mapi((i, title) => {
              @html.option(
                value=i.to_string(),
                selected=chosen == i,
                (i + 1).to_string() +
                ": " +
                (if title.is_empty() { "(empty header)" } else { title }),
              )
            }),
          ),
        ])
      }),
    ),
    @html.div(class="imported-outputs-actions", [
      @html.button(
        class="square-action",
        on_click=dispatch(
          ImportedOutputsEvent(TableViewEvent(MatchMode(!view.exact))),
        ),
        attrs=@html.Attrs::build().aria_pressed(
          if view.exact {
            "true"
          } else {
            "false"
          },
        ),
        if view.exact {
          "Exact match: on"
        } else {
          "Exact match: off"
        },
      ),
      @html.button(
        class="square-action",
        on_click=dispatch(
          ImportedOutputsEvent(TableViewEvent(SortDescending(!view.descending))),
        ),
        attrs=@html.Attrs::build().aria_pressed(
          if view.descending {
            "true"
          } else {
            "false"
          },
        ),
        if view.descending {
          "Sort descending"
        } else {
          "Sort ascending"
        },
      ),
      @html.button(
        class="square-action",
        on_click=dispatch(
          ImportedOutputsEvent(TableViewEvent(TableViewMsg::Reset)),
        ),
        "Reset table view",
      ),
    ]),
    @html.p("Visible/exported columns (source data row is always included):"),
    @html.div(
      class="imported-outputs-actions",
      table.headers.mapi((i, title) => {
        @html.button(
          class="square-action",
          on_click=dispatch(
            ImportedOutputsEvent(TableViewEvent(ToggleColumn(i))),
          ),
          attrs=@html.Attrs::build().aria_pressed(
            if columns.contains(i) {
              "true"
            } else {
              "false"
            },
          ),
          (if columns.contains(i) { "Included " } else { "Omitted " }) +
          (i + 1).to_string() +
          ": " +
          (if title.is_empty() { "(empty header)" } else { title }),
        )
      }),
    ),
    if columns.is_empty() {
      imported_output_status("Choose at least one output column to download.")
    } else {
      @html.nothing
    },
  ])
}
