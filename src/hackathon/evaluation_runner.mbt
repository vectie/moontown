///|
/// Trusted operator registry. Arguments are literal and never interpreted by
/// a shell. Participant material URLs only appear in the request document.
pub struct CompetitionRunner {
  key : String
  program : String
  args : Array[String]
  cwd : String
  timeout_ms : Int
} derive(Debug, ToJson, FromJson)

///|
struct RunnerOutput {
  metrics : Array[MetricValue]
  evidence : Array[String]
} derive(FromJson)

///|
pub fn competition_runner_registry_path() -> String {
  @env.get_env_var("MOONTOWN_CONTEST_RUNNERS").unwrap_or(
    @storage.moontown_product_state_dir() + "/contest-express/runners.json",
  )
}

///|
fn competition_digest(text : String) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text)))
}

///|
/// A durable ledger receipt is still available when the filesystem cannot
/// materialize worker files. The caller persists it through the result action.
pub fn failed_benchmark_result(
  state : HackathonState,
  run_id : String,
  reason : String,
) -> BenchmarkResult raise {
  let run = find_benchmark_run(state, run_id)
  let submission = evaluation_submission(state, run.submission_id)
  let input : Json = {
    "run": run.to_json(),
    "submission": submission.to_json(),
  }
  let output : Json = { "reason": reason }
  {
    run_id,
    worker_run_id: "contest-worker:" + run.id,
    metrics: [],
    evidence: ["ledger:benchmark-run/" + run.id],
    input_hash: competition_digest(input.stringify()),
    output_hash: competition_digest(output.stringify()),
    success: false,
    reason,
  }
}

///|
async fn read_bounded_runner_output(
  reader : @process.ReadFromProcess,
  bytes : Array[Byte],
) -> Unit {
  defer reader.close()
  while reader.read_some(max_len=8192) is Some(chunk) {
    guard bytes.length() + chunk.length() <= 1048576 else {
      fail("benchmark worker output exceeded 1 MiB")
    }
    for byte in chunk {
      bytes.push(byte)
    }
  }
}

///|
async fn run_trusted_benchmark(
  runner : CompetitionRunner,
  request_path : String,
  out_bytes : Array[Byte],
  err_bytes : Array[Byte],
) -> Int {
  @async.with_timeout(runner.timeout_ms, () => {
    @async.with_task_group(group => {
      let (stdout, stdout_target) = @process.read_from_process()
      let (stderr, stderr_target) = @process.read_from_process()
      let out = group.spawn(() => read_bounded_runner_output(stdout, out_bytes))
      let err = group.spawn(() => read_bounded_runner_output(stderr, err_bytes))
      let exit = @process.run(
        runner.program,
        runner.args,
        cwd=runner.cwd,
        inherit_env=false,
        extra_env={ "CONTEST_EXPRESS_REQUEST": request_path },
        stdout=stdout_target,
        stderr=stderr_target,
        cancel_handler=@process.hard_cancel(),
      )
      out.wait()
      err.wait()
      exit
    })
  })
}

///|
/// Run the exact operator-registered command with a durable versioned request.
/// This is a worker boundary: callers persist `start-benchmark` before invoking
/// it, and persist the returned receipt via the internal result action.
pub async fn execute_configured_benchmark(
  state : HackathonState,
  run_id : String,
  registry_path? : String = competition_runner_registry_path(),
  receipt_root? : String = @storage.moontown_product_state_dir() +
    "/contest-express/benchmark-receipts",
) -> BenchmarkResult {
  let run = find_benchmark_run(state, run_id)
  guard valid_id(run.id) && ["queued", "running"].contains(run.state) else {
    fail("benchmark run is not ready to execute")
  }
  let submission = evaluation_submission(state, run.submission_id)
  let track = evaluation_track(state, submission)
  guard state.submission_packages
    .iter()
    .find_first(p => p.submission_id == submission.id)
    is Some(package) &&
    state.challenges.iter().find_first(c => c.id == submission.challenge_id)
    is Some(challenge) &&
    challenge.benchmark_version == run.benchmark_version else {
    fail("benchmark input version is stale")
  }
  let request : Json = {
    "schema": "moontown.contest-express.benchmark-request.v1",
    "run_id": run.id,
    "benchmark_version": run.benchmark_version,
    "challenge": challenge.to_json(),
    "track": track.to_json(),
    "submission": submission.to_json(),
    "package": package.to_json(),
  }
  let input = request.stringify(indent=2)
  let directory = receipt_root + "/" + run.id
  let request_path = directory + "/request.json"
  @support.ensure_parent_directory(request_path)
  // Every queue attempt has a fresh run ID, so its evidence is immutable.
  @fs.write_file(
    request_path,
    input,
    create_mode=CreateNew,
    permission=0o600,
    sync=Full,
  )
  let input_hash = competition_digest(input)
  let out_bytes : Array[Byte] = []
  let err_bytes : Array[Byte] = []
  let mut metrics : Array[MetricValue] = []
  let evidence : Array[String] = [request_path]
  let mut success = false
  let mut reason = ""
  try {
    guard @fs.kind(registry_path, follow_symlink=false) is Regular else {
      fail("operator benchmark runner registry is unavailable")
    }
    let runners : Array[CompetitionRunner] = @json.from_json(
      @json.parse(@fs.read_file(registry_path).text()),
    )
    guard runners.iter().find_first(r => r.key == track.runner_key)
      is Some(runner) else {
      fail("track runner is not configured on this worker")
    }
    guard runner.program.has_prefix("/") &&
      runner.cwd.has_prefix("/") &&
      runner.timeout_ms > 0 &&
      runner.timeout_ms <= 3600000 else {
      fail(
        "operator runner requires absolute paths and a timeout up to one hour",
      )
    }
    let exit = run_trusted_benchmark(runner, request_path, out_bytes, err_bytes)
    guard exit == 0 else { fail("benchmark worker exited with code \{exit}") }
    let output : RunnerOutput = @json.from_json(
      @json.parse(@utf8.decode(Bytes::from_array(out_bytes))),
    )
    validate_measured_metrics(track, output.metrics)
    guard !output.evidence.is_empty() &&
      output.evidence.all(e => !e.trim().is_empty()) else {
      fail("benchmark worker omitted reproducibility evidence")
    }
    metrics = output.metrics
    for item in output.evidence {
      evidence.push(item)
    }
    success = true
  } catch {
    error => reason = error.to_string()
  }
  let output : Json = {
    "stdout": @utf8.decode(Bytes::from_array(out_bytes)),
    "stderr": @utf8.decode(Bytes::from_array(err_bytes)),
    "reason": reason,
  }
  let output_text = output.stringify()
  let output_path = directory + "/output.json"
  @fs.write_file(
    output_path,
    output_text,
    create_mode=CreateNew,
    permission=0o600,
    sync=Full,
  )
  evidence.push(output_path)
  let result : BenchmarkResult = {
    run_id: run.id,
    worker_run_id: "contest-worker:" + run.id,
    metrics,
    evidence,
    input_hash,
    output_hash: competition_digest(output_text),
    success,
    reason,
  }
  @fs.write_file(
    directory + "/receipt.json",
    result.to_json().stringify(indent=2),
    create_mode=CreateNew,
    permission=0o600,
    sync=Full,
  )
  result
}
