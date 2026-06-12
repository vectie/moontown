///|
async test "Wenyu preseed materializes build workspace inputs in build pipeline" {
  let root = "/tmp/moontown-wenyu-preseed-workspace"
  let repo = "/tmp/moontown-wenyu-preseed-repo"
  @support.ignore_checked_command("rm", ["-rf", root])
  @support.ignore_checked_command("rm", ["-rf", repo])
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
    id="wenyu-town-shell",
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
  assert_true(@fs.exists("\{root}/moonclaw.json"))
  assert_true(@fs.exists("\{root}/.moonclaw/moonclaw.json"))
  @support.ignore_checked_command("rm", ["-rf", root])
  @support.ignore_checked_command("rm", ["-rf", repo])
}
