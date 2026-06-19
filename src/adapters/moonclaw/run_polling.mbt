///|
pub async fn poll_run(
  task_id : String,
  run_id : String,
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  detect_orphan? : Bool = true,
) -> ProposalPollResponse {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  match load_run(run_id, resolved_home) {
    Some(run) => {
      let workspace_dir = run.workspace_dir.unwrap_or(resolved_cwd)
      let result_payload = load_run_result_payload(workspace_dir)
      let indexed_status = town_status_for_run_status(run.status)
      let orphaned = detect_orphan &&
        orphan_detectable_run_status(indexed_status) &&
        !moonclaw_run_process_alive(run.id)
      let status : @core.TaskExecutionStatus = if orphaned {
        Failed
      } else {
        indexed_status
      }
      let result_text = moonclaw_result_payload_text(result_payload)
      let result_decision = guarded_moonclaw_result_decision(
        parse_json_string(result_payload, "result_decision").unwrap_or(
          if status == Failed {
            "blocked"
          } else if status == Completed {
            "accepted"
          } else {
            "pending"
          },
        ),
        result_text,
      )
      let requires_review = parse_json_bool(result_payload, "requires_review").unwrap_or(
          false,
        ) ||
        moonclaw_result_text_requires_review(result_text)
      {
        task_id,
        run_id,
        status,
        summary: if orphaned {
          "MoonClaw run \{run.id} is indexed as Running, but no live proposal process was found; treating it as failed for mayor recovery."
        } else {
          run_summary(run, result_payload)
        },
        memory_candidates: [],
        result_decision,
        requires_review,
        notify_town: parse_json_bool(result_payload, "notify_town").unwrap_or(
          status == Completed,
        ),
      }
    }
    None =>
      {
        task_id,
        run_id,
        status: Running,
        summary: "Run \{run_id} has not been indexed in MoonClaw yet.",
        memory_candidates: [],
        result_decision: "pending",
        requires_review: false,
        notify_town: false,
      }
  }
}

///|
fn moonclaw_result_payload_text(payload : Json) -> String {
  match parse_json_string(payload, "content") {
    Some(content) => content
    None =>
      match parse_json_string(payload, "summary") {
        Some(summary) => summary
        None => ""
      }
  }
}

///|
fn guarded_moonclaw_result_decision(
  decision : String,
  result_text : String,
) -> String {
  if moonclaw_result_text_requires_review(result_text) {
    "needs_review"
  } else {
    decision
  }
}

///|
fn moonclaw_result_text_requires_review(result_text : String) -> Bool {
  if result_text.is_empty() {
    return false
  }
  for raw in result_text.split("\n") {
    let line = raw.trim().to_owned().to_lower()
    if line.contains("pass/fail:** fail") ||
      line.contains("pass/fail: fail") ||
      line.contains("review outcome: rejected") ||
      line.contains("result should be rejected") {
      return true
    }
  }
  false
}

///|
fn orphan_detectable_run_status(status : @core.TaskExecutionStatus) -> Bool {
  status == RunConfirmed || status == Running
}

///|
pub async fn run_workspace_dir(
  run_id : String,
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
) -> String? {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  load_run(run_id, resolved_home).bind(fn(run) { run.workspace_dir })
}

///|
pub async fn run_process_alive(run_id : String) -> Bool {
  moonclaw_run_process_alive(run_id)
}

///|
async fn moonclaw_run_process_alive(run_id : String) -> Bool {
  let listed = @integration.run_checked("ps", ["-ef"]) catch {
    _ => return false
  }
  for line in listed.stdout.split("\n") {
    if moonclaw_process_line_is_proposal_run(line.to_owned(), run_id) {
      return true
    }
  }
  false
}

///|
fn moonclaw_process_line_is_proposal_run(
  line : String,
  run_id : String,
) -> Bool {
  let tokens : Array[String] = []
  for token in line.split(" ") {
    let token = token.trim().to_owned()
    if !token.is_blank() {
      tokens.push(token)
    }
  }
  if tokens.length() < 4 {
    return false
  }
  for index in 1..<(tokens.length() - 2) {
    if tokens[index - 1] == "--" &&
      tokens[index] == "proposal" &&
      tokens[index + 1] == "run" &&
      tokens[index + 2] == run_id {
      return true
    }
  }
  false
}
