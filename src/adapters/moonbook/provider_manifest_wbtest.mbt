///|
test "moonclaw provider manifest entry uses product home" {
  let root = "/tmp/moontown-provider-manifest-suite/books/provider-book"
  let moonbook_root = "/tmp/moontown-provider-manifest-moonbook"
  let path = moonclaw_provider_manifest_path(root)
  let provider = moonbook_task_provider_manifest_entry(root, moonbook_root)
  assert_eq(
    path, "/tmp/moontown-provider-manifest-suite/.moonsuite/products/moonclaw/providers.json",
  )
  assert_eq(provider.name, "moonbook")
  assert_eq(provider.kind, "task-provider")
  assert_true(!provider.metadata.command.trim().is_empty())
  assert_true(provider.metadata.command.contains("moon"))
  assert_true(provider.metadata.args == ["run", "cmd/main", "--"])
  assert_eq(provider.metadata.cwd, moonbook_root)
  assert_eq(provider.metadata.workspace_root, root)
  assert_true(provider.capabilities.contains("extension.task"))
}
