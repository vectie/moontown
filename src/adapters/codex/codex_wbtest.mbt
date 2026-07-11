///|
test "codex acp defaults use one model across target builders" {
  assert_eq(model(), "gpt-5.5")
  let args = args()
  assert_true(args.contains("--model"))
  assert_true(args.contains("gpt-5.5"))
  assert_true(args.contains("--sandbox"))
  assert_true(args.contains("workspace-write"))
}

///|
test "codex moontown args stay inside configured workspace" {
  let args = moontown_args()
  assert_true(args.contains("--model"))
  assert_true(args.contains("gpt-5.5"))
  assert_true(args.contains("--cd"))
  assert_false(args.contains("--add-dir"))
}

///|
test "codex package owns moontown target json" {
  let target = moontown_target_json().stringify()
  assert_true(target.contains("\"label\":\"Codex MoonTown Builder\""))
  assert_true(target.contains("\"model\":\"gpt-5.5\""))
  assert_true(target.contains("\"--model\""))
  assert_true(target.contains("\"workspace\""))
}

///|
test "codex package owns reusable codex-main target json" {
  let target = codex_main_target_json("/repo", label="Codex PlanBook Repair").stringify()
  assert_true(target.contains("\"label\":\"Codex PlanBook Repair\""))
  assert_true(target.contains("\"cwd\":\"/repo\""))
  assert_true(target.contains("\"workspace\":\"/repo\""))
  assert_true(target.contains("\"model\":\"gpt-5.5\""))
  assert_true(target.contains("\"--model\""))
  assert_true(target.contains("\"gpt-5.5\""))
}

///|
test "codex target json normalizes explicit model args" {
  let target = codex_acp_target_json(
    "/repo",
    "Codex Custom Worker",
    "/bin/codex",
    ["exec", "--model", "old-model", "--sandbox", "workspace-write"],
    "gpt-5.5",
  ).stringify()
  assert_true(target.contains("\"command\":\"/bin/codex\""))
  assert_true(target.contains("\"model\":\"gpt-5.5\""))
  assert_true(
    target.contains(
      "\"args\":[\"exec\",\"--model\",\"gpt-5.5\",\"--sandbox\",\"workspace-write\"]",
    ),
  )
  assert_true(!target.contains("old-model"))
}

///|
test "codex target json appends missing model args" {
  let target = codex_acp_target_json(
    "/repo",
    "Codex Custom Worker",
    "/bin/codex",
    ["exec", "--sandbox", "workspace-write"],
    "gpt-5.5",
  ).stringify()
  assert_true(
    target.contains(
      "\"args\":[\"exec\",\"--sandbox\",\"workspace-write\",\"--model\",\"gpt-5.5\"]",
    ),
  )
}

///|
test "codex target upsert preserves defaults and existing targets" {
  let base = @json.parse(
    "{\"agents\":{\"defaults\":{\"model\":\"old\"}},\"acp\":{\"targets\":{\"existing\":{\"backend\":\"noop\"}}},\"keep\":\"yes\"}",
  ) catch {
    _ => fail("expected base config to parse")
  }
  let next = upsert_moontown_target_json(base, "/tmp/book").stringify()
  assert_true(next.contains("\"model\":\"old\""))
  assert_true(next.contains("\"workspace\":\"/tmp/book\""))
  assert_true(next.contains("\"existing\":{\"backend\":\"noop\"}"))
  assert_true(next.contains("\"wenyu-codex-moontown\""))
  assert_true(next.contains("\"keep\":\"yes\""))
}

///|
test "codex-main target upsert preserves existing targets" {
  let base = @json.parse(
    "{\"acp\":{\"targets\":{\"existing\":{\"backend\":\"noop\"}}},\"keep\":\"yes\"}",
  ) catch {
    _ => fail("expected base config to parse")
  }
  let next = upsert_codex_main_target_json(
    base,
    "/repo",
    label="Codex PlanBook Repair",
  ).stringify()
  assert_true(next.contains("\"existing\":{\"backend\":\"noop\"}"))
  assert_true(next.contains("\"codex-main\""))
  assert_true(next.contains("\"label\":\"Codex PlanBook Repair\""))
  assert_true(next.contains("\"workspace\":\"/repo\""))
  assert_true(next.contains("\"keep\":\"yes\""))
}
