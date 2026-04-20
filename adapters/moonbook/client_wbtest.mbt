///|
test "book-local moonclaw provider manifest entry is stable" {
  let root = "/tmp/moontown-provider-manifest-book"
  let moonbook_root = "/tmp/moontown-provider-manifest-moonbook"
  let path = moonclaw_provider_manifest_path(root)
  let provider = moonbook_task_provider_manifest_entry(root, moonbook_root)
  assert_eq(
    path, "/tmp/moontown-provider-manifest-book/.moonclaw/providers.json",
  )
  assert_eq(provider.name, "moonbook")
  assert_eq(provider.kind, "task-provider")
  assert_eq(provider.metadata.command, "moon")
  assert_eq(provider.metadata.args, ["run", "cmd/main", "--"])
  assert_eq(provider.metadata.cwd, moonbook_root)
  assert_eq(provider.metadata.workspace_root, root)
  assert_true(provider.capabilities.contains("moonbook.bookapi"))
}
