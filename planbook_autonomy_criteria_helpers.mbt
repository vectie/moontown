///|
fn planbook_criterion(
  id : String,
  plan_id : String,
  title : String,
  owner : String,
  satisfied : Bool,
  evidence : String,
  next_action : String,
) -> PlanbookCriterionStatus {
  { id, plan_id, title, owner, satisfied, evidence, next_action }
}

///|
async fn text_file_contains(path : String, needle : String) -> Bool {
  if !@fs.exists(path) {
    return false
  }
  let text = @fs.read_file(path).text() catch { _ => return false }
  text.contains(needle)
}
