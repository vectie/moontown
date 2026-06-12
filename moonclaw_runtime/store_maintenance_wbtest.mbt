///|
async test "moonclaw store compaction rotates oversized job store files" {
  let root = "/tmp/moontown-moonclaw-store-compaction-wbtest"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  let jobs_root = "\{root}/.moonclaw/jobs"
  @support.write_text_file(
    "\{jobs_root}/job_proposals.json",
    "{\"proposals\":[{\"id\":\"old-proposal\",\"payload\":\"01234567890123456789\"}]}",
  )
  @support.write_text_file(
    "\{jobs_root}/definitions.json",
    "{\"definitions\":[{\"id\":\"old-definition\",\"payload\":\"01234567890123456789\"}]}",
  )
  @support.write_text_file(
    "\{jobs_root}/index/artifacts.json",
    "{\"artifacts\":[{\"id\":\"small\"}]}",
  )
  let summary = compact_moonclaw_job_store_if_needed(
    root,
    42,
    max_store_bytes=50,
  )
  assert_true(summary.contains("MoonClaw store compacted before import"))
  assert_true(summary.contains("job_proposals.json"))
  assert_true(summary.contains("definitions.json"))
  assert_eq(
    @support.read_text_or_empty("\{jobs_root}/job_proposals.json"),
    "{\"proposals\":[]}",
  )
  assert_eq(
    @support.read_text_or_empty("\{jobs_root}/definitions.json"),
    "{\"definitions\":[],\"workflows\":[]}",
  )
  assert_true(@fs.exists("\{jobs_root}/archive/tick-42/job_proposals.json"))
  assert_true(@fs.exists("\{jobs_root}/archive/tick-42/definitions.json"))
  assert_false(@fs.exists("\{jobs_root}/archive/tick-42/index/artifacts.json"))
}

///|
async test "moonclaw store compaction repairs legacy definitions schema" {
  let root = "/tmp/moontown-moonclaw-store-legacy-definitions-wbtest"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  let jobs_root = "\{root}/.moonclaw/jobs"
  @support.write_text_file(
    "\{jobs_root}/definitions.json",
    "{\"definitions\":[]}",
  )
  let summary = compact_moonclaw_job_store_if_needed(
    root,
    44,
    max_store_bytes=1000,
  )
  assert_true(summary.contains("definitions.json=legacy-schema"))
  assert_eq(
    @support.read_text_or_empty("\{jobs_root}/definitions.json"),
    "{\"definitions\":[],\"workflows\":[]}",
  )
  assert_true(@fs.exists("\{jobs_root}/archive/tick-44/definitions.json"))
}

///|
async test "moonclaw store compaction is quiet when files are under threshold" {
  let root = "/tmp/moontown-moonclaw-store-quiet-wbtest"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  let jobs_root = "\{root}/.moonclaw/jobs"
  @support.write_text_file(
    "\{jobs_root}/job_proposals.json",
    "{\"proposals\":[]}",
  )
  let summary = compact_moonclaw_job_store_if_needed(
    root,
    43,
    max_store_bytes=1000,
  )
  assert_eq(summary, "")
  assert_eq(
    @support.read_text_or_empty("\{jobs_root}/job_proposals.json"),
    "{\"proposals\":[]}",
  )
}
