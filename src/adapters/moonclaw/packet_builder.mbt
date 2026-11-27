///|
pub fn default_packet_directory() -> String {
  @storage.moontown_product_artifact("packets")
}

///|
pub fn packet_file_path(packet_dir : String, packet_id : String) -> String {
  "\{packet_dir}/\{packet_id}.json"
}

///|
pub fn proposal_packet_from_bundle(
  bundle : @moonbook.WorkerContextBundle,
  title : String,
  summary : String,
  profile : String,
  packet_id~ : String? = None,
  task~ : @moonbook.BookTask? = None,
  entry~ : @moonbook.BookCatalogEntry? = None,
  notes~ : Array[String] = [],
  tags~ : Array[String] = [],
) -> ExternalProposalPacket {
  let resolved_packet_id = packet_id.unwrap_or("packet-\{bundle.task_id}")
  {
    packet_id: resolved_packet_id,
    title,
    summary,
    request_text: bundle.prompt,
    profile,
    output_contract: packet_output_contract(bundle.output_contract),
    context_pages: bundle.context_pages,
    skill_paths: bundle.skill_paths,
    notes,
    tags,
    metadata: packet_bundle_metadata(bundle, task, entry),
  }
}

///|
fn packet_bundle_metadata(
  bundle : @moonbook.WorkerContextBundle,
  task : @moonbook.BookTask?,
  entry : @moonbook.BookCatalogEntry?,
) -> Json {
  let fields = packet_no_input_policy_fields()
  fields["producer"] = ToJson::to_json("moontown")
  fields["book_id"] = ToJson::to_json(bundle.book_id)
  fields["workspace_root"] = ToJson::to_json(bundle.workspace_root)
  fields["task_id"] = ToJson::to_json(bundle.task_id)
  fields["memory_summary"] = ToJson::to_json(bundle.memory_summary)
  fields["profile_metadata"] = packet_no_input_policy_json()
  fields["step_metadata"] = packet_step_metadata(task)
  set_policy_metadata(fields, entry)
  Json::object(fields)
}

///|
fn set_policy_metadata(
  fields : Map[String, Json],
  entry : @moonbook.BookCatalogEntry?,
) -> Unit {
  match entry {
    Some(entry) => {
      let policy_fields = @core.json_object_copy(
        Some(
          @policy.catalog_policy_context_metadata(
            entry.id,
            entry.name,
            entry.tags,
          ),
        ),
      )
      for key, value in policy_fields {
        fields[key] = value
      }
    }
    None => ()
  }
}

///|
fn packet_step_metadata(task : @moonbook.BookTask?) -> Json {
  let fields = packet_no_input_policy_fields()
  match task {
    Some(task) => {
      let route = packet_task_route(task)
      let task_spec = packet_task_spec_json(task, route)
      set_extension_step_metadata(fields, "task_id", ToJson::to_json(task.id))
      set_extension_step_metadata(fields, "task_spec", task_spec)
      set_extension_step_metadata(
        fields,
        "task_kind",
        ToJson::to_json(route.kind),
      )
      set_extension_step_metadata(
        fields,
        "priority",
        ToJson::to_json(task.priority),
      )
      set_extension_step_metadata(
        fields,
        "requires_review",
        ToJson::to_json(task.requires_review),
      )
      set_extension_step_metadata(
        fields,
        "target_pages",
        ToJson::to_json(route.target_pages),
      )
    }
    None => ()
  }
  Json::object(fields)
}

///|
fn packet_task_spec_json(
  task : @moonbook.BookTask,
  route : PacketTaskRoute,
) -> Json {
  {
    "id": task.id,
    "title": task.title,
    "kind": route.kind,
    "prompt": route.prompt,
    "priority": task.priority,
    "requires_review": task.requires_review,
    "target_pages": route.target_pages,
  }
}

///|
fn set_extension_step_metadata(
  fields : Map[String, Json],
  suffix : String,
  value : Json,
) -> Unit {
  fields.set("extension_\{suffix}", value)
}

///|
fn packet_output_contract(lines : Array[String]) -> String {
  if lines.is_empty() {
    "Return exactly one JSON object."
  } else {
    lines.join("\n")
  }
}
