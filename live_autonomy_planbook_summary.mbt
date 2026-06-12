///|
async fn latest_planbook_change_summary(path : String) -> String {
  let text = @support.read_text_or_empty(path)
  if text.trim().is_empty() {
    return "No PlanBook change log is available yet."
  }
  let sections = text.split("## ")
  let mut latest = ""
  for section in sections {
    let trimmed = section.trim()
    if trimmed != "" && !trimmed.has_prefix("# PlanBook") {
      latest = trimmed.to_owned()
    }
  }
  if latest == "" {
    "PlanBook change log exists but has no event entries yet."
  } else {
    latest
  }
}

///|
fn normalized_planbook_latest_change_summary(
  latest : String,
  planbook_open : Int,
  planbook_repair_active : Int,
) -> String {
  if planbook_open == 0 &&
    planbook_repair_active == 0 &&
    (
      latest.contains("repair task running") ||
      latest.contains("repair task dispatched") ||
      latest.contains("repair task blocked")
    ) {
    "PlanBook is stable: no open self-build gap and no active repair remains. Latest repair log entry is historical."
  } else {
    latest
  }
}
