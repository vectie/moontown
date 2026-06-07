///|
async fn has_external_topic_runtime_entity_contamination(root : String) -> Bool {
  for name in ["moonclaw", "moonbook", "moontown"] {
    if @fs.exists("\{root}/wiki/entities/\{name}.md") {
      return true
    }
  }
  false
}

///|
async fn directory_has_topic_named_page(
  root : String,
  relative_dir : String,
  aliases : Array[String],
) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/\{relative_dir}",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let lower_name = path_basename(file.to_owned()).to_lower()
    for page_alias in aliases {
      if lower_name.contains(page_alias) {
        return true
      }
    }
  }
  false
}

///|
async fn directory_has_topic_source_page(
  root : String,
  aliases : Array[String],
) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/wiki/sources",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let lower_name = path_basename(file.to_owned()).to_lower()
    let lower_content = @fs.read_file(file).text().to_lower() catch { _ => "" }
    for page_alias in aliases {
      if lower_name.contains(page_alias) || lower_content.contains(page_alias) {
        return true
      }
    }
  }
  false
}

///|
async fn has_research_source_marker(root : String) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/wiki/sources",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let content = @fs.read_file(file).text() catch { _ => continue }
    if content.contains("Source type: verified source digest") ||
      content.contains("Evidence Matrix") ||
      content.contains("Claim ID") {
      return true
    }
  }
  false
}
