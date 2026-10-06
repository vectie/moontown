///| The mutex covers separate PortableStore values in this process. The file

///|
/// lock covers cooperating processes using this independent index.
let store_mutex : @async.Mutex = Mutex()

///|
async fn optional_kind(path : String) -> @fs.FileKind? {
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
async fn require_regular(path : String) -> Unit {
  guard optional_kind(path) is Some(Regular) else {
    raise TransferError(503, "package_storage_unavailable")
  }
}

///|
async fn private_directory(path : String) -> Unit {
  match optional_kind(path) {
    Some(Directory) => ()
    Some(_) => raise TransferError(503, "package_storage_unavailable")
    None => @fs.mkdir(path, permission=0o700, recursive=true)
  }
  guard @fs.kind(path, follow_symlink=false) == Directory else {
    raise TransferError(503, "package_storage_unavailable")
  }
}

///|
async fn PortableStore::ensure_root(self : PortableStore) -> Unit {
  checked_limits(self.limits)
  guard self.root.has_prefix("/") &&
    !self.root.has_suffix("/") &&
    !self.root.contains("\u0000") else {
    raise TransferError(503, "package_storage_unavailable")
  }
  let mut prefix = ""
  for part in self.root.split("/") {
    if part.is_empty() {
      continue
    }
    guard part != "." && part != ".." else {
      raise TransferError(503, "package_storage_unavailable")
    }
    prefix = prefix + "/" + part.to_owned()
    match optional_kind(prefix) {
      Some(Directory) | None => ()
      Some(_) => raise TransferError(503, "package_storage_unavailable")
    }
  }
  private_directory(self.root)
  private_directory(self.root + "/objects")
  private_directory(self.root + "/incoming")
}

///|
fn PortableStore::object_path(self : PortableStore, id : String) -> String {
  self.root + "/objects/" + id + ".moonbook-agent"
}

///|
fn PortableStore::part_path(self : PortableStore, attempt : String) -> String {
  self.root + "/incoming/" + attempt + ".part"
}

///|
async fn PortableStore::load_index(self : PortableStore) -> StoreIndex {
  let path = self.root + "/index.json"
  match optional_kind(path) {
    None => empty_index()
    Some(Regular) => {
      let file = @fs.open(path, mode=ReadOnly)
      defer file.close()
      guard file.kind() == Regular else {
        raise TransferError(503, "package_state_unavailable")
      }
      let size = file.size()
      guard size > 0L && size <= 8388608L else {
        raise TransferError(503, "package_state_unavailable")
      }
      let data = file.read_exactly_at(size.to_int(), position=0L)
      let json = @json.parse(@utf8.decode(data))
      let index : StoreIndex = @json.from_json(json)
      // Round-trip equality rejects unknown/missing fields, fractional integer
      // values, and noncanonical persisted representations.
      guard index.to_json() == json else {
        raise TransferError(503, "package_state_unavailable")
      }
      validate_index(index)
      index
    }
    Some(_) => raise TransferError(503, "package_state_unavailable")
  }
}

///|
async fn PortableStore::save_index(
  self : PortableStore,
  index : StoreIndex,
) -> Unit {
  validate_index(index)
  let next = self.root + "/index.next"
  match optional_kind(next) {
    Some(Regular) => @fs.remove(next)
    Some(_) => raise TransferError(503, "package_state_unavailable")
    None => ()
  }
  let text = index.to_json().stringify() + "\n"
  guard @utf8.encode(text).length() <= 8388608 else {
    raise TransferError(503, "package_state_capacity")
  }
  self.checkpoint("index_write")
  @fs.write_file(next, text, create_mode=CreateNew, permission=0o600, sync=Full)
  self.checkpoint("index_rename")
  @fs.rename(next, self.root + "/index.json", replace=true)
  self.checkpoint("index_committed")
}

///|
async fn[T] PortableStore::with_index(
  self : PortableStore,
  action : async (StoreIndex) -> T,
) -> T {
  store_mutex.acquire()
  defer store_mutex.release()
  try {
    self.ensure_root()
    let path = self.root + "/index.lock"
    match optional_kind(path) {
      Some(Regular) | None => ()
      Some(_) => raise TransferError(503, "package_state_unavailable")
    }
    let lock = @fs.open(
      path,
      mode=ReadWrite,
      create_mode=OpenOrCreate,
      permission=0o600,
    )
    defer lock.close()
    guard lock.kind() == Regular else {
      raise TransferError(503, "package_state_unavailable")
    }
    lock.lock(Exclusive)
    defer lock.unlock()
    action(self.load_index())
  } catch {
    TransferError(_, _) as error => raise error
    error =>
      if @async.is_cancellation_error(error) {
        raise error
      } else {
        raise TransferError(503, "package_storage_unavailable")
      }
  }
}

///|
fn replace_package(index : StoreIndex, p : StoredPackage) -> StoreIndex {
  let packages = index.packages.filter(old => old.package_id != p.package_id)
  packages.push(p)
  { ..index, packages, revision: index.revision + 1UL, }
}

///|
async fn remove_regular_if_present(path : String) -> Bool {
  try {
    match optional_kind(path) {
      None => true
      Some(Regular) => {
        @fs.remove(path)
        true
      }
      Some(_) => false
    }
  } catch {
    _ => false
  }
}

///|
async fn PortableStore::remove_owned(
  self : PortableStore,
  path : String,
) -> Bool {
  try {
    self.checkpoint("unlink")
    remove_regular_if_present(path)
  } catch {
    _ => false
  }
}

///|
pub async fn PortableStore::list(
  self : PortableStore,
  actor : TransferActor,
  now_ms : UInt64,
) -> Array[PackageView] {
  self.with_index(index => {
    let result : Array[PackageView] = []
    for p in index.packages {
      if access_basis(index, actor, p, now_ms) is Some(basis) {
        result.push(view_for(index, p, basis))
      }
    }
    result
  })
}

///|
pub async fn PortableStore::get(
  self : PortableStore,
  actor : TransferActor,
  id : String,
  digest : String,
  now_ms : UInt64,
) -> PackageView {
  self.with_index(index => {
    let (p, basis) = authorized(index, actor, id, digest, now_ms)
    view_for(index, p, basis)
  })
}
