///|
pub async fn save_book_template_request_ledger(
  request_path : String,
  ledger : BookTemplateRequestLedger,
) -> Unit {
  write_text_file(request_path, ledger.to_json().stringify(indent=2))
}

///|
async fn load_book_template_request_ledger(
  request_path : String,
) -> BookTemplateRequestLedger {
  if !@fs.exists(request_path) {
    return { requests: [] }
  }
  let text = @fs.read_file(request_path).text() catch {
    _ => return { requests: [] }
  }
  let parsed = @json.parse(text) catch { _ => return { requests: [] } }
  @json.from_json(parsed) catch {
    _ => { requests: [] }
  }
}
