///|
/// Saved opt-in plan used by both watch setup and the existing durable cycle.
pub(all) struct Plan {
  contract : String
  goal_id : String
  book_id : String
  intent : String
  acceptance : String
  next_action : String
  sources : Array[String]
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct Source {
  path : String
  sha256 : String
  content : String
} derive(Eq, ToJson, FromJson)

///|
/// ```mbt check
/// test {
///   assert_true(relative_path("sources/customer.txt"))
///   assert_false(relative_path("../outside.txt"))
/// }
/// ```
pub fn relative_path(path : String) -> Bool {
  !path.is_empty() &&
  !path.has_prefix("/") &&
  !path.contains("\\") &&
  !path.contains("\n") &&
  !path.contains("\r") &&
  path.split("/").all(part => part != ".." && part != "." && !part.is_empty())
}

///|
/// Reject paths outside the owning Book, including symlink escapes.
async fn resolve_existing_path(
  entry : @moonbook.BookCatalogEntry,
  relative : String,
) -> String {
  guard relative_path(relative) else {
    fail("Material-watch paths must be Book-relative")
  }
  let root = @fs.realpath(@moonbook.workspace_root(entry))
  let resolved = @fs.realpath(root + "/" + relative)
  guard resolved.has_prefix(root + "/") && @fs.kind(resolved) == Regular else {
    fail(
      "Material-watch source must be a file inside its owning Book: " + relative,
    )
  }
  resolved
}

///|
pub fn validate(
  plan : Plan,
  entry : @moonbook.BookCatalogEntry,
  goal : @core.StandingGoal,
) -> Plan raise {
  guard plan.contract == "moontown.material_watch_plan.v1" &&
    plan.goal_id == goal.id &&
    plan.book_id == entry.id &&
    goal.target_book_id == Some(entry.id) &&
    !plan.intent.trim().is_empty() &&
    !plan.acceptance.trim().is_empty() &&
    !plan.next_action.trim().is_empty() &&
    !plan.sources.is_empty() else {
    fail(
      "Material-watch plan needs matching goal/book, intent, acceptance, next action and sources",
    )
  }
  let seen : Map[String, Bool] = Map([])
  for source in plan.sources {
    guard relative_path(source) && !seen.contains(source) else {
      fail("Material-watch source paths must be unique and Book-relative")
    }
    seen[source] = true
  }
  let sources = plan.sources.copy()
  sources.sort()
  { ..plan, sources, }
}

///|
pub async fn read_plan(
  entry : @moonbook.BookCatalogEntry,
  goal : @core.StandingGoal,
  relative : String,
) -> Plan {
  let path = resolve_existing_path(entry, relative)
  let plan : Plan = @json.from_json(@json.parse(@fs.read_file(path).text()))
  validate(plan, entry, goal)
}

///|
pub async fn read_sources(
  entry : @moonbook.BookCatalogEntry,
  plan : Plan,
) -> Array[Source] {
  let paths = plan.sources.copy()
  paths.sort()
  let sources = []
  for path in paths {
    let resolved = resolve_existing_path(entry, path)
    let bytes = @fs.read_file(resolved).binary()
    let content = @utf8.decode(bytes)
    guard @utf8.encode(content) == bytes else {
      fail("Material-watch source is not lossless UTF-8: " + path)
    }
    sources.push({
      path,
      sha256: @crypto.bytes_to_hex_string(@crypto.sha256(bytes)),
      content,
    })
  }
  sources
}
