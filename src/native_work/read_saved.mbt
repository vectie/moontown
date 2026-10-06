///|
/// Observe an already existing atomic owner snapshot with the same validation
/// as load, without initializing a directory, state file, or lock file. Callers
/// combining it with other owner records must check that their snapshot has not
/// changed before projecting a decision.
///
/// ```mbt check
/// test {
///   let observe = async fn(path : String) { @native_work.read_saved(path~) }
///   ignore(observe)
/// }
/// ```
pub async fn read_saved(path? : String = default_path()) -> State {
  guard @fs.exists(path) else { fail("native_work_saved_state_missing") }
  load_unlocked(path)
}
