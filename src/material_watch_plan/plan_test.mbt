///|
async test "shared material plan roundtrips sorted exact sources and rejects wrong binding" {
  let root = @fs.tmpdir(prefix="material-plan-contract-")
  let entry = @moonbook.BookCatalogEntry::new(
    id="book",
    name="Book",
    purpose="Sources",
    workspace_root=root,
  )
  let goal = @core.StandingGoal::new(
    id="watch",
    title="Watch",
    prompt="Intent",
    target_book_id=Some("book"),
  )
  let plan : @material_watch_plan.Plan = {
    contract: "moontown.material_watch_plan.v1",
    goal_id: "watch",
    book_id: "book",
    intent: "Intent",
    acceptance: "Exact change",
    next_action: "Owner review",
    sources: ["sources/z.txt", "sources/a.txt"],
  }
  @support.write_text_file(root + "/sources/a.txt", "unchanged\n")
  @support.write_text_file(root + "/sources/z.txt", "中文 source\n")
  @support.write_text_file(root + "/plan.json", plan.to_json().stringify())
  let readback = @material_watch_plan.read_plan(entry, goal, "plan.json")
  assert_eq(readback.sources, ["sources/a.txt", "sources/z.txt"])
  let sources = @material_watch_plan.read_sources(entry, readback)
  assert_eq(sources[1].content, "中文 source\n")
  assert_eq(sources[1].sha256.length(), 64)
  let wrong = @core.StandingGoal::new(
    id="other",
    title="Other",
    prompt="Intent",
    target_book_id=Some("book"),
  )
  try @material_watch_plan.read_plan(entry, wrong, "plan.json") catch {
    _ => ()
  } noraise {
    _ => fail("Wrong goal binding was accepted")
  }
}
