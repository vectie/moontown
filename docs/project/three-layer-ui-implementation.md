# Three-layer UI/UX implementation

Date: 2026-09-05. Work remains on `main`. Scope: the preceding UI/UX/gameplay review, not a change to MoonPoly's policy engine or external execution authority.

## Findings and changes

| Review finding | Implementation |
| --- | --- |
| Furniture, machine and gateway hitboxes stacked at one point | Replaced literal CSS braces with MoonBit interpolation. Canvas and DOM targets now use the same projection function. |
| Indoor furniture and doors were inert | Furniture selects a semantic slot inspector; an equivalent keyboard/touch roster exposes every slot. Work/service desks open contextual work creation; transit gates and the painted primary door return outdoors. Display/rest slots explain their purpose rather than fabricate work. |
| Small screens enlarged props independently of the floor | Removed every minimum art-scale clamp. Background, props and agents scale together; touch controls retain 44px minimums. Re-spaced the standard indoor bays. |
| Background camera disagreed with furniture | Added a new indoor plate and measured camera metadata. Both room plates are registered to a shared 2:1 floor projection in 4:3 stages; the affine transform preserves verticals. The projected axes and plate registration are numerically tested. Painted detail is still authored art, not a claim that every source pixel is geometrically exact. |
| Canvas stopped observing size after leaving and re-entering | Rebind/disconnect the resize observer when the actual canvas element changes. |
| Underground looked like proof that all agents used all machines | Removed inferred execution cables. Only the selected work's matching agent/run can appear as work context. Availability, observed topology, and actual run-to-endpoint assignment remain separate facts. |
| The lift lost the return building on reload | Underground URLs retain the building ID; startup resolves it. Unknown IDs fail safely to town. Slot selection survives a lift round trip; work/request IDs have resumable URL context. |
| Policy navigation silently opened an unchanged map | Policies now opens Policy Hall directly. Existing Talent/District areas render their requested content and a return control. Renamed “Events” to “Districts” to match the actual surface. Explicit area/layer links do not force avatar onboarding. |
| Raw renderer/debug vocabulary obscured purpose | Removed the default road calibration banner (still available in Map Lab), simplified room legends, used actor display names and explicit preview labels, corrected light-surface contrast, and moved opaque work IDs into disclosed details. |
| Three layers did not form a useful work journey | Added issue intake → accepted request correlation → work/agent/run inspection → safe result links → explicit human review. Completed history stays discoverable; cross-building handoffs appear at both ends. A review grants 10 local game sparks once per work/run, not once per refresh. It does not approve or implement a policy. |
| Policy Hall was restricted to youth entrepreneurship | Generalized intake and guide context to Changping local issues: affected people, current conditions, outcomes, evidence, options/tradeoffs, implementation constraints and evaluation. Existing youth sources remain labeled as a limited corpus; unsupported policy domains require new sources. Old client context is still accepted by the backend. |
| Opening an indoor request unexpectedly switched outdoors | Browser testing exposed the shared transient-surface reset. Contextual work creation now preserves its spatial layer. A dedicated indoor/underground modal keyboard lifecycle handles focus, Tab and Escape without relying on the outdoor canvas. |

## Product and authority boundaries

- MoonTown owns spatial presentation, navigation, local game feedback, and submitting an explicitly confirmed existing work-request form.
- A building/slot in the request is context, not an instruction bypassing the scheduler's assignment authority.
- MoonGate and LunaNexa retain execution, provider and machine-control authority. This UI does not add shell access, tokens, model configuration or direct dispatch.
- Policy explanation does not submit applications or approve policy. Missing source coverage is visible, not filled with invented claims.
- Work results use the existing allowlisted result-link validator. Local artifact paths remain hidden.
- The current runtime work schema has agent/run identity but **no verified run-to-machine/provider receipt**. The implementation explicitly reports this gap. Actual machine attribution remains unavailable until an upstream, redacted correlation contract is provided. It must not be derived from active provider configuration or machine workload counts.

## Verification

The focused MoonBit suites cover hitbox CSS, shared geometry, responsive scaling, route recovery, slot interactions, contextual requests, work/request correlation, historical results, evidence gating, review idempotency, policy scope and existing drawer semantics. The production builder also checks asset availability and the existing 69 MiB artifact budget.

Browser validation covers desktop and 390px phone layouts, furniture selection, contextual request open/close without submission, Policy Hall guide, lift navigation, underground selection, deep-link return context, and Talent/District navigation. Runtime verification is deliberately limited to the environment's observed state: MoonGate unreachable, no observed local machines, remote providers not observed. No jobs or policy questions were submitted for testing.

Results: 38 desktop-server tests passed. Focused UI suites passed: spatial interaction regressions (8), spatial layer journey (5), policy question flow (4), compute room (6), drawer accessibility (2), and account experience (9): 34 UI tests total. The final production build verified 275 files at 68.2 MiB; generated public interfaces did not change. Browser checks confirmed indoor modal focus/Escape restoration, semantic furniture selection, provider selection, a fresh underground deep link returning to Policy Hall, and standalone routed areas without an active map behind them.

At 390px, the five Policy Hall furniture targets measured at least 44×44px, had zero pairwise overlaps, and produced no document-level horizontal overflow. Temporary test tabs were closed and the viewport override reset.

The broad UI suite was attempted and interrupted after a prolonged run; do not report it as passing. Real device testing and real distributed execution under an available gateway remain outstanding.

## Art asset provenance and camera contract

- Built-in image generation; new workspace asset: `src/ui/assets/tilemap/rooms/moontown-spatial-v3/indoor-room.jpg`.
- Source PNG remains in the generator's output directory; the project copy is JPEG quality 85 to preserve the existing bundle budget. No earlier asset version was deleted.
- References: v2 indoor room for materials; v2 furniture atlas for camera/style. Underground keeps its existing v1 art with measured registration.
- Production prompt: one empty MoonTown indoor game background, 4:3 landscape; finely outlined hand-painted finish; honey oak beams, cream plaster, blue glazing, planted sills; warm upper-left daylight. Two back walls and two removed front walls; orthographic 2:1 floor axes, vertical verticals, no convergence. Floor corners requested at north (0.50,0.30), east (0.95,0.60), south (0.50,0.90), west (0.05,0.60); back-wall tops at center y=.06 and ends y=.36. One teal door on the right rear wall, windows on the left. Empty floor, no furniture/people/text/UI/racks/consoles/watermarks. Pale ivory outside. Reference room camera explicitly excluded; furniture reference supplies the intended angle.
- Acceptance is based on rendered composition and measured registration, not prompt wording. Camera metadata lives in `spatial_scene_camera.mbt`; new room versions must be measured there before replacing the asset. Never add a prop-scale clamp to compensate for camera errors.

## Follow-up integration prerequisite

To make the final compute hop observable, upstream needs a redacted receipt containing stable work/run identity, endpoint alias, observation time and evidence provenance. Validate the correlation and observation freshness before drawing any execution edge. Do not add a fake receipt or relabel a configured provider as the executor.
