///|
priv struct SourceScan {
  paths : Array[String]
  mut scanned : Int
  mut excluded : Int
  mut unreadable : Int
  mut truncated : Bool
}

///|
async fn scan_sources(
  root : String,
  relative : String,
  depth : Int,
  scan : SourceScan,
) -> Unit {
  if depth > 8 || scan.scanned >= 2048 || scan.paths.length() >= 256 {
    scan.truncated = true
    return
  }
  let full = if relative.is_empty() { root } else { root + "/" + relative }
  // Recheck every parent each time: directory entries themselves are untrusted.
  directory(full, false)
  let dir = @fs.opendir(full)
  defer dir.close()
  for ;; {
    if scan.scanned >= 2048 || scan.paths.length() >= 256 {
      scan.truncated = true
      break
    }
    guard dir.next(include_hidden=true) is Some(entry) else { break }
    scan.scanned += 1
    let path = if relative.is_empty() {
      entry.name
    } else {
      relative + "/" + entry.name
    }
    if !@contract.safe_source_path(path) {
      scan.excluded += 1
      continue
    }
    try {
      let absolute = root + "/" + path
      match kind(absolute) {
        Some(Directory) => scan_sources(root, path, depth + 1, scan)
        Some(Regular) => {
          directory(full, false)
          let file = @fs.open(absolute, mode=ReadOnly)
          defer file.close()
          let size = file.size()
          if file.kind() == Regular &&
            kind(absolute) is Some(Regular) &&
            size >= 0L &&
            size <= 1048576L {
            scan.paths.push(path)
          } else {
            scan.excluded += 1
          }
        }
        _ => scan.excluded += 1
      }
    } catch {
      _ => scan.unreadable += 1
    }
  }
}

///|
/// Read-only, bounded metadata observation through a registered Book ID.
/// No content is captured until the independent explicit save operation.
pub async fn Store::list_sources(
  self : Store,
  book_id : String,
) -> @contract.SourceListing {
  guard @contract.safe_id(book_id) else {
    raise CollaborationError("Invalid Book ID")
  }
  let catalog = @moonbook.load_catalog_file(self.catalog_path).unwrap_or([])
  guard @moonbook.find_catalog_entry(catalog, book_id) is Some(book) else {
    raise CollaborationError("Selected Book is not in the existing catalog")
  }
  directory(book.workspace_root, false)
  let scan : SourceScan = {
    paths: [],
    scanned: 0,
    excluded: 0,
    unreadable: 0,
    truncated: false,
  }
  scan_sources(book.workspace_root, "", 0, scan) catch {
    _ => scan.unreadable += 1
  }
  scan.paths.sort()
  {
    book_id,
    paths: scan.paths,
    scanned_entries: scan.scanned,
    excluded_entries: scan.excluded,
    unreadable_entries: scan.unreadable,
    truncated: scan.truncated,
    detail: "Live paths only; nothing captured. Save rechecks current registered roots and bytes. " +
    "At most 256 files, 2048 entries, 8 nested levels; each file at most 1 MiB. " +
    (if scan.truncated {
      "Listing truncated; search filters only these observed paths. "
    } else {
      "Search filters these observed paths. "
    }) +
    scan.excluded.to_string() +
    " hidden, unsafe, nonregular or oversized entries excluded; " +
    scan.unreadable.to_string() +
    " unreadable entries or directories. " +
    (if scan.unreadable > 0 { "Listing incomplete. " } else { "" }) +
    "Use exact path entry for eligible files beyond this listing.",
  }
}
