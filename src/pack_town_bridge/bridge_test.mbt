///|
fn activation(
  pack_id : String,
  product_id : String,
  tools : Array[@pack.ToolDeclaration],
) -> @host.HostActivationProjection {
  {
    contract: "moonsuite.pack-host-activation.v1",
    pack_id,
    product_id,
    version: "1.0.0",
    required_runtime_extensions: [],
    book_templates: [],
    tools,
    schedules: [],
    app_entrypoints: [],
    provider_ports: [
      @pack.contract_ref(
        projection_provider_port_id(),
        projection_provider_port_version(),
        "providers/moontown-pack-projection.json",
      ),
    ],
    policies: [],
  }
}

///|
fn moonpoly_activation() -> @host.HostActivationProjection {
  activation("moonpoly", "moonpoly", [
    @pack.tool_declaration(
      "policy.candidate.intake",
      "moonpoly",
      candidate_input_schema_id(),
      "policy-case",
      WorkspaceMutation,
      review_required=true,
    ),
    @pack.tool_declaration(
      "policy.options.prepare",
      "moonpoly",
      "policy-case",
      "policy-case",
      SandboxExecution,
    ),
    @pack.tool_declaration(
      "policy.review.request",
      "moonpoly",
      "policy-case",
      "policy-review-request",
      WorkspaceMutation,
      review_required=true,
    ),
  ])
}

///|
fn mooncast_activation() -> @host.HostActivationProjection {
  activation("mooncast", "mooncast", [
    @pack.tool_declaration(
      "creative.candidate.intake",
      "mooncast",
      candidate_input_schema_id(),
      "creative-brief",
      WorkspaceMutation,
      review_required=true,
    ),
    @pack.tool_declaration(
      "brief.validate",
      "mooncast",
      "creative-brief",
      "creative-brief",
      SandboxExecution,
    ),
    @pack.tool_declaration(
      "asset.generate",
      "mooncast",
      "generation-request",
      "asset-provenance",
      ExternalEffect,
      review_required=true,
    ),
  ])
}

///|
fn moonpoly_projection() -> PackTownProjection {
  {
    contract_id: projection_contract_id(),
    pack_id: "moonpoly",
    product_id: "moonpoly",
    version: "1.0.0",
    generated_at: "2026-08-23T10:00:00Z",
    subjects: [
      {
        subject_ref: "policy/cases/night-bus-access",
        schema_id: "policy-case",
        title: "Night bus access",
        summary: "An emergent proposal with several contestable options.",
        lifecycle_state: "option-formation",
        attention: "review",
        place_refs: ["places/transit-hall"],
        related_refs: ["town/ideas/night-bus-access"],
        workflow_refs: ["workflows/governed-policy-formation"],
        run_refs: [],
        evidence_refs: ["evidence/night-bus-demand.json"],
        operation_ids: ["policy.options.prepare", "policy.review.request"],
        domain_payload: {
          "problem": "Late-shift workers lack a reliable return route",
          "current_course": "retain the existing timetable",
        },
      },
    ],
  }
}

///|
fn mooncast_projection() -> PackTownProjection {
  {
    contract_id: projection_contract_id(),
    pack_id: "mooncast",
    product_id: "mooncast",
    version: "1.0.0",
    generated_at: "2026-08-23T10:05:00Z",
    subjects: [
      {
        subject_ref: "production/projects/river-documentary",
        schema_id: "production-project",
        title: "River documentary",
        summary: "A community story awaiting a validated creative brief.",
        lifecycle_state: "brief-review",
        attention: "notice",
        place_refs: ["places/media-studio"],
        related_refs: ["town/ideas/river-memory"],
        workflow_refs: ["workflows/brief-to-delivery"],
        run_refs: ["runs/river-documentary-1"],
        evidence_refs: ["evidence/community-interviews.json"],
        operation_ids: ["brief.validate", "asset.generate"],
        domain_payload: {
          "format": "short-documentary",
          "gate": "creative-brief",
        },
      },
    ],
  }
}

///|
test "unlike domain packs reconcile without shared domain types" {
  let policy = reconcile_projection(
    empty_registry(),
    moonpoly_activation(),
    moonpoly_projection(),
  )
  guard policy is Ok(policy_registry) else {
    fail("expected MoonPoly projection to conform")
  }
  let media = reconcile_projection(
    policy_registry,
    mooncast_activation(),
    mooncast_projection(),
  )
  guard media is Ok(registry) else {
    fail("expected MoonCast projection to conform")
  }
  assert_eq(registry.projections.length(), 2)
  assert_eq(all_projected_subjects(registry).length(), 2)
  guard subject_for_pack(registry, "moonpoly", "policy/cases/night-bus-access")
    is Some(subject) else {
    fail("expected pack-owned policy subject")
  }
  assert_eq(subject.schema_id, "policy-case")
  assert_true(
    subject.domain_payload != mooncast_projection().subjects[0].domain_payload,
  )
}

