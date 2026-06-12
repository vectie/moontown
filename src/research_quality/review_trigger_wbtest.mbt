///|
async test "research quality review trigger writes in-place repair contract" {
  let root = "/tmp/moontown-research-quality-trigger"
  @support.ignore_checked_command("rm", ["-rf", root])
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-quality-trigger",
    name="Research Quality Trigger",
    purpose="Test trigger writing.",
    workspace_root=root,
  )
  write_research_quality_review_trigger(
    entry,
    ["missing deep report", "missing source screen"],
    "test quality gate",
  )
  let trigger = @fs.read_file("\{root}/raw/bootstrap/QUALITY_REPAIR.md").text()
  assert_true(trigger.contains("Research Review Trigger"))
  assert_true(trigger.contains("missing deep report"))
  assert_true(trigger.contains("do not create a new v1/v2/v3/v4 book"))
  write_research_quality_review_resolved(entry, "clean after repair")
  let resolved = @fs.read_file("\{root}/raw/bootstrap/QUALITY_REPAIR.md").text()
  assert_true(resolved.contains("No active quality repair."))
  assert_true(resolved.contains("clean after repair"))
  @support.ignore_checked_command("rm", ["-rf", root])
}

///|
async test "research quality review trigger ignores non-research books" {
  let root = "/tmp/moontown-non-research-quality-trigger"
  @support.ignore_checked_command("rm", ["-rf", root])
  let entry = @moonbook.BookCatalogEntry::new(
    id="course-map-design",
    name="Course Map Design",
    purpose="Test non-research guard.",
    workspace_root=root,
  )
  write_research_quality_review_trigger(entry, ["gap"], "ignored")
  assert_true(!@fs.exists("\{root}/raw/bootstrap/QUALITY_REPAIR.md"))
  @support.ignore_checked_command("rm", ["-rf", root])
}
