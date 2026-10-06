///|
priv struct Root {
  path : String
  name : String
}

///|
fn book_id(root : String) -> String {
  root.split("/").last().unwrap_or("").to_owned()
}

///|
fn handle(root : String) -> String {
  "book-" + @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(root)))
}

///|
async fn actual_name(root : String, fallback : String) -> String {
  let text = @utf8.decode(bounded_bytes(root, "book.toml", 65536)) catch {
    _ => return fallback
  }
  let mut in_book = false
  for raw in text.split("\n") {
    let line = raw.trim()
    if line.has_prefix("[") {
      in_book = line == "[book]"
      continue
    }
    if in_book &&
      line.split_once("=") is Some((key, value)) &&
      key.trim() == "title" {
      let title = value.trim().to_owned()
      if title.has_prefix("\"") {
        if (@json.parse(title) catch { _ => Json::null() }) is String(name) &&
          !name.trim().is_empty() {
          return name
        }
      } else if title.length() > 2 &&
        title.has_prefix("'") &&
        title.has_suffix("'") &&
        !title[1:title.length() - 1].trim().is_empty() {
        return title[1:title.length() - 1].to_owned()
      }
    }
  }
  fallback
}

///|
async fn roots(
  catalog_path : String,
  books_root : String,
) -> (Array[Root], Bool) {
  let result : Array[Root] = []
  let seen : Map[String, Unit] = Map([])
  let mut unavailable = false
  if present(catalog_path) {
    try {
      let catalog = @json.parse(
        @utf8.decode(bounded_absolute(catalog_path, 1024 * 1024)),
      )
      guard catalog is Array(entries) && entries.length() <= 256 else {
        fail("Invalid Book catalog")
      }
      for entry in entries {
        guard entry is { "workspace_root": String(path), .. } &&
          absolute_path_valid(path) else {
          fail("Invalid catalog workspace root")
        }
        if !seen.contains(path) {
          let name = match entry {
            { "name": String(name), .. } => name
            _ => book_id(path)
          }
          result.push({ path, name, })
          seen[path] = ()
        }
      }
    } catch {
      _ => unavailable = true
    }
  }
  if present(books_root) {
    try {
      check_path(books_root, directory=true)
      let directory = @fs.opendir(books_root)
      defer directory.close()
      let mut count = 0
      while directory.next() is Some(entry) {
        count += 1
        guard count <= 4096 else { fail("Too many Book directory entries") }
        let path = books_root + "/" + entry.name
        if !entry.is_dir || seen.contains(path) {
          continue
        }
        // Only existing Book roots with known import provenance are discovered.
        if present(path + "/book.toml") &&
          (
            present(path + "/state/portable-source-binding.json") ||
            present(path + "/state/agent-installation.json")
          ) {
          guard result.length() < 256 else { fail("Too many imported Books") }
          result.push({ path, name: entry.name, })
          seen[path] = ()
        }
      }
    } catch {
      _ => unavailable = true
    }
  }
  result.sort_by((a, b) => a.path.compare(b.path))
  (result, unavailable)
}

///|
async fn inspect_book(root : Root) -> @contract.Book? {
  let exact = present(root.path + "/state/portable-source-binding.json")
  let ordinary = present(root.path + "/state/agent-installation.json")
  guard exact || ordinary else { return None }
  let id = book_id(root.path)
  let base : @contract.Book = {
    handle: handle(root.path),
    book_id: id,
    name: actual_name(root.path, root.name),
    state: "unavailable",
    message: "Exact-import provenance or manifest is unavailable or changed. No members have been opened.",
    source: None,
    outputs: [],
  }
  try {
    check_path(root.path, directory=true)
    ignore(bounded_bytes(root.path, "book.toml", 65536))
    if !exact {
      return Some({
        ..base,
        state: "unsupported",
        message: "This ordinary agent installation has no exact portable-source receipt. Its provenance is unsupported by this viewer.",
      })
    }
    let (source, outputs) = exact_outputs(root.path, id)
    Some({
      ..base,
      state: if outputs.is_empty() {
        "empty"
      } else {
        "ready"
      },
      message: if outputs.is_empty() {
        "This exact import contains no declared outputs."
      } else {
        "Original import source and manifest matched. Each member is verified again when opened; imported content is never executed."
      },
      source: Some(source),
      outputs,
    })
  } catch {
    _ => Some(base)
  }
}

///|
pub async fn discover(
  catalog_path : String,
  books_root : String,
) -> @contract.Catalog {
  let (candidates, unavailable) = roots(catalog_path, books_root)
  let books : Array[@contract.Book] = []
  let mut total_wire = 4096
  for root in candidates {
    if inspect_book(root) is Some(book) {
      total_wire += @utf8.encode(book.to_json().stringify()).length() + 1
      if total_wire > @contract.catalog_wire_limit() {
        return {
          contract: "moontown.imported_outputs.v1",
          state: "unavailable",
          message: "Imported-output catalog exceeds the 4 MiB response policy. No partial member list is shown.",
          books: [],
        }
      }
      books.push(book)
    }
  }
  {
    contract: "moontown.imported_outputs.v1",
    state: if !books.is_empty() {
      "ready"
    } else if unavailable {
      "unavailable"
    } else {
      "empty"
    },
    message: if unavailable {
      "Some existing catalog or Book roots could not be read safely. Available imports are shown below."
    } else if books.is_empty() {
      "No existing imported Books were found in the Book catalog or active Books folder."
    } else {
      "Read-only imported outputs. Source identity is from the retained exact-import receipt, not a publisher signature or a new package verification."
    },
    books,
  }
}
