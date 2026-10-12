///|
async test "public authoring API saves and reopens incomplete local drafts without a Book catalog" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-authoring-public-"))
  let store : @collaboration_authoring.Store = {
    root: root + "/state",
    catalog_path: root + "/missing-catalog.json",
  }
  let draft = @contract.empty_draft("public-draft")
  let saved = store.save(draft, "", "2026-10-06T16:00:00Z")
  assert_eq(store.load("public-draft"), saved)
  assert_true(
    try {
      ignore(store.prepare("public-draft", saved.revision))
      false
    } catch {
      @collaboration_authoring.CollaborationError(_) => true
      error => raise error
    },
  )
  assert_false(@fs.exists(root + "/missing-catalog.json"))
}
