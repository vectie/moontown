///|
pub fn Mayor::handoff_to_keeper(
  self : Mayor,
  book : @core.BookRef,
  objective : String,
  scope_summary : String,
  constraints? : Array[String] = [],
) -> @moonclaw.EmbeddedRuntimeHandoff {
  ignore(self)
  @moonclaw.mayor_to_keeper_handoff(
    book.id,
    objective,
    scope_summary,
    constraints~,
  )
}

///|
pub async fn Mayor::prepare_keeper_packet(
  self : Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  packet_dir? : String = @moonclaw.default_packet_directory(),
) -> MayorKeeperPacket {
  let bundle = @moonbook.hydrate_worker_context(entry, task)
  let packet_id = keeper_packet_id(entry.id, task.id)
  let profile = moonclaw_profile_for_entry_task(entry, task)
  let packet = @moonclaw.proposal_packet_from_bundle(
    bundle,
    task.title,
    "Mayor issued a keeper packet for \{entry.name}.",
    profile,
    packet_id=Some(packet_id),
    task=Some(task),
    entry=Some(entry),
    notes=["produced by mayor runtime", "book task kind=\{task.kind}"],
    tags=[entry.id, task.kind, "keeper"],
  )
  {
    handoff: self.handoff_to_keeper(
      entry.to_book_ref(),
      task.title,
      bundle.memory_summary,
      constraints=["follow packet-first handoff", "keep book memory isolated"],
    ),
    packet,
    packet_path: @moonclaw.packet_file_path(packet_dir, packet.packet_id),
    rationale: "Mayor prepared keeper packet \{packet.packet_id} for \{entry.id} / \{task.id}.",
  }
}

///|
pub fn keeper_runtime(
  book : @core.BookRef,
) -> @moonclaw.EmbeddedMoonclawRuntime {
  @moonclaw.keeper_runtime(book)
}

///|
pub fn keeper_packet_id(book_id : String, task_id : String) -> String {
  let hash = task_id.hash().to_string().trim(chars="-").to_owned()
  let prefix = compact_id_segment(book_id, 24)
  let body = compact_id_segment(task_id, 40)
  "keeper-\{prefix}-\{body}-\{hash}"
}

///|
fn compact_id_segment(text : String, limit : Int) -> String {
  let builder = StringBuilder::new()
  let mut emitted = 0
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      if emitted >= limit {
        break
      }
      builder.write_char(char)
      emitted += 1
      last_dash = false
    } else if !last_dash && emitted > 0 {
      if emitted >= limit {
        break
      }
      builder.write_char('-')
      emitted += 1
      last_dash = true
    }
  }
  let slug = builder.to_string().trim(chars="-").to_owned()
  if slug.is_blank() {
    "task"
  } else {
    slug
  }
}

///|
fn moonclaw_profile_for_task(task : @moonbook.BookTask) -> String {
  if @dispatch.research_bootstrap_book_task(task) {
    return "moontown_research_bootstrap_worker"
  }
  match task.kind {
    "standing-watch" => "wiki_ingest_controller"
    "implementation-backlog"
    | "code-patch"
    | "image-asset"
    | "projection-schema"
    | "test-fix" => "wenyu_build_controller"
    "ingest" | "ingest-followup" => "wiki_ingest_controller"
    "review" | "planning" => "wiki_lint_controller"
    "analysis" | "synthesis" => "wiki_query_controller"
    _ => "wiki_query_controller"
  }
}

///|
fn moonclaw_profile_for_entry_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> String {
  if entry.id == "plan-moontown-quality" {
    return "planbook_repair_worker"
  }
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(_) => "wenyu_civic_service_worker"
    None => moonclaw_profile_for_task(task)
  }
}
