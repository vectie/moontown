///|
test "dispatch owns book and task domain policy" {
  let coding = @moonbook.BookCatalogEntry::new(
    id="coding",
    name="Coding",
    purpose="Build software.",
    workspace_root="/tmp/coding",
  )
  let finance = @moonbook.BookCatalogEntry::new(
    id="finance",
    name="Finance",
    purpose="Track finance.",
    workspace_root="/tmp/finance",
  )
  assert_eq(domain_for_book(coding), Coding)
  assert_eq(domain_for_book(finance), Finance)
  let patch = @moonbook.BookTask::new(
    id="patch",
    title="Patch code",
    kind="code-patch",
    prompt="Patch",
    priority=1,
    requires_review=true,
  )
  let civic = @moonbook.BookTask::new(
    id="civic",
    title="Run civic workflow",
    kind="civic-service-workflow",
    prompt="Serve",
    priority=1,
    requires_review=true,
  )
  let watch = @moonbook.BookTask::new(
    id="watch",
    title="Watch topic",
    kind="standing-watch",
    prompt="Watch",
    priority=1,
    requires_review=false,
  )
  assert_eq(domain_for_book_task(finance, patch), Coding)
  assert_eq(domain_for_book_task(coding, civic), SocialExperiment)
  assert_eq(domain_for_book_task(coding, watch), Research)
  assert_eq(
    domain_for_provider_overview(
      @core.BookRef::new(
        id="finance",
        name="Finance",
        purpose="Track finance.",
        workspace_root="/tmp/finance",
      ),
    ),
    Finance,
  )
}
