///|
fn pending_participant(
  p : WorkInput,
  detail : String,
) -> @contract.ParticipantWork {
  {
    book_id: p.book_id,
    packet_id: p.packet_id,
    proposal_id: p.proposal_id,
    run_id: p.run_id,
    status: "pending",
    detail,
    output_ref: "",
    output_digest: "",
    output_text: "",
  }
}

///|
async fn Store::collect_participant(
  self : Store,
  saved : @contract.SavedDraft,
  intent : WorkIntent,
  p : WorkInput,
) -> @contract.ParticipantWork {
  let root = self.work_root(saved)
  let terminal_path = root + "/produced/" + p.book_id + "/terminal.json"
  if kind(terminal_path) is Some(Regular) {
    let value : @contract.ParticipantWork = @json.from_json(
      @json.parse(text_bytes(read_bytes(terminal_path, 2097152))),
    )
    guard value.book_id == p.book_id &&
      value.packet_id == p.packet_id &&
      value.proposal_id == p.proposal_id &&
      value.run_id == p.run_id &&
      ["completed", "failed"].contains(value.status) else {
      raise CollaborationError("Retained participant result changed identity")
    }
    if value.status == "completed" {
      guard value.output_ref ==
        revision_prefix(saved) + "oneoff/produced/" + p.book_id + "/report.md" else {
        raise CollaborationError("Retained output reference changed")
      }
      let bytes = read_bytes(
        self.draft_root(saved.draft.draft_id) + "/" + value.output_ref,
        1048576,
      )
      guard digest(bytes) == value.output_digest &&
        text_bytes(bytes) == value.output_text else {
        raise CollaborationError("Retained participant output bytes changed")
      }
    }
    return value
  }
  let poll = @moonclaw.poll_run(
    p.packet_id,
    p.run_id,
    home=intent.store_home,
    cwd=p.workspace,
    detect_orphan=false,
  )
  let status = poll.to_json()
  let current = pending_participant(p, poll.summary)
  // poll_run is the production collector. Unknown is deliberately pending,
  // never a success inferred from a receipt, file name or provider summary.
  let terminal = if status is { "status": "Completed", .. } {
    guard @moonclaw.run_workspace_dir(
        p.run_id,
        home=intent.store_home,
        cwd=p.workspace,
      )
      is Some(workspace) else {
      raise CollaborationError("Completed run has no indexed output workspace")
    }
    directory(workspace, false)
    let report = read_bytes(workspace + "/report.md", 1048576)
    let result = read_bytes(workspace + "/result.json", 1048576)
    let text = text_bytes(report)
    guard !text.trim().is_empty() else {
      raise CollaborationError(
        "Completed participant returned no usable contribution",
      )
    }
    ignore(@json.parse(text_bytes(result)))
    let output_ref = revision_prefix(saved) +
      "oneoff/produced/" +
      p.book_id +
      "/report.md"
    write_bytes(
      self.draft_root(saved.draft.draft_id) + "/" + output_ref,
      report,
    )
    write_bytes(root + "/produced/" + p.book_id + "/result.json", result)
    {
      ..current,
      status: "completed",
      output_ref,
      output_digest: digest(report),
      output_text: text,
    }
  } else if status is { "status": "Failed", .. } {
    { ..current, status: "failed", }
  } else {
    let diagnostics : Array[String] = []
    for suffix in [".stderr", ".stdout"] {
      let log = root + "/logs/" + p.book_id + suffix
      if kind(log) is Some(Regular) {
        let bytes = read_bytes(log, 1048576) catch { _ => b"" }
        let text = text_bytes(bytes) catch { _ => "" }
        if !text.trim().is_empty() {
          diagnostics.push(text)
        }
      }
    }
    let detail = {
      let text = diagnostics.join("\n")
      if !text.trim().is_empty() {
        "Runtime outcome is not yet indexed. Check the configured profile/model and retained runtime log. Frozen profile inputs stay unchanged: save a changed source/question revision to use corrected profile settings; unchanged Start only reconciles existing inputs. Diagnostic: " +
        (if text.length() <= 2000 { text } else { text[:2000].to_owned() })
      } else {
        current.detail
      }
    }
    return { ..current, status: "pending", detail, }
  }
  write_bytes(
    terminal_path,
    @utf8.encode(terminal.to_json().stringify(indent=2)),
  )
  terminal
}