///|
test "projection reconciliation is idempotent per pack" {
  let first = reconcile_projection(
    empty_registry(),
    moonpoly_activation(),
    moonpoly_projection(),
  )
  guard first is Ok(first_registry) else { fail("expected valid projection") }
  let second = reconcile_projection(
    first_registry,
    moonpoly_activation(),
    moonpoly_projection(),
  )
  guard second is Ok(second_registry) else { fail("expected valid projection") }
  assert_eq(second_registry.projections.length(), 1)
  assert_eq(
    remove_pack_projection(second_registry, "moonpoly").projections.length(),
    0,
  )
}

///|
test "projection can expose only activated pack operations" {
  let invalid = moonpoly_projection()
  invalid.subjects[0] = {
    ..invalid.subjects[0],
    operation_ids: ["asset.generate"],
  }
  let issues = projection_conformance_issues(moonpoly_activation(), invalid)
  assert_true(
    issues.any(issue => {
      issue.path == "subjects[0].operation_ids[0]" &&
      issue.message.contains("activated pack")
    }),
  )
}

///|
test "projection requires explicit host discovery port" {
  let undiscoverable = { ..moonpoly_activation(), provider_ports: [] }
  let issues = projection_conformance_issues(
    undiscoverable,
    moonpoly_projection(),
  )
  assert_true(
    issues.any(issue => {
      issue.path == "activation.provider_ports" &&
      issue.message.contains(projection_provider_port_id())
    }),
  )
}

///|
test "bottom-up candidate resolves a route but does not grant authority" {
  let candidate : TownPackCandidate = {
    contract_id: candidate_contract_id(),
    candidate_ref: "town/candidates/river-memory",
    origin_ref: "town/ideas/river-memory",
    target_pack_id: "mooncast",
    intake_operation_id: "creative.candidate.intake",
    submitted_by: "river-neighborhood-book",
    submitted_at: "2026-08-23T10:10:00Z",
    title: "Preserve river-worker memories",
    rationale: "Residents developed a documented story proposal.",
    claim_ceiling: "research-evidence",
    evidence_refs: ["evidence/community-interviews.json"],
    domain_payload: {
      "suggested_format": "short-documentary",
      "community_owner": "river-neighborhood-book",
    },
  }
  guard resolve_candidate_route(mooncast_activation(), candidate) is Ok(route) else {
    fail("expected candidate to resolve")
  }
  assert_eq(route.operation_id, "creative.candidate.intake")
  assert_true(route.authority == WorkspaceMutation)
  assert_true(route.review_required)
}

///|
test "candidate cannot route directly into a non-intake domain action" {
  let candidate : TownPackCandidate = {
    contract_id: candidate_contract_id(),
    candidate_ref: "town/candidates/river-memory",
    origin_ref: "town/ideas/river-memory",
    target_pack_id: "mooncast",
    intake_operation_id: "brief.validate",
    submitted_by: "river-neighborhood-book",
    submitted_at: "2026-08-23T10:10:00Z",
    title: "Preserve river-worker memories",
    rationale: "Residents developed a documented story proposal.",
    claim_ceiling: "research-evidence",
    evidence_refs: ["evidence/community-interviews.json"],
    domain_payload: {},
  }
  let issues = candidate_conformance_issues(mooncast_activation(), candidate)
  assert_true(
    issues.any(issue => {
      issue.path == "intake_operation_id" &&
      issue.message.contains(candidate_input_schema_id())
    }),
  )
}

///|
test "candidate cannot exceed MoonTown claim authority or target an undeclared operation" {
  let candidate : TownPackCandidate = {
    contract_id: candidate_contract_id(),
    candidate_ref: "town/candidates/autonomous-release",
    origin_ref: "town/ideas/autonomous-release",
    target_pack_id: "mooncast",
    intake_operation_id: "publication.release",
    submitted_by: "media-book",
    submitted_at: "2026-08-23T10:15:00Z",
    title: "Release automatically",
    rationale: "This must remain only a rejected proposal.",
    claim_ceiling: "physical-readiness",
    evidence_refs: [],
    domain_payload: {},
  }
  let issues = candidate_conformance_issues(mooncast_activation(), candidate)
  assert_true(issues.any(issue => issue.path == "claim_ceiling"))
  assert_true(issues.any(issue => issue.path == "intake_operation_id"))
}
