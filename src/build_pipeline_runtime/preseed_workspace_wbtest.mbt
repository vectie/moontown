///|
async test "Wenyu preseed materializes build workspace inputs in build pipeline" {
  let root = @fs.tmpdir(prefix="moontown-wenyu-preseed-workspace-")
  let repo = @fs.tmpdir(prefix="moontown-wenyu-preseed-repo-")
  @support.write_text_file(
    "\{repo}/docs/WENYU_VALLEY_PRD.md",
    "# Wenyu Valley PRD\n\nBuild the AI innovation town.",
  )
  @support.write_text_file(
    "\{repo}/docs/project/wenyu.md",
    "# Wenyu Vision\n\nMake the valley live.",
  )
  @support.write_text_file(
    "\{repo}/src/ui/rabbita-town/main/main.mbt",
    "fn main { println(\"town\") }",
  )
  @support.write_text_file(
    "\{repo}/src/ui/rabbita-town/styles.css",
    ".town { color: white; }",
  )
  @support.write_text_file(
    "\{repo}/src/roles/mayor.mbt",
    "pub fn mayor_role() -> String { \"mayor\" }",
  )
  @support.write_text_file(
    "\{repo}/src/town_runtime/goal_run.mbt",
    "pub fn goal_run() -> String { \"run\" }",
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-native-build",
    name="Wenyu Valley / Town Shell",
    purpose="Build Wenyu town shell.",
    workspace_root=root,
  )
  preseed_wenyu_goal_inputs(entry, "Build Wenyu Valley", repo)
  let request = @fs.read_file("\{root}/raw/bootstrap/RESEARCH_REQUEST.md").text()
  assert_true(request.contains("Wenyu Valley module: Town Shell"))
  let hints = @fs.read_file("\{root}/raw/bootstrap/SOURCE_HINTS.md").text()
  assert_true(hints.contains("\{repo}/docs/WENYU_VALLEY_PRD.md"))
  let manifest = @fs.read_file("\{root}/mounted-sources/MANIFEST.md").text()
  assert_true(manifest.contains("Mounted Source Manifest"))
  let copied = @fs.read_file(
    "\{root}/mounted-sources/moontown/ui-rabbita-town-main.mbt",
  ).text()
  assert_true(
    copied.contains("source: \{repo}/src/ui/rabbita-town/main/main.mbt"),
  )
  assert_true(@fs.exists("\{root}/skills/wenyu-build/SKILL.md"))
  assert_false(
    @fs.exists(
      @moonsuite.product_artifact_for_workspace_root(
        root, "moonclaw", "moonclaw.json",
      ),
    ),
  )
  assert_false(@fs.exists(root + "/moonclaw.jobs.json"))
  assert_false(@fs.exists("\{root}/moonclaw.json"))
  preseed_wenyu_goal_inputs(entry, "Build Wenyu Valley", repo, execution="acp")
  assert_true(@fs.exists(root + "/moonclaw.jobs.json"))
  assert_true(
    @fs.exists(
      @moonsuite.product_artifact_for_workspace_root(
        root, "moonclaw", "moonclaw.json",
      ),
    ),
  )
}

///|
async test "wenyu explicit legacy preseed preserves customized profile and target bytes" {
  let root = @fs.tmpdir(prefix="moontown-wenyu-custom-legacy-")
  let repo = @fs.tmpdir(prefix="moontown-wenyu-custom-source-")
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-build",
    name="Wenyu Build",
    purpose="Fixture",
    workspace_root=root,
  )
  let profile = "{ \"jobs\": { \"profiles\": { \"wenyu_build_controller\": { \"custom\": true } } } }\n"
  let target = "{ \"acp\": { \"targets\": { \"wenyu-codex-moontown\": { \"custom\": true } } }, \"agents\": { \"defaults\": { \"workspace\": \"unchanged\" } } }\n"
  let target_path = @moonsuite.product_artifact_for_workspace_root(
    root, "moonclaw", "moonclaw.json",
  )
  @support.write_text_file(root + "/moonclaw.jobs.json", profile)
  @support.write_text_file(target_path, target)
  preseed_wenyu_goal_inputs(entry, "goal", repo)
  assert_eq(@fs.read_file(root + "/moonclaw.jobs.json").text(), profile)
  assert_eq(@fs.read_file(target_path).text(), target)
  preseed_wenyu_goal_inputs(entry, "goal", repo, execution="acp")
  assert_eq(@fs.read_file(root + "/moonclaw.jobs.json").text(), profile)
  assert_eq(@fs.read_file(target_path).text(), target)
}
