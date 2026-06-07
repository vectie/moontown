///|
fn contains_process_heavy_research_text(lower : String) -> Bool {
  if lower.contains("pending enrichment") ||
    lower.contains("provisional-only") ||
    lower.contains("placeholder notes") ||
    lower.contains("placeholder output") ||
    lower.contains("placeholder-only") ||
    lower.contains("unable to access") ||
    lower.contains("i could not") {
    return true
  }
  let mut process_markers = 0
  if lower.contains("this run") {
    process_markers += 1
  }
  if lower.contains("the worker failed") ||
    lower.contains("the worker could not") ||
    lower.contains("worker log") {
    process_markers += 1
  }
  if lower.contains("tool output") {
    process_markers += 1
  }
  process_markers >= 2
}
