///|
async fn ensure_book_provider_manifest(
  root : String,
  moonbook_root : String,
) -> Unit {
  let (command, args) = moonbook_runtime_invocation([])
  let manifest = [
    moonbook_task_provider_manifest_entry(root, moonbook_root, command~, args~),
  ]
  let text = manifest.to_json().stringify()
  write_workspace_text(moonclaw_provider_manifest_path(root), text)
  write_workspace_text(moonbook_resource_provider_manifest_path(root), text)
}

///|
fn moonclaw_provider_manifest_path(root : String) -> String {
  @moonsuite.product_artifact_for_book_root(root, "moonclaw", "providers.json")
}

///|
fn moonbook_resource_provider_manifest_path(root : String) -> String {
  moonbook_adapter_path(root)
  .join(moonbook_adapter_path(".moonsuite/resource-providers.json"))
  .to_string()
}

///|
fn moonbook_task_provider_manifest_entry(
  root : String,
  moonbook_root : String,
  command? : String = moonbook_moon_command(),
  args? : Array[String] = ["run", "cmd/main", "--"],
) -> BookTaskProviderManifestEntry {
  {
    name: "moonbook",
    title: "MoonBook Extension API",
    description: "MoonBook provider runtime boundary for domain-local book logic.",
    kind: "task-provider",
    capabilities: ["provider", "extension", "provider.task", "extension.task"],
    metadata: {
      command,
      args,
      task_args_prefix: ["wiki", "extension"],
      cwd: moonbook_root,
      workspace_root: root,
    },
  }
}
