///|
async fn ignore_checked_command(command : String, args : Array[String]) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}
