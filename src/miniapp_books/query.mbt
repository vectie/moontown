///|
pub fn miniapp_record_building_query(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappBuildingQueryDraft,
  now_ms~ : UInt64,
) -> MiniappBookChange {
  match miniapp_book_building_by_id(snapshot, draft.building_id) {
    None =>
      miniapp_book_reject(
        snapshot,
        draft.building_id,
        "",
        Some(draft.run_id),
        "building not found",
      )
    Some(building) =>
      if !@miniapp_projection.miniapp_can_view_building(viewer, building) {
        miniapp_book_reject(
          snapshot,
          draft.building_id,
          building.primary_book_id,
          Some(draft.run_id),
          "viewer cannot query building",
        )
      } else {
        match miniapp_book_by_id(snapshot, building.primary_book_id) {
          None =>
            miniapp_book_reject(
              snapshot,
              draft.building_id,
              building.primary_book_id,
              Some(draft.run_id),
              "primary book not found",
            )
          Some(book) => {
            let thread = miniapp_thread_for_query(snapshot, building, draft)
            let run : @miniapp_contracts.MiniappRun = {
              id: draft.run_id,
              user_id: viewer.user_id,
              building_id: building.id,
              book_id: book.id,
              agent_id: draft.agent_id,
              thread_id: draft.thread_id,
              status: @miniapp_contracts.RunWaitingReview,
              summary: draft.question_summary,
              created_at_ms: now_ms,
              updated_at_ms: now_ms,
              version: 1,
            }
            miniapp_book_accept(
              {
                ..snapshot,
                books: miniapp_replace_book(snapshot.books, {
                  ..book,
                  pending_review_count: book.pending_review_count + 1,
                }),
                threads: miniapp_replace_thread(snapshot.threads, thread),
                runs: snapshot.runs + [run],
                version: snapshot.version + 1,
              },
              building.id,
              book.id,
              Some(run.id),
              "building query recorded",
            )
          }
        }
      }
  }
}

///|
fn miniapp_thread_for_query(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building : @miniapp_contracts.MiniappBuilding,
  draft : MiniappBuildingQueryDraft,
) -> @miniapp_contracts.MiniappThread {
  match miniapp_thread_by_id(snapshot, draft.thread_id) {
    Some(thread) =>
      {
        ..thread,
        message_count: thread.message_count + 1,
        version: thread.version + 1,
      }
    None =>
      {
        id: draft.thread_id,
        building_id: building.id,
        title: "\{building.title} query",
        message_count: 1,
        unread_count: 0,
        version: 1,
      }
  }
}
