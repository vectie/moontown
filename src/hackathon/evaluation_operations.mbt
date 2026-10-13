///|
fn evaluation_submission(
  state : HackathonState,
  id : String,
) -> Submission raise {
  match state.submissions.iter().find_first(s => s.id == id) {
    Some(submission) => submission
    None => fail("submission was not found")
  }
}

///|
fn evaluation_program(
  state : HackathonState,
  challenge_id : String,
) -> CompetitionProgram raise {
  match state.programs.iter().find_first(p => p.challenge_id == challenge_id) {
    Some(program) => program
    None => fail("competition program was not found")
  }
}

///|
pub fn require_competition_reviewer(
  state : HackathonState,
  submission_id : String,
  reviewer_id : String,
  now_ms : UInt64,
) -> Unit raise {
  let submission = evaluation_submission(state, submission_id)
  if state.programs
    .iter()
    .find_first(p => p.challenge_id == submission.challenge_id)
    is Some(program) {
    guard ["open", "evaluating"].contains(program.state) &&
      now_ms <= program.review_close_ms else {
      fail("competition review is closed")
    }
    guard program.evaluator_ids.contains(reviewer_id) else {
      fail("reviewer is not assigned to this competition")
    }
  }
  guard !reviewer_id.trim().is_empty() &&
    !state.teams.any(t => {
      t.id == submission.team_id && t.members.contains(reviewer_id)
    }) else {
    fail("a team member cannot review their own submission")
  }
}

///|
fn evaluation_track(
  state : HackathonState,
  submission : Submission,
) -> CompetitionTrack raise {
  let program = evaluation_program(state, submission.challenge_id)
  guard state.submission_packages
    .iter()
    .find_first(p => p.submission_id == submission.id)
    is Some(package) else {
    fail("submission package was not found")
  }
  match program.tracks.iter().find_first(t => t.id == package.track_id) {
    Some(track) => track
    None => fail("competition track was not found")
  }
}

///|
fn current_evaluation_version(
  state : HackathonState,
  submission_id : String,
) -> Int raise {
  let submission = evaluation_submission(state, submission_id)
  guard state.challenges.iter().find_first(c => c.id == submission.challenge_id)
    is Some(challenge) else {
    fail("challenge was not found")
  }
  challenge.benchmark_version
}

///|
fn valid_metric_number(value : Double) -> Bool {
  value == value && value >= 0.0 && value < 1.0e300
}

///|
fn validate_measured_metrics(
  track : CompetitionTrack,
  metrics : Array[MetricValue],
) -> Unit raise {
  guard metrics.length() == track.metrics.length() else {
    fail("benchmark result requires every configured metric")
  }
  let seen : Map[String, Bool] = Map([])
  for metric in metrics {
    guard valid_metric_number(metric.value) &&
      !seen.contains(metric.metric_id) &&
      track.metrics.iter().find_first(m => m.id == metric.metric_id)
      is Some(rule) &&
      (rule.direction != "min" || metric.value > 0.0) else {
      fail(
        "benchmark metric is unknown, duplicated, negative or nonfinite; minimizing metrics must be positive",
      )
    }
    seen[metric.metric_id] = true
  }
}

///|
fn benchmark_hash_valid(hash : String) -> Bool {
  let token = if hash.has_prefix("sha256:") {
    hash.substring(start=7).to_string()
  } else {
    hash
  }
  token.length() == 64 &&
  token.iter().all(c => (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))
}

///|
fn replace_benchmark_run(
  state : HackathonState,
  run : BenchmarkRun,
) -> HackathonState {
  let runs = state.benchmark_runs.map(r => if r.id == run.id { run } else { r })
  { ..state, revision: state.revision + 1, benchmark_runs: runs, }
}

///|
fn find_benchmark_run(
  state : HackathonState,
  id : String,
) -> BenchmarkRun raise {
  match state.benchmark_runs.iter().find_first(r => r.id == id) {
    Some(run) => run
    None => fail("benchmark run was not found")
  }
}

