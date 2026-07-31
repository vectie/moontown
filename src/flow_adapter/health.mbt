///|
fn canonical_utc_timestamp(value : String) -> Bool {
  value.length() == 20 &&
  value[4] == '-' &&
  value[7] == '-' &&
  value[10] == 'T' &&
  value[13] == ':' &&
  value[16] == ':' &&
  value[19] == 'Z'
}

///|
pub async fn publish_health(
  workspace : String,
  checked_at : String,
  valid_until : String,
  evidence_ref : String,
  attestation_ref : String,
) -> Json {
  if !canonical_utc_timestamp(checked_at) ||
    !canonical_utc_timestamp(valid_until) ||
    valid_until <= checked_at {
    fail("MoonTown adapter health requires an increasing canonical UTC window")
  }
  let root = resolve_workspace(workspace)
  let evidence : Json = {
    "contract_id": "moontown.moonflow-adapter-health-evidence.v1",
    "adapter_id": adapter_id(),
    "product_id": "moontown",
    "pack_id": "moontown",
    "pack_version": pack_version(),
    "protocol": "moonflow.adapter.v2",
    "operation_refs": [operation_ref()],
    "input_schema_refs": [input_schema_ref()],
    "output_schema_refs": [output_schema_ref()],
    "authority": "workspace-mutation",
    "claim_ceiling": "execution-result",
    "checks": [
      "workspace-resolved", "immutable-result-store-linked", "civic-runtime-linked",
      "moonclaw-reducer-port-linked", "reconciliation-linked",
    ],
    "checked_at": checked_at,
  }
  let evidence_text = immutable_json_ref(root, evidence_ref, evidence)
  let attestation : Json = {
    "contract_id": "moonflow.adapter-health.v1",
    "adapter_id": adapter_id(),
    "product_id": "moontown",
    "pack_id": "moontown",
    "pack_version": pack_version(),
    "protocol": "moonflow.adapter.v2",
    "status": "healthy",
    "checked_at": checked_at,
    "valid_until": valid_until,
    "operation_refs": [operation_ref()],
    "evidence_ref": evidence_ref,
    "evidence_digest": sha256_text(evidence_text),
  }
  ignore(immutable_json_ref(root, attestation_ref, attestation))
  attestation
}
