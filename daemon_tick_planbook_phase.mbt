///|
async fn run_daemon_planbook_phase(
  snapshot_path : String,
  book_catalog_path : String,
) -> DaemonPlanbookPhaseResult {
  let planbook_summary = write_moontown_planbook_autonomy(
    snapshot_path~,
    book_catalog_path~,
  )
  {
    planbook_summary,
    repair_summary: ensure_daemon_planbook_repair_task(
      snapshot_path, book_catalog_path,
    ),
  }
}

///|
async fn ensure_daemon_planbook_repair_task(
  snapshot_path : String,
  book_catalog_path : String,
) -> String {
  if planbook_repair_active_count(snapshot_path~) == 0 {
    write_moontown_planbook_repair_task(
      snapshot_path~,
      book_catalog_path~,
      dispatch=true,
      run_inline=false,
    )
  } else {
    daemon_planbook_repair_duplicate_message()
  }
}

///|
fn daemon_planbook_repair_duplicate_message() -> String {
  "PlanBook repair already active; daemon did not create a duplicate repair task."
}
