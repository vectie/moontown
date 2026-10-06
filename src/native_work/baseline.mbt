///|
async fn git_read(root : String, args : Array[String]) -> String {
  @integration.run_checked("git", ["-C", root] + args).stdout
}

///|
fn relative_path(path : String) -> Bool {
  path != "" &&
  !path.has_prefix("/") &&
  !path.contains("\\") &&
  !path.split("/").any(part => part == ".." || part == "." || part == "")
}

///|
fn native_fingerprint(bytes : Bytes) -> String {
  "present:" + @base64.encode(Bytes::from_array(@crypto.sha256(bytes)))
}

///|
async fn source_snapshot(root : String) -> Json {
  let listed = git_read(root, [
    "ls-files", "-z", "--cached", "--others", "--exclude-standard",
  ])
  let names = listed
    .split("\u0000")
    .filter(name => name != "")
    .map(name => name.to_owned())
    .to_array()
  names.sort()
  if names.length() > 20000 {
    fail("source_snapshot_too_large")
  }
  let files : Map[String, Json] = Map([])
  let executable : Map[String, Json] = Map([])
  for relative in names {
    if files.contains(relative) {
      continue
    }
    if !relative_path(relative) {
      fail("source_snapshot_path_invalid")
    }
    let path = root + "/" + relative
    let kind = @fs.kind(path, follow_symlink=false) catch { _ => @fs.Unknown }
    if kind is SymLink {
      let target = @integration.run_checked("readlink", ["--", path]).stdout
      files[relative] = ("symlink:" + digest(target)).to_json()
      continue
    }
    if !@fs.exists(path) {
      files[relative] = "absent".to_json()
      continue
    }
    if @fs.kind(path, follow_symlink=false) != Regular ||
      @fs.realpath(path) != path {
      fail("source_snapshot_path_not_regular: " + relative)
    }
    let file = @fs.open(path, mode=ReadOnly)
    defer file.close()
    if file.size() > 64_000_000L {
      fail("source_snapshot_file_too_large: " + relative)
    }
    files[relative] = native_fingerprint(file.read_all().binary()).to_json()
    executable[relative] = @fs.can_execute(path).to_json()
  }
  let dirty : Array[String] = []
  for
    listing in [
      git_read(root, [
        "diff", "--name-only", "-z", "--no-ext-diff", "--no-textconv",
      ]),
      git_read(root, [
        "diff", "--cached", "--name-only", "-z", "--no-ext-diff", "--no-textconv",
      ]),
      git_read(root, ["ls-files", "--others", "--exclude-standard", "-z"]),
    ] {
    for item in listing.split("\u0000") {
      if item != "" && !dirty.contains(item.to_owned()) {
        dirty.push(item.to_owned())
      }
    }
  }
  dirty.sort()
  let head = git_read(root, ["rev-parse", "HEAD"]).trim().to_owned()
  let index = git_read(root, [
    "diff", "--cached", "--binary", "--no-ext-diff", "--no-textconv",
  ])
  let canonical = names
    .map(name => {
      name +
      ":" +
      text(Json::object(files), name) +
      ":" +
      executable.get(name).unwrap_or(Json::null()).stringify()
    })
    .join("\n")
  {
    "root": root,
    "head": head,
    "files": Json::object(files),
    "executable": Json::object(executable),
    "dirty_paths": dirty,
    "index_digest": digest(index),
    "source_digest": digest(canonical),
  }
}

///|
/// Existing runtime task-scope protects pre-existing dirty paths. It is derived
/// from the full baseline, never from the target-file inspection hints.
fn clean_source_scopes(snapshot : Json) -> Array[String] {
  let dirty = rows(snapshot, "dirty_paths").filter_map(value => {
    if value is String(path) {
      Some(path)
    } else {
      None
    }
  })
  if dirty.is_empty() {
    return ["."]
  }
  let scopes : Array[String] = []
  if field(snapshot, "files") is Object(files) {
    for path, _ in files {
      if dirty.contains(path) {
        continue
      }
      let pieces = path.split("/").to_array()
      for count in 1..<=pieces.length() {
        let candidate = pieces[:count].join("/")
        if dirty.any(path => {
            path == candidate || path.has_prefix(candidate + "/")
          }) {
          continue
        }
        if !scopes.contains(candidate) {
          scopes.push(candidate)
        }
        break
      }
    }
  }
  scopes.sort()
  scopes
}
