///|
pub fn empty_runtime_state() -> PackBridgeRuntimeState {
  {
    contract_id: "moontown.pack-bridge-runtime.v1",
    projections: @pack_town_bridge.empty_registry(),
    capabilities: [],
    lifecycles: [],
    candidates: [],
    candidate_envelopes: [],
  }
}

///|
fn migrate_runtime_state_json(value : Json) -> Json {
  guard value is Object(fields) else { return value }
  if fields.get("capabilities") is None {
    fields["capabilities"] = ([] : Array[Json]).to_json()
  }
  if fields.get("candidate_envelopes") is None {
    fields["candidate_envelopes"] = ([] : Array[Json]).to_json()
  }
  Json::object(fields)
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent.is_empty() || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}

///|
pub async fn load_runtime_state(path : String) -> PackBridgeRuntimeState {
  if !@fs.exists(path) {
    return empty_runtime_state()
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    error => fail("pack bridge runtime state is invalid JSON: \{error}")
  }
  @json.from_json(migrate_runtime_state_json(parsed)) catch {
    error => fail("pack bridge runtime state is invalid: \{error}")
  }
}

///|
pub async fn save_runtime_state(
  path : String,
  state : PackBridgeRuntimeState,
) -> Unit {
  ensure_parent_directory(path)
  let temporary = path + ".next"
  @fs.write_file(
    temporary,
    @encoding/utf8.encode(state.to_json().stringify(indent=2) + "\n"),
    create_mode=CreateOrTruncate,
    permission=0o644,
    sync=Full,
  )
  @fs.rename(temporary, path, replace=true)
}

///|
fn lifecycle_index(state : PackBridgeRuntimeState, pack_id : String) -> Int? {
  for index, lifecycle in state.lifecycles {
    if lifecycle.pack_id == pack_id {
      return Some(index)
    }
  }
  None
}

///|
fn candidate_index(
  state : PackBridgeRuntimeState,
  candidate_ref : String,
) -> Int? {
  for index, receipt in state.candidates {
    if receipt.candidate_ref == candidate_ref {
      return Some(index)
    }
  }
  None
}

///|
fn candidate_envelope_index(
  state : PackBridgeRuntimeState,
  candidate_ref : String,
) -> Int? {
  for index, candidate in state.candidate_envelopes {
    if candidate.candidate_ref == candidate_ref {
      return Some(index)
    }
  }
  None
}

///|
fn replace_lifecycle(
  state : PackBridgeRuntimeState,
  lifecycle : @pack_town_bridge.PackLifecycleRecord,
) -> Unit {
  match lifecycle_index(state, lifecycle.pack_id) {
    Some(index) => state.lifecycles[index] = lifecycle
    None => state.lifecycles.push(lifecycle)
  }
}

///|
fn replace_candidate(
  state : PackBridgeRuntimeState,
  receipt : @pack_town_bridge.PackCandidateReceipt,
) -> Unit {
  match candidate_index(state, receipt.candidate_ref) {
    Some(index) => state.candidates[index] = receipt
    None => state.candidates.push(receipt)
  }
}

///|
fn lifecycle_event(
  lifecycle : @pack_town_bridge.PackLifecycleRecord,
  kind : String,
  occurred_at : String,
  evidence_refs : Array[String],
  issue? : String? = None,
) -> @pack_town_bridge.PackLifecycleEvent {
  {
    contract_id: @pack_town_bridge.pack_lifecycle_event_contract_id(),
    event_id: "\{lifecycle.pack_id}-\{lifecycle.version}-\{kind}-\{lifecycle.sequence + 1}",
    pack_id: lifecycle.pack_id,
    version: lifecycle.version,
    kind,
    occurred_at,
    evidence_refs,
    issue,
  }
}

