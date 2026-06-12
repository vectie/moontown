///|
pub fn repair_bridge_summary(
  repaired : Array[BookQualityRepairBridgeItem],
  retired_goal_ids : Array[String],
  existing_repair_goal_ids : Array[String],
) -> String {
  let new_items : Array[BookQualityRepairBridgeItem] = []
  let refreshed_items : Array[BookQualityRepairBridgeItem] = []
  for item in repaired {
    if existing_repair_goal_ids.contains(item.standing_goal_id) {
      refreshed_items.push(item)
    } else {
      new_items.push(item)
    }
  }
  let repair_summary = if repaired.is_empty() {
    "No weak AI semantic book-quality review needed repair bridging."
  } else {
    repair_bridge_action_summary(new_items, refreshed_items)
  }
  if retired_goal_ids.is_empty() {
    repair_summary
  } else {
    "\{repair_summary} Retired \{retired_goal_ids.length()} stale repair goal(s): \{retired_goal_ids.join(", ")}."
  }
}

///|
fn repair_bridge_action_summary(
  new_items : Array[BookQualityRepairBridgeItem],
  refreshed_items : Array[BookQualityRepairBridgeItem],
) -> String {
  let parts : Array[String] = []
  if !new_items.is_empty() {
    let ids = new_items.map(fn(item) { item.book_id }).join(", ")
    parts.push(
      "Queued \{new_items.length()} new weak AI semantic book-quality repair(s): \{ids}.",
    )
  }
  if !refreshed_items.is_empty() {
    let ids = refreshed_items.map(fn(item) { item.book_id }).join(", ")
    parts.push(
      "Refreshed \{refreshed_items.length()} existing weak AI semantic book-quality repair(s): \{ids}.",
    )
  }
  parts.join(" ")
}
