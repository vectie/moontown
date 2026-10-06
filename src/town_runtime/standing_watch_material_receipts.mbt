///|
priv struct MaterialWatchPendingReceipt {
  contract : String
  execution : @core.TaskExecutionRecord
  receipt : @moonbook.PersistResultOutcome
} derive(ToJson, FromJson)

///|
async fn stage_material_watch_receipt(
  directory : String,
  execution : @core.TaskExecutionRecord,
  receipt : @moonbook.PersistResultOutcome,
) -> Unit {
  guard load_material_watch_journal(directory) is Some(journal) else {
    fail("Material-watch receipt has no durable journal")
  }
  ignore(merge_material_watch_receipt(journal, execution, receipt))
  let pending : MaterialWatchPendingReceipt = {
    contract: "moontown.material_watch_receipt.v1",
    execution,
    receipt,
  }
  let text = ToJson::to_json(pending).stringify()
  let path = directory + "/receipt-" + material_watch_hash(text) + ".json"
  if @fs.exists(path) {
    guard @fs.read_file(path).text() == text else {
      fail("Retained material-watch receipt bytes conflict")
    }
    return
  }
  // Different contenders never truncate each other's staging bytes. Only a
  // complete file is renamed into the receipt inbox; partial files stay .tmp.
  for index = 0; ; index = index + 1 {
    let temp = path + ".pending-\{index}.tmp"
    @fs.write_file(temp, @utf8.encode(text), create_mode=CreateNew) catch {
      @os_error.OSError(_) as error if error.is_EEXIST() => continue
      error => raise error
    }
    @fs.rename(temp, path, replace=false) catch {
      error => {
        if !@fs.exists(path) {
          raise error
        }
        guard @fs.read_file(path).text() == text else { raise error }
        @fs.remove(temp)
      }
    }
    return
  }
}

///|
/// Called under the existing per-goal lock. The immutable inbox also survives
/// a crash between the receiver acknowledgement and the journal checkpoint.
async fn reconcile_material_watch_receipts(directory : String) -> Unit {
  guard load_material_watch_journal(directory) is Some(original) else { return }
  let mut journal = original
  for name in @fs.readdir(directory, sort=true) {
    if !name.has_prefix("receipt-") || !name.has_suffix(".json") {
      continue
    }
    let text = @fs.read_file(directory + "/" + name).text()
    let pending : MaterialWatchPendingReceipt = @json.from_json(
      @json.parse(text),
    )
    guard pending.contract == "moontown.material_watch_receipt.v1" &&
      name == "receipt-" + material_watch_hash(text) + ".json" else {
      fail("Material-watch receipt inbox entry needs repair: " + name)
    }
    journal = merge_material_watch_receipt(
      journal,
      pending.execution,
      pending.receipt,
    )
    let confirmed = execution_after_successful_book_persist(
      pending.execution,
      pending.receipt,
      pending.execution.heartbeat_tick,
    )
    let changes = journal.changes.map(change => {
      if change.input.task_id != confirmed.task_id {
        change
      } else {
        let selected = select_material_watch_execution(change, Some(confirmed)).unwrap()
        {
          ..change,
          execution: Some(bind_material_watch_execution(selected, change)),
        }
      }
    })
    journal = { ..journal, changes, }
  }
  if journal != original {
    save_material_watch_journal(directory, journal)
  }
}
