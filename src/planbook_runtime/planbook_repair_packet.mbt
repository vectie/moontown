///|
fn planbook_repair_packet(
  criterion : PlanbookCriterionStatus,
  task_id : String,
) -> @moonclaw.ExternalProposalPacket {
  @moonclaw.ExternalProposalPacket::new(
    packet_id=task_id,
    title="Repair PlanBook gap: \{criterion.title}",
    summary="Bounded self-repair task for PlanBook criterion `\{criterion.id}`.",
    request_text=planbook_repair_request_text(criterion),
    profile=@moonclaw_policy.planbook_keeper_profile(),
    output_contract=planbook_repair_result_contract(),
    context_pages=planbook_repair_context_pages(),
    skill_paths=planbook_repair_skill_paths(),
    notes=[
      "Make the smallest safe repair that satisfies the criterion.", "Do not modify unrelated book/domain content.",
      "If the repair belongs in MoonBook or MoonClaw, produce a precise patch plan and blocker instead of leaking ownership into Moontown.",
    ],
    tags=["planbook", "self-healing", "repair", criterion.id],
    metadata=planbook_repair_packet_metadata(criterion),
  )
}
