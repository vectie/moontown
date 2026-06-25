///|
async fn reconcile_mooncode_book_result_sidecar_imports(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  for entry in catalog {
    let imports = @moonbook.reconcile_mooncode_book_result_sidecars(entry) catch {
      error => {
        state.record_event(
          @core.TownEvent::new(
            id="event-mooncode-sidecar-\{entry.id}-error-\{state.events.length()}",
            kind="error",
            detail="MoonCode book-result sidecar reconciliation failed for \{entry.id}: \{error}",
            related_book_id=Some(entry.id),
          ),
        )
        continue
      }
    }
    for imported in imports {
      record_mooncode_book_result_import(state, entry, imported)
    }
  }
}

///|
fn record_mooncode_book_result_import(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  imported : @moonbook.MoonCodeBookResultImport,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-mooncode-sidecar-\{entry.id}-\{imported.result_id}-\{state.events.length()}",
      kind="book.mooncode_sidecar_persisted",
      detail="MoonCode sidecar persisted into \{entry.id}: result=\{imported.result_id} session=\{imported.session_id} command=\{imported.command_id} pages=\{imported.updated_pages.length()} review=\{imported.review_queued} evidence=\{imported.evidence_id} event=\{imported.executable_event_path}",
      related_book_id=Some(entry.id),
      related_task_id=Some(imported.result_id),
      related_run_id=Some(imported.session_id),
    ),
  )
  let route = imported.executable_event.route_to_town(state.events.length())
  if route.notify_operator {
    state.record_event(route.town_event)
  }
}
