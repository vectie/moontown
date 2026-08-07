///|
/// Runtime summaries and activity labels can contain command output or local
/// artifact paths. Those values are useful in the durable ledger, but must not
/// be copied verbatim into browser-facing narrative surfaces.
fn energy_valley_runtime_copy_contains_local_path(value : String) -> Bool {
  let lower = value.to_lower()
  if lower.contains("file://") ||
    lower.contains("~/") ||
    lower.contains("$home/") ||
    lower.contains("/users/") ||
    lower.contains("/home/") ||
    lower.contains("/tmp/") ||
    lower.contains("/private/") ||
    lower.contains("/var/") ||
    lower.contains("/etc/") ||
    lower.contains("/opt/") ||
    lower.contains("/volumes/") ||
    value.contains("\\") {
    return true
  }
  let words = lower
    .replace(old="\n", new=" ")
    .replace(old="\r", new=" ")
    .replace(old="\t", new=" ")
  for word in words.split(" ") {
    let token = word
      .to_owned()
      .trim(chars="()[]{}<>,;:'\"（）【】《》，；：")
      .to_owned()
    let candidate = match token.split_once("=") {
      Some((_, path)) => path.to_owned()
      None => token
    }
    if candidate.has_prefix("/") && !candidate.has_prefix("/book-output/") {
      return true
    }
  }
  false
}

///|
/// Return compact, browser-safe runtime prose. The caller supplies copy that
/// explains why a path-bearing or excessively long value was withheld.
fn energy_valley_safe_runtime_copy(
  value : String,
  hidden_copy : String,
  limit : Int,
) -> String {
  if energy_valley_runtime_copy_contains_local_path(value) ||
    value.length() > limit {
    hidden_copy
  } else {
    compact_single_line(value, limit~)
  }
}
