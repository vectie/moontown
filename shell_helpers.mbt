///|
async fn ignore_checked_command(command : String, args : Array[String]) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}

///|
fn path_basename(path : String) -> String {
  let parts = path.split("/").to_array()
  match parts.get(parts.length() - 1) {
    Some(part) => part.to_owned()
    None => path
  }
}
