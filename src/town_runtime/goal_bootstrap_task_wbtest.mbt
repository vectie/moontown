///|
test "town runtime delegates bootstrap task contract to owner package" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-runtime-dispatch",
    name="Runtime Dispatch",
    purpose="Test runtime dispatch.",
    workspace_root="/tmp/research-runtime-dispatch",
  )
  let research = bootstrap_ingest_task(
    entry, "Research how LLMs are trained in very detail",
  )
  let wenyu = bootstrap_ingest_task(
    entry, "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
  )
  assert_eq(research.title, "Bootstrap verified research coverage")
  assert_eq(wenyu.title, "Bootstrap Wenyu Valley module coverage")
  assert_true(research.prompt.contains("Work as a researcher"))
  assert_true(!research.prompt.contains("WENYU_VALLEY_PRD"))
  assert_true(wenyu.prompt.contains("WENYU_VALLEY_PRD.md"))
  assert_true(wenyu.prompt.contains("must not collapse all Wenyu modules"))
}
