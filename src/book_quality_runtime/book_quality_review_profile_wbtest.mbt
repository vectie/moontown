///|
test "book quality runtime owns semantic review ACP config" {
  let acp = book_quality_review_acp_config_json(
    "/repo",
    "/bin/codex",
    ["exec", "--sandbox", "workspace-write"],
    "gpt-5",
  ).stringify()
  assert_true(acp.contains("\"codex-main\""))
  assert_true(acp.contains("\"label\":\"Codex Book Quality Reviewer\""))
  assert_true(acp.contains("\"cwd\":\"/repo\""))
  assert_true(acp.contains("\"command\":\"/bin/codex\""))
  assert_true(acp.contains("\"model\":\"gpt-5\""))
  assert_true(acp.contains("\"--model\""))
  assert_true(
    acp.contains(
      "\"args\":[\"exec\",\"--sandbox\",\"workspace-write\",\"--model\",\"gpt-5\"]",
    ),
  )
  let corrected = book_quality_review_acp_config_json(
    "/repo",
    "/bin/codex",
    ["exec", "--model", "gpt-4.1", "--sandbox", "workspace-write"],
    "gpt-5.5",
  ).stringify()
  assert_true(corrected.contains("\"model\":\"gpt-5.5\""))
  assert_true(
    corrected.contains(
      "\"args\":[\"exec\",\"--model\",\"gpt-5.5\",\"--sandbox\",\"workspace-write\"]",
    ),
  )
}
