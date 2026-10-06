///|
async fn load_material_watch_journal(
  directory : String,
) -> MaterialWatchJournal? {
  let path = directory + "/journal.json"
  if !@fs.exists(path) {
    return None
  }
  let journal : MaterialWatchJournal = @json.from_json(
    @json.parse(@fs.read_file(path).text()),
  )
  guard journal.contract == "moontown.material_watch.v1" else {
    fail("Unsupported material-watch journal; retain it for repair")
  }
  for change in journal.changes {
    guard change.input.goal.id == journal.goal_id &&
      change.input.plan.book_id == journal.book_id else {
      fail("Material-watch journal identity does not match its saved goal")
    }
    let saved : MaterialWatchInput = @json.from_json(
      @json.parse(@fs.read_file(change.input_path).text()),
    )
    guard saved == change.input else {
      fail("Material-watch input changed; original review binding retained")
    }
  }
  Some(journal)
}

///|
async fn save_material_watch_journal(
  directory : String,
  journal : MaterialWatchJournal,
) -> Unit {
  let path = directory + "/journal.json"
  @fs.write_file(
    path + ".pending",
    @utf8.encode(journal.to_json().stringify()),
    create_mode=CreateOrTruncate,
  )
  @fs.rename(path + ".pending", path, replace=true)
}

///|
async fn remember_material_watch_execution(
  directory : String,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  guard load_material_watch_journal(directory) is Some(journal) else { return }
  guard execution.book_id == journal.book_id else {
    fail("Material-watch observation belongs to a different Book")
  }
  for change in journal.changes {
    if change.input.task_id == execution.task_id &&
      change.execution is Some(saved) &&
      saved.run_id is Some(old_run) &&
      execution.run_id is Some(run) &&
      old_run != run {
      fail("Material-watch observation conflicts with the retained run")
    }
  }
  let changes = journal.changes.map(change => {
    if change.input.task_id == execution.task_id {
      let selected = select_material_watch_execution(change, Some(execution)).unwrap()
      {
        ..change,
        execution: Some(bind_material_watch_execution(selected, change)),
      }
    } else {
      change
    }
  })
  save_material_watch_journal(directory, { ..journal, changes, })
}

///|
async fn remember_material_watch_receipt(
  directory : String,
  execution : @core.TaskExecutionRecord,
  receipt : @moonbook.PersistResultOutcome,
) -> Unit {
  guard load_material_watch_journal(directory) is Some(journal) else { return }
  save_material_watch_journal(
    directory,
    merge_material_watch_receipt(journal, execution, receipt),
  )
}

///|
fn merge_material_watch_receipt(
  journal : MaterialWatchJournal,
  execution : @core.TaskExecutionRecord,
  receipt : @moonbook.PersistResultOutcome,
) -> MaterialWatchJournal raise {
  guard journal.book_id == execution.book_id &&
    receipt.executable_event.book_id == execution.book_id &&
    receipt.executable_event.result_id == execution.task_id &&
    (
      receipt.executable_event.run_id is None ||
      receipt.executable_event.run_id == execution.run_id
    ) else {
    fail("Book receipt does not match the retained material-watch task/run")
  }
  let changes = []
  let mut matched = false
  for change in journal.changes {
    if change.input.task_id != execution.task_id {
      changes.push(change)
      continue
    }
    matched = true
    ignore(select_material_watch_execution(change, Some(execution)))
    if change.execution is Some(saved) && saved.run_id is Some(run) {
      guard execution.run_id == Some(run) &&
        (
          receipt.executable_event.run_id is None ||
          receipt.executable_event.run_id == Some(run)
        ) else {
        fail(
          "Book receipt run conflicts with the durable material-watch reservation",
        )
      }
    }
    if change.book_receipt is Some(saved) {
      guard saved.executable_event.id == receipt.executable_event.id &&
        saved.evidence_id == receipt.evidence_id else {
        fail(
          "Book receipt identity conflicts with the original material-watch review",
        )
      }
      changes.push(change)
    } else {
      changes.push({ ..change, book_receipt: Some(receipt), })
    }
  }
  guard matched else { fail("Book receipt has no material-watch reservation") }
  { ..journal, changes, }
}

///|
/// The normal supervision persistence path runs outside the watch-cycle lock.
/// Publish the typed receipt before attempting the lock so an acknowledgement
/// cannot disappear while another cycle owns the journal.
async fn retain_material_watch_book_receipt(
  execution : @core.TaskExecutionRecord,
  receipt : @moonbook.PersistResultOutcome,
) -> Unit {
  guard @standing_watch_policy.standing_watch_marker_value(
      execution.summary,
      "material_watch_input",
    )
    is Some(input_path) &&
    execution.context_pages.contains(input_path) else {
    return
  }
  let directory = @storage.snapshot_base_dir(input_path)
  if !input_path.has_suffix(
      "/input-" + material_watch_hash(execution.task_id) + ".json",
    ) ||
    !@fs.exists(directory + "/journal.json") {
    return
  }
  stage_material_watch_receipt(directory, execution, receipt)
  let lock = @fs.open(
    directory + "/watch.lock",
    mode=ReadWrite,
    create_mode=OpenExisting,
  )
  defer lock.close()
  if !lock.try_lock(Exclusive) {
    return
  }
  reconcile_material_watch_receipts(directory)
}
