///|
async test "MoonTown attests plural emergence, dissent, review, and return" {
  let workspace = "/tmp/moontown-flow-attestor-test"
  write_json(scoped_path(workspace, "runtime/request.json"), {
    "request_id": "request-concept",
    "operation": "deliberate-concept",
  })
  write_json(scoped_path(workspace, "runtime/result.json"), {
    "result_id": "result-concept",
    "output_digest": "sha256:draft",
  })
  write_json(scoped_path(workspace, "drafts/concept.json"), {
    "contract_id": "moontown.deliberation.v1",
    "product_id": "moontown",
    "civic_round": {
      "contract_id": "moontown.autonomous-civic-round.v1",
      "round_id": "round-polar-inspector",
      "commission_id": "commission-lunar-robot",
      "question": "Which digital lunar robot concept best preserves safety and inspectability?",
      "commissioned_agenda_ids": [],
      "comparison_criteria": [
        {
          "criterion_id": "safety",
          "name": "bounded safe behavior",
          "definition": "Preserves a safe hold under degraded localization.",
        },
      ],
      "contributions": [
        {
          "contribution_id": "polar-inspector",
          "participant_id": "mobility-book",
          "source_book_id": "mobility",
          "origin": "emergent",
          "summary": "A slow polar inspection robot with redundant sensing.",
          "evidence_refs": ["outputs/research.json"],
          "alternatives": ["stationary beacon network"],
          "blockers": ["thermal calibration is unresolved"],
          "implementation_criteria": ["safe-hold on localization disagreement"],
          "claim_ceiling": "accepted-knowledge",
          "supports": [],
          "proposal": {
            "concept_id": "polar-inspector",
            "mission": "inspect a bounded polar traverse",
          },
        },
        {
          "contribution_id": "beacon-minority",
          "participant_id": "safety-book",
          "source_book_id": "safety",
          "origin": "dissenting",
          "summary": "Prefer stationary beacons until mobility hazards are calibrated.",
          "evidence_refs": ["outputs/research.json"],
          "alternatives": ["polar inspector"],
          "blockers": ["lower spatial coverage"],
          "implementation_criteria": ["survive an unilluminated thermal cycle"],
          "claim_ceiling": "research-evidence",
          "supports": [],
          "proposal": { "concept_id": "beacon-minority" },
        },
      ],
      "critiques": [
        {
          "critique_id": "thermal-critique",
          "participant_id": "safety-book",
          "target_contribution_id": "polar-inspector",
          "concern": "Thermal bounds require calibration.",
          "evidence_refs": ["outputs/research.json"],
          "severity": "material",
          "resolved": false,
        },
      ],
      "rankings": [
        {
          "voter_id": "mission-book",
          "ordered_contribution_ids": ["polar-inspector", "beacon-minority"],
          "rationale": "The inspector provides bounded mobility while preserving safe hold.",
        },
      ],
      "review": {
        "reviewer_id": "independent-civic-reviewer",
        "decision": "accepted",
        "evidence_refs": ["outputs/research.json"],
        "note": "Dissent remains explicit and the winning claim is bounded.",
      },
      "deliveries": [
        {
          "participant_id": "mobility-book",
          "received": true,
          "returned_home": true,
          "receipt_ref": "receipts/mobility.json",
        },
        {
          "participant_id": "safety-book",
          "received": true,
          "returned_home": true,
          "receipt_ref": "receipts/safety.json",
        },
      ],
      "requested_authority": "cognitive-maintenance",
      "recorded_at": "2026-07-12T00:00:00Z",
    },
  })
  attest(
    workspace, "runtime/request.json", "runtime/result.json", "runtime/attestation.json",
    "moontown-native-attestor-v1", "drafts/concept.json", "outputs/concept.json",
  )
  let output = read_json(scoped_path(workspace, "outputs/concept.json"))
  let text = output.stringify()
  assert_true(text.contains("\"emergence_qualified\":true"))
  assert_true(text.contains("\"comparison_criteria\""))
  assert_true(text.contains("\"polar-inspector\""))
  assert_true(text.contains("\"beacon-minority\""))
  assert_true(text.contains("\"physical_readiness\":false"))
}
