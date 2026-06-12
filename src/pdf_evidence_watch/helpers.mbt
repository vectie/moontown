///|
fn markdown_bullets(values : Array[String]) -> String {
  values.map(fn(value) { "- \{value}" }).join("\n")
}

///|
fn merge_single_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  book : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id != book.id {
      merged.push(entry)
    }
  }
  merged.push(book)
  merged
}

///|
async fn read_text_or_empty(path : String) -> String {
  if !@fs.exists(path) {
    return ""
  }
  @fs.read_file(path).text() catch {
    _ => ""
  }
}

///|
async fn read_optional_json_file(path : String) -> Json? {
  if !@fs.exists(path) {
    return None
  }
  Some(@json.parse(@fs.read_file(path).text())) catch {
    _ => None
  }
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn write_text_file_if_missing(path : String, content : String) -> Unit {
  let current = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  if current.trim().is_empty() {
    write_text_file(path, content)
  }
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}

///|
async fn workspace_missing_relative_paths(
  root : String,
  relatives : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for relative in relatives {
    let path = "\{root}/\{relative}"
    if !@fs.exists(path) {
      missing.push(relative)
    }
  }
  missing
}

///|
fn standing_goal_registry_upsert(
  goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  let mut seen = false
  for current in goals {
    if current.id == goal.id {
      updated.push(goal)
      seen = true
    } else {
      updated.push(current)
    }
  }
  if !seen {
    updated.push(goal)
  }
  updated
}

///|
fn standing_goal_registry_contains(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  goals.any(fn(goal) { goal.id == goal_id })
}

///|
fn standing_goal_registry_enabled(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  goals.any(fn(goal) { goal.id == goal_id && goal.enabled })
}

///|
fn resolve_book_template_config_relative_path(
  base_dir : String,
  path : String,
) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}

///|
async fn resolve_book_template_config_text_override(
  inline_text : String,
  path : String,
  base_dir : String,
) -> String {
  if !inline_text.trim().is_empty() {
    return inline_text
  }
  if path.trim().is_empty() {
    return ""
  }
  read_text_or_empty(resolve_book_template_config_relative_path(base_dir, path))
}

///|
fn resolve_book_template_config_workspace_root(
  base_dir : String,
  configured_workspace_root : String,
  default_workspace_root : String,
) -> String {
  if configured_workspace_root.trim().is_empty() {
    default_workspace_root
  } else {
    resolve_book_template_config_relative_path(
      base_dir, configured_workspace_root,
    )
  }
}
