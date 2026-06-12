///|
pub async fn write_protocol_jsonl_record(
  building_id : String,
  ledger : String,
  value : Json,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Unit {
  @support.write_text_file(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
    value.stringify() + "\n",
  )
}

///|
pub async fn write_protocol_jsonl_records(
  building_id : String,
  ledger : String,
  values : Array[Json],
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Unit {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string(value.stringify())
    builder.write_char('\n')
  }
  @support.write_text_file(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
    builder.to_string(),
  )
}

///|
pub async fn count_protocol_jsonl_records(
  building_id : String,
  ledger : String,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Int {
  let text = @support.read_text_or_empty(
    protocol_ledger_path(building_id, ledger, ledger_base_dir~),
  )
  let mut count = 0
  for raw in text.split("\n") {
    if !raw.trim().is_empty() {
      count += 1
    }
  }
  count
}
