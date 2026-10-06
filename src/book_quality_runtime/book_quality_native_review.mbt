///|
async fn native_review_request(
  score : @book_quality.BookQualityScore,
  catalog_path : String,
  review_dir : String,
  result_dir : String,
) -> @native_work.Request {
  let packet = @book_quality.review_packet(score, review_dir)
  let context : Array[String] = [
    packet.prompt,
    "\n" + @book_quality.review_skill_markdown(),
    "\nSelected Book context (captured by MoonTown):",
  ]
  let mut blocker = ""
  for relative in packet.context_pages {
    if relative.has_prefix("/") || relative.split("/").any(part => part == "..") {
      blocker = "review_context_path_invalid"
      continue
    }
    let path = score.workspace_root + "/" + relative
    if !@fs.exists(path) {
      context.push("\n" + relative + ": absent at request creation")
      continue
    }
    if @fs.kind(path, follow_symlink=false) != Regular ||
      @fs.realpath(path) != path {
      blocker = "review_context_not_canonical: " + relative
      continue
    }
    let file = @fs.open(path, mode=ReadOnly)
    defer file.close()
    if file.size() > 1_000_000L {
      blocker = "review_context_too_large: " + relative
      continue
    }
    let content = file.read_all().text()
    context.push(
      "\nFile: " +
      relative +
      "\nSHA256: " +
      @native_work.digest(content) +
      "\n" +
      content,
    )
  }
  context.push(
    "\nDo not modify authored Book content. Return only the required semantic review contract through finish; MoonTown owns result storage. Do not start workers, commands, external tools, or web searches.",
  )
  let prompt = context.join("\n")
  if prompt.length() > 2_000_000 {
    blocker = "review_context_too_large: full context retained, dispatch blocked"
  }
  {
    kind: "book_quality_review",
    work_key: "book_quality_review:" + score.book_id,
    generation: 0,
    owner_workspace: @storage.moontown_active_workspace_root(),
    book_id: score.book_id,
    book_root: score.workspace_root,
    book_type: score.book_type,
    catalog_path,
    execution_root: score.workspace_root,
    source_binding: { "kind": "registered_book", "root": score.workspace_root },
    criterion_id: "",
    model_request: "",
    prompt,
    input_blocker: blocker,
    input_digest: @native_work.digest(prompt),
    output_contract: @book_quality.review_output_contract(),
    result_path: @book_quality.review_result_path(result_dir, score.book_id),
    acceptance_policy: {
      "task_intent": "read_only",
      "runtime_enforcement_required": true,
    },
    created_at_ms: @env.now(),
  }
}

///|
async fn dispatch_next_native_book_quality_review(
  catalog_path : String,
  snapshot_path : String,
  review_dir : String,
  result_dir : String,
  run_path : String,
  client? : @native_code_control.Client,
) -> String {
  // Preserve observation of historical ACP runs, but never re-import old
  // automatic ACP packets. Native state is the sole new default producer.
  ignore(reconcile_book_quality_ai_review_results(result_dir~, run_path~))
  let active = active_book_quality_review_count(result_dir, run_path)
  if active > 0 {
    return @book_quality.active_review_dispatch_message(active)
  }
  let path = @native_work.path_for_snapshot(snapshot_path)
  let state = @native_work.load(path~)
  for work in state.work {
    if work.request.kind == "book_quality_review" &&
      !@native_work.terminal(work.state) {
      return @native_work.summary(
        @native_work.sync(work.id, @env.now(), path~, client?),
      )
    }
  }
  ignore(
    write_book_quality_review_packets(
      book_catalog_path=catalog_path,
      snapshot_path~,
      review_dir~,
    ),
  )
  let audit = inspect_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  guard first_pending_review_score(audit, result_dir) is Some(score) else {
    return @book_quality.no_pending_review_dispatch_message(result_dir)
  }
  let work = @native_work.enqueue(
    native_review_request(score, catalog_path, review_dir, result_dir),
    path~,
  )
  @native_work.summary(@native_work.sync(work.id, @env.now(), path~, client?))
}
