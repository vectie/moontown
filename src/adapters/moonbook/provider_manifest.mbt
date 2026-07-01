///|
async fn ensure_book_provider_manifest(
  root : String,
  moonbook_root : String,
) -> Unit {
  let path = moonclaw_provider_manifest_path(root)
  let manifest = [moonbook_task_provider_manifest_entry(root, moonbook_root)]
  write_workspace_text(path, manifest.to_json().stringify())
}

///|
fn moonclaw_provider_manifest_path(root : String) -> String {
  @moonsuite.product_artifact_for_book_root(root, "moonclaw", "providers.json")
}

///|
fn moonbook_task_provider_manifest_entry(
  root : String,
  moonbook_root : String,
) -> BookTaskProviderManifestEntry {
  {
    name: "moonbook",
    title: "MoonBook Extension API",
    description: "MoonBook provider runtime boundary for domain-local book logic.",
    kind: "task-provider",
    capabilities: ["provider", "extension", "provider.task", "extension.task"],
    metadata: {
      command: moonbook_moon_command(),
      args: ["run", "cmd/main", "--"],
      cwd: moonbook_root,
      workspace_root: root,
    },
  }
}
