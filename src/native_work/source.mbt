///|
/// Resolve only the explicit, already supported source setting. The suite,
/// imported Book, and process working directory are never source fallbacks.
pub async fn source_binding(configured : String?) -> Result[Json, String] {
  guard configured is Some(root) && root != "" else {
    return Err(
      "source_workspace_unconfigured: Set MOONTOWN_WORKSPACE_ROOT to the intended MoonTown source checkout; process cwd is not a source binding",
    )
  }
  source_binding_at(root) catch {
    _ => Err("source_workspace_unavailable: " + root)
  }
}

///|
async fn source_binding_at(root : String) -> Result[Json, String] {
  guard root.has_prefix("/") &&
    @fs.kind(root, follow_symlink=false) is Directory &&
    @fs.realpath(root) == root else {
    return Err("source_workspace_not_canonical")
  }
  let module_path = root + "/moon.mod"
  guard @fs.kind(module_path, follow_symlink=false) is Regular &&
    @fs.realpath(module_path) == module_path else {
    return Err("source_module_missing")
  }
  let metadata = @fs.read_file(module_path).text()
  let lines = metadata.split("\n")
  guard lines.any(line => line.trim() == "name = \"vectie/moontown\"") else {
    return Err("source_module_identity_mismatch")
  }
  let top = @integration.run_checked("git", [
    "-C", root, "rev-parse", "--show-toplevel",
  ])
  guard top.stdout.trim() == root else {
    return Err("source_repository_root_mismatch")
  }
  let gitdir = @integration.run_checked("git", [
    "-C", root, "rev-parse", "--absolute-git-dir",
  ])
  let head = @integration.run_checked("git", ["-C", root, "rev-parse", "HEAD"])
  Ok({
    "setting": "MOONTOWN_WORKSPACE_ROOT",
    "root": root,
    "module_identity": "vectie/moontown",
    "module_digest": digest(metadata),
    "repository_identity": gitdir.stdout.trim().to_owned(),
    "base_head": head.stdout.trim().to_owned(),
  })
}

///|
pub fn source_root(binding : Json) -> String {
  text(binding, "root")
}

///|
pub async fn source_still_bound(
  binding : Json,
  strict_digest? : Bool = true,
) -> Bool {
  match source_binding(Some(source_root(binding))) {
    Ok(current) =>
      text(current, "repository_identity") ==
      text(binding, "repository_identity") &&
      (
        !strict_digest ||
        text(current, "module_digest") == text(binding, "module_digest")
      ) &&
      text(current, "base_head") == text(binding, "base_head")
    Err(_) => false
  }
}
