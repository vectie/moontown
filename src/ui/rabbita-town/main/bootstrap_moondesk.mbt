///|
fn parse_bootstrap_moondesk_handoff_artifacts() -> Array[
  MoondeskHandoffArtifact,
] {
  let text = load_bootstrap_moondesk_handoff_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let index : MoondeskHandoffIndex = @json.from_json(parsed) catch {
    _ => return []
  }
  ignore(index.version)
  ignore(index.description)
  index.artifacts
}

///|
fn parse_bootstrap_moondesk_bridge() -> MoondeskBridgeIndex? {
  let text = load_bootstrap_moondesk_bridge_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_editor_pipeline() -> EditorPipelineSnapshot? {
  let text = load_bootstrap_editor_pipeline_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}
