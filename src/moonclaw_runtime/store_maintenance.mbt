///|
pub async fn compact_moonclaw_job_store_if_needed(
  workspace_root : String,
  tick : Int,
  max_store_bytes? : Int64 = 50_000_000,
) -> String {
  let jobs_root = @moonsuite.product_artifact_for_book_root(
    workspace_root, "moonclaw", "jobs",
  )
  let rotated = []
  for item in moonclaw_store_compaction_targets(jobs_root) {
    let reset_reason = moonclaw_store_reset_reason(item)
    match moonclaw_file_size(item.path) {
      Some(size) if size > max_store_bytes => {
        let archive_path = "\{jobs_root}/archive/tick-\{tick}/\{item.name}"
        @support.ensure_parent_directory(archive_path)
        ignore(@integration.run_checked("mv", [item.path, archive_path])) catch {
          _ => continue
        }
        @support.write_text_file(item.path, item.empty_json)
        rotated.push("\{item.name}=\{size}B")
      }
      Some(_) if reset_reason is Some(reason) => {
        let archive_path = "\{jobs_root}/archive/tick-\{tick}/\{item.name}"
        @support.ensure_parent_directory(archive_path)
        ignore(@integration.run_checked("mv", [item.path, archive_path])) catch {
          _ => continue
        }
        @support.write_text_file(item.path, item.empty_json)
        rotated.push("\{item.name}=\{reason}")
      }
      _ => ()
    }
  }
  if rotated.is_empty() {
    ""
  } else {
    "MoonClaw store compacted before import: \{rotated.join(", ")}."
  }
}

///|
pub async fn compact_registered_moonclaw_job_stores(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  tick? : Int = 0,
  max_store_bytes? : Int64 = 50_000_000,
) -> String {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let summaries = []
  let seen = []
  for entry in catalog {
    seen.push(entry.id)
    let summary = compact_moonclaw_job_store_for_book(
      entry.id,
      @moonbook.workspace_root(entry),
      tick,
      max_store_bytes~,
    )
    if !summary.is_empty() {
      summaries.push(summary)
    }
  }
  let snapshot_book_count = match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let mut added = 0
      for book in snapshot.town.books {
        if seen.contains(book.id) {
          continue
        }
        seen.push(book.id)
        added += 1
        let summary = compact_moonclaw_job_store_for_book(
          book.id,
          book.workspace_root,
          tick,
          max_store_bytes~,
        )
        if !summary.is_empty() {
          summaries.push(summary)
        }
      }
      added
    }
    None => 0
  }
  let checked_count = catalog.length() + snapshot_book_count
  if summaries.is_empty() {
    "MoonClaw store compaction checked \{checked_count} book(s); no oversized hot stores found."
  } else {
    "MoonClaw store compaction checked \{checked_count} book(s); compacted \{summaries.length()} book(s).\n\{summaries.join("\n")}"
  }
}

///|
async fn compact_moonclaw_job_store_for_book(
  book_id : String,
  workspace_root : String,
  tick : Int,
  max_store_bytes~ : Int64,
) -> String {
  let summary = compact_moonclaw_job_store_if_needed(
    workspace_root,
    tick,
    max_store_bytes~,
  )
  if summary.is_empty() {
    ""
  } else {
    "- `\{book_id}`: \{summary}"
  }
}

///|
struct MoonClawStoreCompactionTarget {
  name : String
  path : String
  empty_json : String
} derive(Eq, Debug)

///|
fn moonclaw_store_compaction_targets(
  jobs_root : String,
) -> Array[MoonClawStoreCompactionTarget] {
  [
    {
      name: "job_proposals.json",
      path: "\{jobs_root}/job_proposals.json",
      empty_json: "{\"proposals\":[]}",
    },
    {
      name: "definitions.json",
      path: "\{jobs_root}/definitions.json",
      empty_json: "{\"definitions\":[],\"workflows\":[]}",
    },
    {
      name: "index/artifacts.json",
      path: "\{jobs_root}/index/artifacts.json",
      empty_json: "{\"artifacts\":[]}",
    },
  ]
}

///|
async fn moonclaw_store_reset_reason(
  item : MoonClawStoreCompactionTarget,
) -> String? {
  if item.name != "definitions.json" || !@fs.exists(item.path) {
    return None
  }
  let text = @fs.read_file(item.path).text() catch { _ => return None }
  if text.trim().is_empty() {
    Some("empty")
  } else if !text.contains("\"workflows\"") {
    Some("invalid-schema")
  } else {
    None
  }
}

///|
async fn moonclaw_file_size(path : String) -> Int64? {
  if !@fs.exists(path) {
    return None
  }
  let file = @fs.open(path, mode=ReadOnly) catch { _ => return None }
  defer file.close()
  Some(file.size()) catch {
    _ => None
  }
}
