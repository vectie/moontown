///|
pub fn miniapp_accept_run_as_memory(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappBookMemoryDraft,
  now_ms~ : UInt64,
) -> MiniappBookChange {
  match miniapp_run_by_id(snapshot, draft.run_id) {
    None =>
      miniapp_book_reject(snapshot, "", "", Some(draft.run_id), "run not found")
    Some(run) =>
      match miniapp_book_building_by_id(snapshot, run.building_id) {
        None =>
          miniapp_book_reject(
            snapshot,
            run.building_id,
            run.book_id,
            Some(run.id),
            "building not found",
          )
        Some(building) =>
          if !(@miniapp_projection.miniapp_can_edit_building(viewer, building) ||
            @miniapp_projection.miniapp_viewer_can_publish(viewer)) {
            miniapp_book_reject(
              snapshot,
              building.id,
              run.book_id,
              Some(run.id),
              "viewer cannot accept memory",
            )
          } else {
            match miniapp_book_by_id(snapshot, run.book_id) {
              None =>
                miniapp_book_reject(
                  snapshot,
                  building.id,
                  run.book_id,
                  Some(run.id),
                  "book not found",
                )
              Some(book) => {
                let next_pending = if book.pending_review_count > 0 {
                  book.pending_review_count - 1
                } else {
                  0
                }
                let next_book = {
                  ..book,
                  summary: draft.accepted_summary,
                  accepted_memory_count: book.accepted_memory_count + 1,
                  pending_review_count: next_pending,
                  version: book.version + 1,
                }
                let next_run = {
                  ..run,
                  status: @miniapp_contracts.RunDone,
                  summary: "accepted memory: \{draft.accepted_summary}",
                  updated_at_ms: now_ms,
                  version: run.version + 1,
                }
                miniapp_book_accept(
                  {
                    ..snapshot,
                    books: miniapp_replace_book(snapshot.books, next_book),
                    runs: miniapp_replace_run(snapshot.runs, next_run),
                    version: snapshot.version + 1,
                  },
                  building.id,
                  book.id,
                  Some(run.id),
                  "run accepted as book memory",
                )
              }
            }
          }
      }
  }
}
