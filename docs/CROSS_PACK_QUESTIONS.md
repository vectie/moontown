# Turn cross-pack observations into a review question

**Pack layers → Compose cross-pack question** starts with independently selected
observations from at least two distinct active domain packs. It does not require
them to share a material path, topic label, or apparent conclusion. An operator
asks a bounded question and explicitly records how each observation supports,
challenges, or contextualizes it. The result continues into the existing reviewed
domain candidate intake. It is neither automatic synthesis nor accepted knowledge.

## User journey

1. Open **Pack layers**. Read the domain subjects and check **Use as proposal
   source** on two to twelve observations spanning at least two packs.
2. Select **Compose cross-pack question**. Enter the question (140 characters),
   its scope and tentative rationale, and an observable rejection test. For every
   observation, choose **supports**, **challenges**, or **context** and explain its
   connection. Record the date, population, or conditions under which it applies;
   explicitly write **unknown** if they are unknown.
3. Compare the exact copied summaries, publishing versions/timestamps, lifecycle
   states, and pack-relative evidence references shown beside those notes.
   Equal-looking paths in different packs retain their distinct pack identities.
   Different dates or conditions can explain differences; the product never labels
   these as contradictions, consensus, or independent corroboration.
4. Use **Keep question and close** to retain the draft in this mounted panel.
   Layer filtering, refresh, and reopening preserve it. Selecting additional
   observations and reopening appends new identities without silently replacing
   historical excerpts or previous notes. **Remove this observation** is explicit.
5. **Download question packet** saves the unsent question, exact historical
   excerpts, roles, connections, and conditions as bounded JSON. In a new page
   session, use **Resume a downloaded question packet**, inspect the import count,
   then explicitly choose **Replace local question with imported packet**.
   Import alone never uploads, sends, or accepts anything. Download the existing
   local draft first if it is needed; replacement only affects that unsent draft.
6. Imported or refreshed missing, ambiguous, version-changed, unavailable, or
   materially changed observations remain visible as **unresolved snapshot gaps**.
   Their historical excerpts and notes are retained. Intake is blocked. When a
   current observation exists, **Read current snapshot and re-label** replaces that
   one excerpt and clears its role, connection, and conditions for explicit review.
   A missing observation must return or be explicitly removed. No gap is silently
   discarded, and the remaining question must still span two packs.
7. **Continue question to intake** opens the existing editable candidate composer.
   The question, scope, connections, and rejection test prefill its fields. The
   original question roles/conditions remain attached as reviewed context even if
   the candidate title, rationale, or connection notes are refined. Choose the
   exact receiving pack operation and supply any pack-specific JSON, then explicitly
   **Submit for review**. The final live preflight checks all selected sources and
   the current destination before POST. Uncertain outcomes retain the same candidate
   identity/body for **Retry same candidate**, including when reopening from this
   question or import controls. Check Candidate flow before creating another copy.

## Contracts and persistence

The portable `moontown.cross-pack-question-draft.v1` packet is an untrusted,
operator-editable draft. It preserves incomplete rows so work can resume; only a
fully described question with current observations can continue to intake.
Unknown imported keys are discarded. A packet claiming accepted knowledge is
rejected. Source strings render through textContent/value, not HTML.

The receiving envelope remains `moontown.pack-candidate-intake.v1`. Existing
`domain_payload` keys are preserved. Source observations remain in
`domain_payload.moontown_source_context.sources`; the reviewed question is nested
under `moontown_source_context.cross_pack_question` with contract
`moontown.cross-pack-question.v1`. Both pack ID and subject reference identify
every observation. The existing top-level evidence list merges duplicate paths;
its nested source context is what preserves each publishing pack's namespace.

The native bridge routes one candidate to one reviewed intake operation, writes
the full envelope into its pack-owned workspace mailbox, retains it in durable
state, and reconciles retries by candidate identity. The new native fixture test
installs and projects two distinct fixture packs, submits this nested cross-pack
context, verifies exact mailbox and reloaded-envelope equality, checks that both
projections are unchanged, and replays the same candidate without another envelope.

There is one unsent question in memory per mounted panel. A download/import is
the explicit page-restart recovery path, not localStorage or a background upload.
The packet does not contain a pending POST identity or a native receipt and cannot
recover an uncertain already-sent candidate after reload. Inspect durable candidate
receipts before composing another copy after such an interruption.

## Boundaries and limits

- Two to twelve observations, from at least two distinct packs, at continuation.
- Question: 140 characters. Scope, rejection test, and each per-row connection or
  conditions note: 2,000 characters. Roles are operator-selected, not inferred.
- Portable JSON is at most 128 KiB in UTF-8 including the final newline; larger
  selected combinations must be narrowed. The existing complete native candidate
  envelope also stays within 128 KiB, including JSON overhead and duplicated context.
- Source validation uses the existing projection limits (including 16,384-character
  summaries and at most 100 safe evidence references per source). At most 200 unique
  evidence references fit the candidate intake contract.
- A timestamp-only republish does not invalidate unchanged inspected content.
  Timestamps are publisher claims, not proof of present-day relevance. An imported
  snapshot is compared against the active projection; it is not a signed attestation.
- Browser preflight is not atomic with native POST. Native intake owns routing,
  identity, persistence, and pack review; it does not independently validate these
  nested labels or authorize source access, Book acceptance, or downstream execution.
- Pack observations are not necessarily MoonBook snapshots. This is bounded support
  for MOONTOWN-B03/UC03's cited input-projection, pending-intake and named-gap
  slices only. It does not qualify B05's full spatial/supervisor path or complete cross-Book contradiction review,
  a source-bounded standing watch, autonomous emergence, or an always-on service.

## Verification scope

The focused frontend suite covers 51 tests, including 21 new question tests and
the existing source/candidate and shared-material tests. It executes the actual
mounted builders and event handlers with a small event DOM and fetch substitutes.
Stale callbacks from closed dialogs, replaced row renders and discarded/imported
previews remain inert; seven regressions cover these boundaries. This does not
qualify real browser downloads, layout, focus, or accessibility.

A narrow native harness copies the exact `pack_town_bridge` and
`pack_town_bridge_runtime` packages and runs 19 tests, including the new two-pack
mailbox/reload/replay test. Cached async 0.19.4 is used in that harness; the shipped
module still declares async 0.16.6. Native check/info/fmt pass for the harness and
generated interfaces remain unchanged. This is not a full paired-product build.

The complete frontend suite still fails seven pre-existing gates (106 pass / 7 fail):
five missing assembled landmark asset checks, the unchanged single-map source
assertion, and the unchanged transit portal assertion. The same seven failures
were reproduced against the exact earlier source. Production assembly, paired
MoonChat/Rabbita compilation, real browser exercise, live packs/providers, multi-day
daemon recovery, authentication, and production backup/restore remain unqualified.
All failed or unrun required release gates remain blocking.
