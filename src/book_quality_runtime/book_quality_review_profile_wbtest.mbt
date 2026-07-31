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
    "gpt-5.6-sol",
  ).stringify()
  assert_true(corrected.contains("\"model\":\"gpt-5.6-sol\""))
  assert_true(
    corrected.contains(
      "\"args\":[\"exec\",\"--model\",\"gpt-5.6-sol\",\"--sandbox\",\"workspace-write\"]",
    ),
  )
}

///|
async test "book quality review profile preserves canonical MoonClaw model and auth config" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-profile-preserves-config",
  )
  let review_dir = "\{root}/ai-review-packets"
  let config_path = @book_quality.moonclaw_config_path(review_dir)
  let config : Json = {
    "agents": {
      "defaults": {
        "model": { "primary": "codex/gpt-5.4" },
        "workspace": "/tmp/original-workspace",
      },
    },
    "models": { "providers": { "codex": { "auth": "oauth" } } },
    "keep": "canonical",
  }
  @support.write_text_file(config_path, config.stringify(indent=2))
  write_book_quality_review_moonclaw_profile(review_dir)
  let text = @support.read_text_or_empty(config_path)
  assert_true(text.contains("\"primary\": \"codex/gpt-5.4\""))
  assert_true(text.contains("\"auth\": \"oauth\""))
  assert_true(text.contains("\"workspace\": \"/tmp/original-workspace\""))
  assert_true(text.contains("\"keep\": \"canonical\""))
  assert_true(text.contains("\"codex-main\""))
  assert_true(text.contains("\"Codex Book Quality Reviewer\""))
}