///|
fn activated_lifecycle(
  current : @pack_town_bridge.PackLifecycleRecord?,
  pack_id : String,
  version : String,
  occurred_at : String,
  manifest_ref : String,
) -> @pack_town_bridge.PackLifecycleRecord {
  let lifecycle = match current {
    Some(record) if record.version == version => record
    _ => @pack_town_bridge.draft_pack_lifecycle(pack_id, version, occurred_at)
  }
  advance_to_active(lifecycle, occurred_at, manifest_ref)
}

///|
fn advance_to_active(
  lifecycle : @pack_town_bridge.PackLifecycleRecord,
  occurred_at : String,
  manifest_ref : String,
) -> @pack_town_bridge.PackLifecycleRecord {
  match lifecycle.stage {
    "draft" =>
      advance_to_active(
        @pack_town_bridge.reduce_pack_lifecycle(
          lifecycle,
          lifecycle_event(lifecycle, "validated", occurred_at, [manifest_ref]),
        ).unwrap(),
        occurred_at,
        manifest_ref,
      )
    "validated" =>
      advance_to_active(
        @pack_town_bridge.reduce_pack_lifecycle(
          lifecycle,
          lifecycle_event(lifecycle, "installed", occurred_at, [manifest_ref]),
        ).unwrap(),
        occurred_at,
        manifest_ref,
      )
    "installed" | "inactive" =>
      @pack_town_bridge.reduce_pack_lifecycle(
        lifecycle,
        lifecycle_event(lifecycle, "activated", occurred_at, [manifest_ref]),
      ).unwrap()
    _ => lifecycle
  }
}

///|
async fn active_projection(
  workspace : String,
  pack_id : String,
) -> (@host.HostActivationProjection, String) {
  guard @installer.active_pack(workspace, pack_id) is Some(pointer) else {
    fail("target pack is not active")
  }
  guard @installer.active_manifest(workspace, pack_id) is Some(manifest) else {
    fail("active pack manifest is unavailable")
  }
  (
    @host.activation_projection(manifest, pointer),
    pointer.installed_root + "/pack.json",
  )
}

///|
pub async fn discover_active_packs(
  workspace : String,
  state_path : String,
  occurred_at : String,
) -> PackBridgeRuntimeState {
  let state = load_runtime_state(state_path)
  let active_ids : Array[String] = []
  let capabilities : Array[PackBridgeCapability] = []
  for pointer in @installer.list_active(workspace) {
    let (activation, manifest_ref) = active_projection(
      workspace,
      pointer.pack_id,
    )
    let bridge_capable = activation.provider_ports.any(port => {
      port.id == @pack_town_bridge.projection_provider_port_id() &&
      port.version == @pack_town_bridge.projection_provider_port_version()
    })
    if !bridge_capable {
      continue
    }
    guard @installer.active_manifest(workspace, pointer.pack_id)
      is Some(manifest) else {
      continue
    }
    active_ids.push(pointer.pack_id)
    capabilities.push({
      pack_id: activation.pack_id,
      product_id: activation.product_id,
      version: activation.version,
      display_name: manifest.display_name,
      intake_operation_ids: activation.tools
      .filter(tool => {
        tool.input_schema_id == @pack_town_bridge.candidate_input_schema_id()
      })
      .map(tool => tool.id),
      operation_ids: activation.tools.map(tool => tool.id),
    })
    let current = match lifecycle_index(state, pointer.pack_id) {
      Some(index) => Some(state.lifecycles[index])
      None => None
    }
    replace_lifecycle(
      state,
      activated_lifecycle(
        current,
        pointer.pack_id,
        pointer.version,
        occurred_at,
        manifest_ref,
      ),
    )
  }
  for index, lifecycle in state.lifecycles {
    if !active_ids.contains(lifecycle.pack_id) &&
      ["installed", "active", "projecting", "degraded"].contains(
        lifecycle.stage,
      ) {
      let inactive = @pack_town_bridge.reduce_pack_lifecycle(
        lifecycle,
        lifecycle_event(lifecycle, "deactivated", occurred_at, []),
      ).unwrap()
      state.lifecycles[index] = inactive
      state.projections = @pack_town_bridge.remove_pack_projection(
        state.projections,
        lifecycle.pack_id,
      )
    }
  }
  state.capabilities = capabilities
  save_runtime_state(state_path, state)
  state
}

