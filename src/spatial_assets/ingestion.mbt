///|
pub(all) struct SpatialAssetIssue {
  code : String
  message : String
} derive(Debug, Eq, ToJson)

///|
pub(all) struct TownPresentationAsset {
  building_id : String
  placement_id : String
  artifact_id : String
  artifact_digest : String
  engineering_parent_id : String
  engineering_parent_digest : String
  payload_ref : String
  units : String
  coordinate_system : String
  up_axis : String
  handedness : String
  transform_id : String
  declared_losses : Array[String]
  assumptions : Array[String]
  authority_envelope_id : String
} derive(Debug, Eq, ToJson)

///|
fn issue(
  code : String,
  message : String,
) -> Result[TownPresentationAsset, SpatialAssetIssue] {
  Err({ code, message })
}

///|
fn json_strings(values : Array[Json]) -> Array[String]? {
  let result : Array[String] = []
  for value in values {
    match value {
      String(text) => result.push(text)
      _ => return None
    }
  }
  Some(result)
}

///|
fn valid_digest(value : String) -> Bool {
  value.has_prefix("sha256:") && value.length() == 71
}

///|
pub fn ingest_moonmold_presentation(
  text : String,
  building_id~ : String,
  placement_id~ : String,
  expected_engineering_digest~ : String,
) -> Result[TownPresentationAsset, SpatialAssetIssue] {
  if building_id.trim().is_empty() || placement_id.trim().is_empty() {
    return issue(
      "missing-town-identity", "building and placement identities are required",
    )
  }
  if building_id == placement_id {
    return issue(
      "conflated-town-identity", "building identity must remain distinct from placement identity",
    )
  }
  let parsed = @json.parse(text) catch {
    _ => return issue("invalid-json", "MoonMold envelope is not valid JSON")
  }
  match parsed {
    {
      "schema": String(schema),
      "manifest": {
        "contract_id": String(manifest_contract),
        "artifact_id": String(artifact_id),
        "representation": String(representation),
        "digest": String(artifact_digest),
        "payload_ref": String(payload_ref),
        "units": String(units),
        "coordinate_system": String(coordinate_system),
        "up_axis": String(up_axis),
        "handedness": String(handedness),
        "authority_envelope_id": String(authority_envelope_id),
        "assumptions": Array(assumption_values),
        "intended_consumers": Array(consumer_values),
        "forbidden_consumers": Array(forbidden_values),
        "claim_ceiling": String(claim_ceiling),
        ..
      },
      "transform": {
        "contract_id": String(transform_contract),
        "transform_id": String(transform_id),
        "parent_artifact_id": String(parent_artifact_id),
        "parent_digest": String(parent_digest),
        "parent_representation": String(parent_representation),
        "child_artifact_id": String(child_artifact_id),
        "child_digest": String(child_digest),
        "child_representation": String(child_representation),
        "lineage_relation": String(lineage_relation),
        "authority_ref": String(authority_ref),
        "declared_losses": Array(loss_values),
        ..
      },
      ..
    } => {
      let assumptions = match json_strings(assumption_values) {
        Some(value) => value
        None =>
          return issue(
            "invalid-string-array", "assumptions must contain strings",
          )
      }
      let consumers = match json_strings(consumer_values) {
        Some(value) => value
        None =>
          return issue("invalid-string-array", "consumers must contain strings")
      }
      let forbidden = match json_strings(forbidden_values) {
        Some(value) => value
        None =>
          return issue(
            "invalid-string-array", "forbidden consumers must contain strings",
          )
      }
      let losses = match json_strings(loss_values) {
        Some(value) => value
        None =>
          return issue(
            "invalid-string-array", "declared losses must contain strings",
          )
      }
      if schema != "moonmold-portable-ingestion-v1" ||
        manifest_contract != "moonmold.spatial-artifact.v1" ||
        transform_contract != "moonmold.representation-transform.v1" {
        return issue(
          "unsupported-contract", "portable MoonMold contract version is unsupported",
        )
      }
      if representation != "visual-styled-model" ||
        child_representation != "visual-styled-model" ||
        parent_representation != "engineering-model" ||
        lineage_relation != "styled-from" {
        return issue(
          "wrong-representation-lane", "MoonTown accepts only styled presentation children of engineering geometry",
        )
      }
      if artifact_id != child_artifact_id || artifact_digest != child_digest {
        return issue(
          "child-lineage-mismatch", "manifest and transform child identity differ",
        )
      }
      if parent_digest != expected_engineering_digest {
        return issue(
          "stale-engineering-parent", "presentation parent digest is not the accepted engineering digest",
        )
      }
      if !valid_digest(artifact_digest) || !valid_digest(parent_digest) {
        return issue(
          "invalid-digest", "artifact and parent digests must be sha256",
        )
      }
      if claim_ceiling != "digital-artifact" {
        return issue(
          "claim-ceiling-exceeded", "presentation geometry must remain a digital artifact",
        )
      }
      if !consumers.contains("moontown") || forbidden.contains("moontown") {
        return issue(
          "consumer-policy-mismatch", "manifest does not authorize MoonTown presentation use",
        )
      }
      if losses.is_empty() {
        return issue(
          "undeclared-style-loss", "styled representation must declare conversion losses",
        )
      }
      if assumptions.is_empty() {
        return issue(
          "missing-assumptions", "presentation assumptions must remain visible",
        )
      }
      if authority_envelope_id.trim().is_empty() ||
        authority_ref != authority_envelope_id {
        return issue(
          "authority-lineage-mismatch", "manifest and transform authority differ",
        )
      }
      if units.trim().is_empty() ||
        coordinate_system.trim().is_empty() ||
        up_axis.trim().is_empty() ||
        handedness.trim().is_empty() ||
        transform_id.trim().is_empty() ||
        payload_ref.trim().is_empty() {
        return issue(
          "incomplete-spatial-contract", "spatial conventions, transform, and payload are required",
        )
      }
      Ok({
        building_id,
        placement_id,
        artifact_id,
        artifact_digest,
        engineering_parent_id: parent_artifact_id,
        engineering_parent_digest: parent_digest,
        payload_ref,
        units,
        coordinate_system,
        up_axis,
        handedness,
        transform_id,
        declared_losses: losses,
        assumptions,
        authority_envelope_id,
      })
    }
    _ =>
      issue(
        "invalid-envelope", "required portable artifact or transform fields are missing",
      )
  }
}