///|
async fn Store::collect_work(
  self : Store,
  saved : @contract.SavedDraft,
  intent : WorkIntent,
) -> @contract.OneoffWork {
  let participants : Array[@contract.ParticipantWork] = []
  for p in intent.participants {
    participants.push(self.collect_participant(saved, intent, p))
  }
  let complete = participants.all(p => {
    p.status == "completed" || p.status == "failed"
  })
  let all_succeeded = participants.all(p => p.status == "completed")
  let mut view = {
    ..@contract.empty_work(saved.draft.draft_id, saved.revision),
    participants,
    status: if all_succeeded {
      "completed"
    } else if complete {
      "partial"
    } else {
      "running"
    },
    detail: if all_succeeded {
      "Actual participant outputs retained. Review the exact collected result before exporting an outcome."
    } else if complete {
      "Partial result retained with failures visible. This revision will not rerun participants. Revise the saved question to start new work."
    } else {
      "One-off work is pending or running. Refresh or repeat Start to reconcile the same work; uncertain running work is never replayed."
    },
  }
  if complete {
    let result = collected_result(saved, intent.source_digest, participants)
    let bytes = @utf8.encode(result.stringify(indent=2))
    write_bytes(self.work_root(saved) + "/result.json", bytes)
    view = {
      ..view,
      result_digest: digest(bytes),
      result_text: text_bytes(bytes),
      review_status: "pending_review",
    }
    view = self.project_work_review(saved, view)
  }
  self.project_book_readback(saved, view)
}

///|
fn collected_result(
  saved : @contract.SavedDraft,
  source_digest : String,
  participants : Array[@contract.ParticipantWork],
) -> Json {
  {
    "contract_version": "moontown.collaboration-result.v1",
    "draft_id": saved.draft.draft_id,
    "revision": saved.revision,
    "question": saved.draft.question,
    "source_packet_digest": source_digest,
    "sources": saved.sources.to_json(),
    "participants": participants.to_json(),
    "assembly": "Exact attributed participant outputs and failures. This is a collected dossier, not an invented consensus or model synthesis.",
    "all_participants_succeeded": participants.all(p => p.status == "completed"),
    "successful_participants": participants
    .filter(p => p.status == "completed")
    .length(),
    "failed_participants": participants
    .filter(p => p.status == "failed")
    .length(),
  }
}

///|
pub async fn Store::start_oneoff(
  self : Store,
  id : String,
  revision : String,
  runtime : OneoffRuntime,
  background? : Bool = false,
) -> @contract.OneoffWork {
  let (saved, intent) = self.locked(() => {
    let saved = self.load_revision(id, revision)
    ignore(self.verify_prepared(saved))
    let root = self.work_root(saved)
    let intent = if kind(root + "/intent.json") is None {
      guard self.current_revision(id) == revision else {
        raise CollaborationError(
          "A newer saved revision exists. Reopen it before starting new work",
        )
      }
      self.create_work_intent(saved, runtime)
    } else {
      self.work_intent(saved)
    }
    guard intent.runtime == runtime else {
      raise CollaborationError(
        "Runtime configuration changed. Reopen retained results; use a new source revision for new work",
      )
    }
    directory(root + "/logs", true)
    (saved, intent)
  })
  let root = self.work_root(saved)
  for p in intent.participants {
    if kind(root + "/produced/" + p.book_id + "/terminal.json") is Some(Regular) {
      continue
    }
    // Producer reconciles an exact stable packet before starting anything.
    // A failed host reply is intentionally not converted into a failed run.
    try {
      if background {
        ignore(
          @moonclaw.launch_oneoff(
            p.packet_path,
            moonclaw_root=runtime.moonclaw_root,
            home=runtime.home,
            store_home=intent.store_home,
            cwd=p.workspace,
            log_prefix=root + "/logs/" + p.book_id,
          ),
        )
      } else {
        let receipt = @moonclaw.start_oneoff(
          p.packet_path,
          moonclaw_root=runtime.moonclaw_root,
          home=runtime.home,
          store_home=intent.store_home,
          cwd=p.workspace,
        )
        guard receipt.packet_id == p.packet_id &&
          receipt.proposal_id == p.proposal_id &&
          receipt.run_id == p.run_id else {
          raise CollaborationError(
            "MoonClaw returned an unrelated one-off identity",
          )
        }
      }
    } catch {
      error =>
        return {
          ..self.locked(() => self.collect_work(saved, self.work_intent(saved))),
          detail: "Runtime start or reply is unavailable: " +
          error_message(error) +
          " Retry Start to reconcile the same stable request. Check the installed MoonClaw oneoff command and its configured profile/model.",
        }
    }
  }
  self.locked(() => self.collect_work(saved, self.work_intent(saved)))
}

///|
pub async fn Store::read_oneoff(
  self : Store,
  id : String,
  revision : String,
) -> @contract.OneoffWork {
  self.locked(() => {
    let saved = self.load_revision(id, revision)
    ignore(self.verify_prepared(saved))
    if kind(self.work_root(saved) + "/intent.json") is None {
      @contract.empty_work(id, revision)
    } else {
      self.collect_work(saved, self.work_intent(saved))
    }
  })
}
