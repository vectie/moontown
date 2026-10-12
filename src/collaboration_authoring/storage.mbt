///|
/// Local-only authoring storage. No worker, schedule, provider, or Book writer.
pub(all) struct Store {
  root : String
  catalog_path : String
}

///|
pub suberror CollaborationError {
  CollaborationError(String)
} derive(Debug)

///|
let mutex : @async.Mutex = Mutex()

///|
fn digest(bytes : Bytes) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
async fn kind(path : String) -> @fs.FileKind? {
  Some(@fs.kind(path, follow_symlink=false)) catch {
    @os_error.OSError(_, ..) as error =>
      if error.is_ENOENT() {
        None
      } else {
        raise error
      }
    error => raise error
  }
}

///|
/// Reject every existing symlink component, including trusted storage roots.
async fn directory(path : String, create : Bool) -> Unit {
  guard path.has_prefix("/") && !path.contains("\u0000") else {
    raise CollaborationError("Absolute local storage root required")
  }
  let mut prefix = ""
  for part in path.split("/") {
    if part.is_empty() {
      continue
    }
    guard part != "." && part != ".." else {
      raise CollaborationError("Unsafe directory")
    }
    prefix = prefix + "/" + part.to_owned()
    match kind(prefix) {
      Some(Directory) => ()
      None if create => @fs.mkdir(prefix, permission=0o700)
      _ =>
        raise CollaborationError("Directory is missing or contains a symlink")
    }
  }
}

///|
async fn read_bytes(path : String, limit : Int) -> Bytes {
  guard kind(path) is Some(Regular) else {
    raise CollaborationError(
      "Source or artifact is missing or is not a regular file",
    )
  }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= limit.to_int64() else {
    raise CollaborationError("Source or artifact exceeds the size limit")
  }
  let bytes = file.read_exactly_at(size.to_int(), position=0L)
  guard file.size() == size else {
    raise CollaborationError("Source changed while being captured")
  }
  bytes
}

///|
async fn write_bytes(path : String, bytes : Bytes) -> Unit {
  let parent = path[:path.rev_find("/").unwrap()].to_owned()
  directory(parent, true)
  match kind(path) {
    Some(Regular) => {
      guard read_bytes(path, 33554432) == bytes else {
        raise CollaborationError(
          "Immutable artifact already exists with different bytes",
        )
      }
    }
    None => {
      // A private reserved staging name makes interrupted writes retryable.
      // User-selected paths cannot contain hidden components, so it cannot
      // collide with a selected source or an exported artifact.
      let temporary = parent + "/.collaboration-next"
      match kind(temporary) {
        Some(Regular) => @fs.remove(temporary)
        None => ()
        _ => raise CollaborationError("Unsafe artifact staging path")
      }
      @fs.write_file(
        temporary,
        bytes,
        create_mode=CreateNew,
        permission=0o600,
        sync=Full,
      )
      @fs.rename(temporary, path, replace=false)
    }
    _ => raise CollaborationError("Artifact path is unsafe")
  }
}

///|
async fn[T] Store::locked(self : Store, operation : async () -> T) -> T {
  mutex.acquire()
  defer mutex.release()
  directory(self.root, true)
  let path = self.root + "/authoring.lock"
  guard kind(path) is (None | Some(Regular)) else {
    raise CollaborationError("Unsafe authoring lock")
  }
  let lock = @fs.open(
    path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  defer lock.close()
  lock.lock(Exclusive)
  defer lock.unlock()
  operation()
}

///|
fn Store::draft_root(self : Store, id : String) -> String raise {
  guard @contract.safe_id(id) else {
    raise CollaborationError("Invalid draft ID")
  }
  self.root + "/drafts/" + id
}

///|
async fn Store::current_revision(self : Store, id : String) -> String {
  let path = self.draft_root(id) + "/current"
  match kind(path) {
    None => ""
    Some(Regular) => {
      let revision = @utf8.decode(read_bytes(path, 100))
      guard @contract.safe_id(revision) else {
        raise CollaborationError("Invalid saved revision")
      }
      revision
    }
    _ => raise CollaborationError("Unsafe draft pointer")
  }
}

///|
fn revision_for(saved : @contract.SavedDraft) -> String {
  "r-" +
  digest(@utf8.encode({ ..saved, revision: "", }.to_json().stringify()))[7:].to_owned()
}

///|
async fn Store::load_revision(
  self : Store,
  id : String,
  revision : String,
) -> @contract.SavedDraft {
  guard @contract.safe_id(revision) else {
    raise CollaborationError("Invalid revision")
  }
  let root = self.draft_root(id) + "/revisions/" + revision
  directory(root, false)
  let json = @json.parse(@utf8.decode(read_bytes(root + "/draft.json", 524288)))
  let saved : @contract.SavedDraft = @json.from_json(json)
  guard saved.to_json() == json &&
    saved.contract_version == "moontown.collaboration-draft.v1" &&
    saved.draft.draft_id == id &&
    saved.revision == revision &&
    revision_for(saved) == revision else {
    raise CollaborationError("Saved draft identity has changed")
  }
  for source in saved.sources {
    guard @contract.safe_id(source.book_id) &&
      @contract.safe_source_path(source.source_path) &&
      source.artifact_ref ==
      "sources/" + source.book_id + "/" + source.source_path else {
      raise CollaborationError("Invalid snapshot path")
    }
    let path = root + "/" + source.artifact_ref
    directory(path[:path.rev_find("/").unwrap()].to_owned(), false)
    let bytes = read_bytes(path, 1048576)
    guard bytes.length() == source.size_bytes && digest(bytes) == source.digest else {
      raise CollaborationError(
        "Captured source bytes no longer match the saved revision",
      )
    }
  }
  saved
}

///|
/// Reopening never reads live source files; the exact captured bytes are verified.
pub async fn Store::load(
  self : Store,
  id : String,
  revision? : String = "",
) -> @contract.SavedDraft {
  self.locked(() => {
    self.load_revision(
      id,
      if revision.is_empty() {
        self.current_revision(id)
      } else {
        revision
      },
    )
  })
}

///|
/// Catalog reads are explicit and never create, repair, or normalize Books.
pub async fn Store::books(self : Store) -> Array[@contract.CatalogBook] {
  let catalog = @moonbook.load_catalog_file(self.catalog_path)
  guard catalog is Some(entries) else {
    raise CollaborationError(
      "The existing Book catalog is unavailable; register Books before selecting sources",
    )
  }
  entries.map(book => { book_id: book.id, title: book.name, })
}

///|
pub async fn Store::list(self : Store) -> Array[@contract.SavedDraft] {
  self.locked(() => {
    let root = self.root + "/drafts"
    if kind(root) is None {
      return []
    }
    directory(root, false)
    let dir = @fs.opendir(root)
    defer dir.close()
    let ids = dir.read_all()
    ids.sort()
    let result : Array[@contract.SavedDraft] = []
    for id in ids {
      guard result.length() < 256 else {
        raise CollaborationError("Too many saved drafts")
      }
      result.push(self.load_revision(id, self.current_revision(id)))
    }
    result
  })
}
