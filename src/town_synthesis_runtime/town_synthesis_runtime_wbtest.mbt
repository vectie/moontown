///|
async test "town synthesis runtime writes synthesis and latest artifacts" {
  let root = "/tmp/moontown-town-synthesis-runtime-check"
  @support.ignore_checked_command("rm", ["-rf", root])
  let state = @core.empty_state(
    @core.TownConfig::new(id="town-synthesis-runtime", name="Runtime"),
  )
  let plan = @roles.MayorGoalPlan::new(
    output_contract="mayor.goal.decomposition.v1",
    prompt="test",
    parallelizable=true,
    summary="test two-lane synthesis",
    lanes=[
      @roles.MayorGoalLane::new(
        entry=@moonbook.BookCatalogEntry::new(
          id="research-moonbook",
          name="MoonBook",
          purpose="Research MoonBook",
          workspace_root="\{root}/research-moonbook",
          tags=["research"],
        ),
        objective="Research MoonBook",
        rationale="test lane",
      ),
      @roles.MayorGoalLane::new(
        entry=@moonbook.BookCatalogEntry::new(
          id="research-moonclaw",
          name="MoonClaw",
          purpose="Research MoonClaw",
          workspace_root="\{root}/research-moonclaw",
          tags=["research"],
        ),
        objective="Research MoonClaw",
        rationale="test lane",
      ),
    ],
  )
  for lane in plan.lanes {
    let entry = lane.entry
    @support.write_text_file(
      "\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md",
      "# \{entry.name}\n\n## Executive Summary\n\n\{entry.name} summary.",
    )
  }
  let snapshot_path = "\{root}/town.json"
  write_town_goal_synthesis(
    state, "research moonbook and moonclaw", plan, snapshot_path,
  )
  let path = @town_synthesis.town_synthesis_path(
    snapshot_path, "research moonbook and moonclaw",
  )
  let text = @support.read_text_or_empty(path)
  assert_true(text.contains("MoonBook summary."))
  assert_true(text.contains("MoonClaw summary."))
  assert_true(
    @support.read_text_or_empty(
      @town_synthesis.town_synthesis_latest_path(snapshot_path),
    ).contains("MoonBook summary."),
  )
  assert_true(state.events.length() > 0)
  @support.ignore_checked_command("rm", ["-rf", root])
}