///|
pub fn apply_evaluation_action(
  state : HackathonState,
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> HackathonState? raise {
  match action {
    "queue-benchmark" => {
      let request : QueueBenchmarkRequest = @json.from_json(payload)
      guard valid_id(request.id) &&
        !state.benchmark_runs.any(r => r.id == request.id) else {
        fail("benchmark run ID is invalid or already exists")
      }
      require_competition_reviewer(
        state,
        request.submission_id,
        request.reviewer_id,
        now_ms,
      )
      let submission = evaluation_submission(state, request.submission_id)
      let track = evaluation_track(state, submission)
      guard track.scoring_mode == "metric" && !track.runner_key.is_empty() else {
        fail("track requires a configured metric runner")
      }
      let version = current_evaluation_version(state, request.submission_id)
      guard !state.benchmark_runs.any(r => {
        r.submission_id == request.submission_id &&
        r.benchmark_version == version &&
        ["queued", "running", "review"].contains(r.state)
      }) else {
        fail("submission already has an active benchmark run")
      }
      let runs = state.benchmark_runs.copy()
      runs.push({
        id: request.id,
        submission_id: request.submission_id,
        reviewer_id: request.reviewer_id,
        worker_run_id: "",
        state: "queued",
        reason: "",
        input_hash: "",
        output_hash: "",
        benchmark_version: version,
        metrics: [],
        evidence: [],
        queued_ms: now_ms,
        finished_ms: 0UL,
      })
      Some({ ..state, revision: state.revision + 1, benchmark_runs: runs, })
    }
    "start-benchmark" => {
      let request : RunIdRequest = @json.from_json(payload)
      let run = find_benchmark_run(state, request.run_id)
      require_competition_reviewer(
        state,
        run.submission_id,
        run.reviewer_id,
        now_ms,
      )
      guard run.state == "queued" else { fail("benchmark run is not queued") }
      let _ = current_evaluation_version(state, run.submission_id)
      Some(replace_benchmark_run(state, { ..run, state: "running", }))
    }
    "execute-benchmark" => {
      let request : RunIdRequest = @json.from_json(payload)
      let run = find_benchmark_run(state, request.run_id)
      require_competition_reviewer(
        state,
        run.submission_id,
        run.reviewer_id,
        now_ms,
      )
      guard run.state == "queued" else {
        fail("benchmark execution is already claimed or complete")
      }
      // The persisted queue is the command. HTTP only acknowledges it;
      // the background worker makes the exclusive running claim.
      Some(state)
    }
    "record-benchmark-result" => {
      let result : BenchmarkResult = @json.from_json(payload)
      let run = find_benchmark_run(state, result.run_id)
      let submission = evaluation_submission(state, run.submission_id)
      guard evaluation_program(state, submission.challenge_id).state != "final" else {
        fail("final competition receipts are frozen")
      }
      guard run.state == "running" else {
        fail("only a running benchmark can accept a worker receipt")
      }
      let current = run.benchmark_version ==
        current_evaluation_version(state, run.submission_id)
      guard benchmark_hash_valid(result.input_hash) &&
        benchmark_hash_valid(result.output_hash) &&
        !result.worker_run_id.trim().is_empty() else {
        fail("worker receipt requires input/output hashes and worker identity")
      }
      guard !result.evidence.is_empty() &&
        result.evidence.all(e => !e.trim().is_empty()) else {
        fail("worker receipt requires evidence")
      }
      if result.success && current {
        validate_measured_metrics(
          evaluation_track(
            state,
            evaluation_submission(state, run.submission_id),
          ),
          result.metrics,
        )
      } else if !result.success {
        guard !result.reason.trim().is_empty() else {
          fail("failed benchmark requires a reason")
        }
      }
      Some(
        replace_benchmark_run(state, {
          ..run,
          worker_run_id: result.worker_run_id,
          state: if result.success && current {
            "review"
          } else {
            "failed"
          },
          reason: if !current {
            "benchmark version changed during execution; retry with current benchmark"
          } else {
            result.reason
          },
          input_hash: result.input_hash,
          output_hash: result.output_hash,
          metrics: result.metrics,
          evidence: result.evidence,
          finished_ms: now_ms,
        }),
      )
    }
    "approve-benchmark" | "reject-benchmark" => {
      let request : ApproveBenchmarkRequest = @json.from_json(payload)
      let run = find_benchmark_run(state, request.run_id)
      require_competition_reviewer(
        state,
        run.submission_id,
        request.reviewer_id,
        now_ms,
      )
      guard request.reviewer_id == run.reviewer_id && run.state == "review" else {
        fail("the assigned reviewer must decide a measured result")
      }
      guard run.benchmark_version ==
        current_evaluation_version(state, run.submission_id) else {
        fail("benchmark version changed before approval")
      }
      let mut reason = run.reason
      if action == "approve-benchmark" {
        let track = evaluation_track(
          state,
          evaluation_submission(state, run.submission_id),
        )
        validate_measured_metrics(track, run.metrics)
        guard benchmark_hash_valid(run.input_hash) &&
          benchmark_hash_valid(run.output_hash) &&
          !run.evidence.is_empty() else {
          fail("approval requires a complete reproducibility receipt")
        }
        let failures = qualification_failure_reasons(track, run.metrics)
        if !failures.is_empty() {
          reason = (if run.reason.is_empty() { "" } else { run.reason + ". " }) +
            "Unranked: qualification gates failed. " +
            failures.join("; ")
        }
      }
      Some(
        replace_benchmark_run(state, {
          ..run,
          reason,
          state: if action == "approve-benchmark" {
            "approved"
          } else {
            "rejected"
          },
          finished_ms: now_ms,
        }),
      )
    }
    "retry-benchmark" => {
      let request : RunIdRequest = @json.from_json(payload)
      let run = find_benchmark_run(state, request.run_id)
      require_competition_reviewer(
        state,
        run.submission_id,
        run.reviewer_id,
        now_ms,
      )
      guard run.state == "failed" ||
        (
          run.state == "review" &&
          run.benchmark_version !=
          current_evaluation_version(state, run.submission_id)
        ) else {
        fail("only a failed or outdated pending review can be retried")
      }
      let id = "retry-" +
        state.revision.to_string() +
        "-" +
        run.queued_ms.to_string()
      // A retry is a new receipt, preserving the failed attempt and its hashes.
      apply_evaluation_action(
        state,
        "queue-benchmark",
        {
          "id": id,
          "submission_id": run.submission_id,
          "reviewer_id": run.reviewer_id,
        },
        now_ms,
      )
    }
    "recover-interrupted-benchmark" => {
      let request : RecoverBenchmarkRequest = @json.from_json(payload)
      let run = find_benchmark_run(state, request.run_id)
      let submission = evaluation_submission(state, run.submission_id)
      guard evaluation_program(state, submission.challenge_id).state != "final" &&
        ["queued", "running"].contains(run.state) &&
        !request.reason.trim().is_empty() else {
        fail(
          "recovering an interrupted queued or running worker requires an operator reason before finalization",
        )
      }
      let result = failed_benchmark_result(state, run.id, request.reason)
      let evidence = run.evidence.copy()
      for item in result.evidence {
        evidence.push(item)
      }
      Some(
        replace_benchmark_run(state, {
          ..run,
          worker_run_id: result.worker_run_id,
          state: "failed",
          reason: result.reason,
          input_hash: result.input_hash,
          output_hash: result.output_hash,
          evidence,
          finished_ms: now_ms,
        }),
      )
    }
    "open-appeal" => {
      let request : AppealRequest = @json.from_json(payload)
      let submission = evaluation_submission(state, request.submission_id)
      let program = evaluation_program(state, submission.challenge_id)
      guard program.state != "final" &&
        program.state != "draft" &&
        now_ms <= program.review_close_ms else {
        fail("appeals are closed")
      }
      guard valid_id(request.id) &&
        !request.reason.trim().is_empty() &&
        !state.appeals.any(a => {
          a.id == request.id ||
          (a.submission_id == request.submission_id && a.state == "open")
        }) else {
        fail(
          "appeal requires a unique ID and reason; an unresolved appeal already exists",
        )
      }
      guard state.teams.any(t => {
        t.id == submission.team_id && t.members.contains(request.member_id)
      }) else {
        fail("only a submission team member can appeal")
      }
      guard state.benchmark_runs.any(r => {
          r.submission_id == submission.id &&
          ["approved", "rejected", "failed"].contains(r.state)
        }) ||
        state.evaluations.any(e => e.submission_id == submission.id) else {
        fail("appeal requires a completed evaluation receipt")
      }
      let appeals = state.appeals.copy()
      appeals.push({
        id: request.id,
        submission_id: request.submission_id,
        member_id: request.member_id,
        reason: request.reason,
        state: "open",
        resolution: "",
        created_ms: now_ms,
        resolved_ms: 0UL,
      })
      Some({ ..state, revision: state.revision + 1, appeals, })
    }
    "resolve-appeal" => {
      let request : ResolveAppealRequest = @json.from_json(payload)
      guard state.appeals.iter().find_first(a => a.id == request.appeal_id)
        is Some(appeal) else {
        fail("appeal was not found")
      }
      let submission = evaluation_submission(state, appeal.submission_id)
      guard evaluation_program(state, submission.challenge_id).state != "final" &&
        appeal.state == "open" &&
        !request.resolution.trim().is_empty() else {
        fail("only an open appeal can be resolved before finalization")
      }
      let appeals = state.appeals.map(a => {
        if a.id == appeal.id {
          {
            ..a,
            state: "resolved",
            resolution: request.resolution,
            resolved_ms: now_ms,
          }
        } else {
          a
        }
      })
      Some({ ..state, revision: state.revision + 1, appeals, })
    }
    _ => None
  }
}
