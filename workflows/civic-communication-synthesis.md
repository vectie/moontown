# Civic communication synthesis

1. Receive a `moontown.civic.communication.handoff.v1` artifact.
2. Validate its producer binding and generic civic scenario.
3. Run the existing MoonTown civic communication runtime. The
   `communication_pattern_id` may be `research-salon`, but it is configuration,
   not the cross-product operation identity.
4. Use MoonClaw as the sole worker/reducer runtime.
5. Materialize participant, synthesis, metrics, review and returned-output
   evidence in the caller's workspace.
6. Return `moontown.civic-synthesis-result.v1` with exact evidence digests.
7. Reconcile by reading the durable native receipt and evidence; never rerun an
   unknown attempt automatically.
8. Leave every completed output at `review_status: pending`. MoonFlow and a
   named reviewer own settlement.
