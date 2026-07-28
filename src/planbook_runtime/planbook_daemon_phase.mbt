///|
pub struct PlanbookDaemonPhaseResult {
  planbook_summary : String
  repair_summary : String
}

///|
pub async fn run_planbook_daemon_phase(
  snapshot_path : String,
  book_catalog_path : String,
  dispatch_repair? : Bool = true,
) -> PlanbookDaemonPhaseResult {
  let planbook_summary = write_moontown_planbook_autonomy(
    snapshot_path~,
    book_catalog_path~,
  )
  {
    planbook_summary,
    repair_summary: if dispatch_repair {
      ensure_planbook_daemon_repair_task(snapshot_path, book_catalog_path)
    } else {
      planbook_daemon_repair_deferred_for_live_work_message()
    },
  }
}

///|
async fn ensure_planbook_daemon_repair_task(
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
    planbook_daemon_repair_duplicate_message()
  }
}

///|
pub fn planbook_daemon_repair_duplicate_message() -> String {
  "PlanBook repair already active; daemon did not create a duplicate repair task."
}

///|
pub fn planbook_daemon_repair_deferred_for_live_work_message() -> String {
  "PlanBook repair dispatch deferred while another external execution is live; this avoids concurrent MoonClaw run-id races."
}
