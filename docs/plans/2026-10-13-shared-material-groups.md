# Shared-material groups into reviewed domain candidates

## Product gap

Pack layers exposes observations and R624 lets an operator manually combine them.
It does not yet reveal when several observations point back to the same local
material. Add a bounded discovery and review step before the existing candidate
composer, following `docs/project/PACK_TOWN_BRIDGE.md`'s bottom-up provenance and
pack-owned review boundary.

## Intended journey

1. Load active projected observations in Pack layers.
2. Discover groups sharing an exact evidence reference within one owning pack.
   Identical paths from different packs are not the same material.
3. Review exact summaries and references, include two to twelve observations,
   exclude irrelevant observations, and describe a tentative pattern.
4. Continue to the existing domain candidate composer. Preserve the reviewed
   grouping, selected source excerpts, individual contribution notes and contrary
   evidence. Only explicit Submit routes a candidate through native intake.
5. Preserve existing freshness preflight, bounded envelopes and identity-stable
   uncertain-request retry. Cancellation before submission writes nothing.

Shared evidence is reuse of a material reference, not independent corroboration,
verified file identity, semantic clustering, accepted knowledge or autonomous
emergence. Grouping is a local view; only the submitted candidate is durable.

## Verification plan

Test grouping scope, duplicates, degraded/invalid/missing sources, limits and
deterministic order. Exercise the mounted journey including filter changes,
review exclusions, invalid/blank input, cancel/reopen, repeated continuation,
changed-source rejection, concurrent submission and exact-body retry. Check
production asset declarations and existing frontend regression tests. Report
unrun native, browser and installed workflow qualification separately.

## Execution evidence

Implementation and final validation are recorded in
`docs/SHARED_MATERIAL_GROUPS.md` and the round's external evidence directory.
