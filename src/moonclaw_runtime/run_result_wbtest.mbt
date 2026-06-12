///|
async test "moonclaw run result helpers read content and optional summary fallback" {
  let root = "/tmp/moontown-moonclaw-run-result-wbtest"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  assert_eq(moonclaw_run_result_path(root), "\{root}/result.json")
  assert_eq(moonclaw_run_result_text_from_workspace(root), "")
  @support.write_text_file(moonclaw_run_result_path(root), "{bad json")
  assert_eq(moonclaw_run_result_text_from_workspace(root), "")
  @support.write_text_file(
    moonclaw_run_result_path(root),
    "{\"content\":\"accepted content\",\"summary\":\"fallback summary\"}",
  )
  assert_eq(moonclaw_run_result_text_from_workspace(root), "accepted content")
  @support.write_text_file(
    moonclaw_run_result_path(root),
    "{\"summary\":\"fallback summary\"}",
  )
  assert_eq(moonclaw_run_result_text_from_workspace(root), "")
  assert_eq(
    moonclaw_run_result_text_from_workspace(root, fallback_summary=true),
    "fallback summary",
  )
}