///|
pub async fn ingest_projection(
  workspace : String,
  state_path : String,
  projection_json : Json,
  occurred_at : String,
) -> ProjectionIngestResult {
  let projection : @pack_town_bridge.PackTownProjection = @json.from_json(
    projection_json,
  )
  let (activation, manifest_ref) = active_projection(
    workspace,
    projection.pack_id,
  )
  let state = discover_active_packs(workspace, state_path, occurred_at)
  guard lifecycle_index(state, projection.pack_id) is Some(index) else {
    fail("active pack does not declare the projection provider")
  }
  let lifecycle = activated_lifecycle(
    Some(state.lifecycles[index]),
    projection.pack_id,
    activation.version,
    occurred_at,
    manifest_ref,
  )
  match
    @pack_town_bridge.reconcile_projection(
      state.projections,
      activation,
      projection,
    ) {
    Ok(registry) => {
      state.projections = registry
      let projecting = @pack_town_bridge.reduce_pack_lifecycle(
        lifecycle,
        lifecycle_event(lifecycle, "projection-accepted", occurred_at, [
          "pack-projections/\{projection.pack_id}.json",
        ]),
      ).unwrap()
      replace_lifecycle(state, projecting)
      save_runtime_state(state_path, state)
      {
        accepted: true,
        lifecycle: projecting,
        projection: Some(projection),
        issues: [],
      }
    }
    Err(issues) => {
      let detail = issues
        .map(issue => "\{issue.path}: \{issue.message}")
        .join("; ")
      let degraded = @pack_town_bridge.reduce_pack_lifecycle(
        lifecycle,
        lifecycle_event(
          lifecycle,
          "projection-rejected",
          occurred_at,
          [],
          issue=Some(detail),
        ),
      ).unwrap()
      replace_lifecycle(state, degraded)
      save_runtime_state(state_path, state)
      { accepted: false, lifecycle: degraded, projection: None, issues }
    }
  }
}

///|
pub async fn submit_candidate(
  workspace : String,
  state_path : String,
  candidate_json : Json,
  occurred_at : String,
) -> CandidateSubmissionResult {
  let candidate : @pack_town_bridge.TownPackCandidate = @json.from_json(
    candidate_json,
  )
  let (activation, _) = active_projection(workspace, candidate.target_pack_id)
  let route = match
    @pack_town_bridge.resolve_candidate_route(activation, candidate) {
    Ok(route) => route
    Err(issues) =>
      fail(issues.map(issue => "\{issue.path}: \{issue.message}").join("; "))
  }
  let state = discover_active_packs(workspace, state_path, occurred_at)
  match candidate_index(state, candidate.candidate_ref) {
    Some(index) => {
      let receipt = state.candidates[index]
      if receipt.pack_id != route.pack_id ||
        receipt.operation_id != route.operation_id {
        fail("candidate identity is already bound to another route")
      }
      match candidate_envelope_index(state, candidate.candidate_ref) {
        Some(envelope_index) if state.candidate_envelopes[envelope_index] !=
          candidate =>
          fail("candidate identity is already bound to another payload")
        _ => ()
      }
      return { accepted: true, route, receipt }
    }
    None => ()
  }
  let submitted = @pack_town_bridge.submitted_candidate_receipt(
    candidate, occurred_at,
  )
  let routed = @pack_town_bridge.transition_candidate_receipt(
    submitted,
    "route",
    occurred_at,
    [],
  ).unwrap()
  let receipt = if route.review_required {
    @pack_town_bridge.transition_candidate_receipt(
      routed,
      "request-review",
      occurred_at,
      [],
    ).unwrap()
  } else {
    routed
  }
  replace_candidate(state, receipt)
  state.candidate_envelopes.push(candidate)
  save_runtime_state(state_path, state)
  { accepted: true, route, receipt }
}
