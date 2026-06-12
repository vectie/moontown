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
  "\{root}/.moonclaw/providers.json"
}

///|
fn moonbook_task_provider_manifest_entry(
  root : String,
  moonbook_root : String,
) -> BookTaskProviderManifestEntry {
  {
    name: "moonbook",
    title: "MoonBook Book Harness",
    description: "MoonBook provider-task bridge for domain-local workspace logic.",
    kind: "task-provider",
    capabilities: [
      "provider", "extension", "provider.task", "extension.task", "bookapi", "moonbook.bookapi",
    ],
    metadata: {
      command: "moon",
      args: ["run", "cmd/main", "--"],
      cwd: moonbook_root,
      workspace_root: root,
    },
  }
}
