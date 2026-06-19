///|
fn moonclaw_runtime_book_task(
  id~ : String,
  title~ : String,
  kind~ : String,
  prompt~ : String,
  priority? : Int = 100,
  requires_review? : Bool = true,
  target_pages? : Array[String] = [],
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id~,
    title~,
    kind~,
    prompt~,
    priority~,
    requires_review~,
    target_pages~,
  )
}

///|
fn moonclaw_runtime_bootstrap_ingest_task(
  id? : String = "task-bootstrap",
) -> @moonbook.BookTask {
  moonclaw_runtime_book_task(
    id~,
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    target_pages=["raw/bootstrap/research-question.md"],
  )
}

///|
fn moonclaw_runtime_standing_watch_task(
  id~ : String,
  title~ : String,
  prompt~ : String,
  target_pages? : Array[String] = [],
  priority? : Int = 95,
) -> @moonbook.BookTask {
  moonclaw_runtime_book_task(
    id~,
    title~,
    kind="standing-watch",
    prompt~,
    priority~,
    requires_review=false,
    target_pages~,
  )
}

///|
async fn test_ignore_checked_command(
  command : String,
  args : Array[String],
) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}

///|
async fn test_write_text_file(path : String, content : String) -> Unit {
  moonclaw_write_text_file(path, content)
}
