# Discover and review shared local material

The Pack layers panel now exposes a step before manual candidate composition:
find several projected observations that cite the same local material, inspect
them together, and formulate a reviewable domain question.

## Operator journey

1. Open **Pack layers**. **Shared-material groups** lists repeated evidence
   references among visible layers. A group is keyed by the exact pair
   `(pack_id, evidence_ref)`. Equal paths from different packs never merge.
2. Choose **Review shared material**. Read each source's exact title, summary,
   identity, lifecycle, published timestamp and evidence references. No source
   is included by default. Explicitly include two to twelve sources; leave
   irrelevant sources excluded. Write **Your tentative pattern**.
3. Choose **Continue to proposal**. The existing editable domain candidate
   composer displays the grouping basis, included/excluded identities and the
   original operator hypothesis separately from copied observations. The
   hypothesis seeds the editable rationale. Nothing has been sent.
4. Select the exact destination intake operation, name the question, explain
   each included observation's contribution, and supply contrary evidence or a
   rejection test. The receiving pack still owns the optional domain JSON.
5. Explicitly **Submit for review**. The current snapshot must still contain
   the selected observations and the complete reviewed group generation. A
   changed, missing or added member, including an excluded observation, blocks
   the POST. Reopen the group and review its current contents.
6. Existing native v1 intake retains the submitted envelope and returns the
   existing candidate receipt. Inspect it in Candidate flow. Submission routes
   a pending candidate; it does not accept knowledge, run a domain operation or
   authorize downstream effects.

## Cancel, refresh and interrupted submission

Cancel or Escape before submission writes nothing. The mounted panel retains
the group's explicit choices and hypothesis across cancel, layer filtering and
snapshot refresh. If its content changes, **Review current group** is required:
surviving identities retain their choices, removed identities disappear, and
new observations start excluded. The hypothesis remains editable. Refresh
failure blocks continuation while retaining the draft. A late response from an
older refresh cannot overwrite a newer snapshot.

While preparation or submission is in progress, repeated actions cannot create
another composer or candidate. An uncertain POST retains the exact original
candidate identity and serialized body. Choosing a group or reopening the normal
composer resumes that candidate. Retry reconciles the original envelope without
rebasing it to newer sources. See [candidate recovery](SOURCE_LINKED_PACK_CANDIDATES.md).

Draft retention is in memory only. Reload clears unsent reviews; it does not
cancel a POST. Inspect the durable candidate list/mailbox before composing a new
copy when a previous result was uncertain. Up to forty group reviews are retained
per mounted panel; additional reviews are refused visibly rather than evicting
existing drafts silently.

## Provenance and bounds

The existing `moontown_source_context` gains an optional `material_review` object
with contract `moontown.shared-material-review.v1`. It contains the scoped
material reference, observed/included/excluded subject identities, original
operator hypothesis, capture timestamp and SHA-256 binding of the entire
reviewed group. The binding covers sorted subject identities and each captured
pack/product/version, title, summary, schema, lifecycle and evidence-reference
array. Publication time alone is excluded from the content binding; the original
capture timestamp remains historical provenance. An unchanged timestamp-only
republish and subject-array reordering do not invalidate the group.

This is deterministic grouping of published references. It does not read the
referenced files or prove their byte identity, resolve aliases, infer semantic
similarity, discover cross-pack equivalence, identify a contradiction or prove
independent corroboration. Groups sharing different references never merge
transitively. The digest is a browser content binding, not a signature or atomic
server compare-and-swap. Publication can change between preflight and intake.
Source text remains literal data.

Discovery is bounded to 128 entries in each snapshot pack collection and 1,000
total projected observations. Invalid/ambiguous observations and unavailable
packs are skipped with visible counts. Groups are ordered by observation count,
then exact scoped reference; at most forty are displayed with a truncation
notice. Layer filtering narrows displayed groups. More than 128 observations
in one group disables review instead of silently picking a subset. Existing
source-text limits, twelve included sources, 2,000-character operator notes and
the complete 128 KiB UTF-8 candidate-body limit still apply.

## Product and verification scope

This supports MOONTOWN-UC03/B03's cited, review-pending output boundary and
MOONTOWN-UC05/B05's source-linked, fresh actionable view. It advances the
Pack–Town bridge's observation-to-candidate step. It does not complete configured
cross-book synthesis, contradiction resolution, recurring watches, accepted Book
knowledge, named-human acceptance, production identity, backup/restore or
always-on service gates. No saved-time or autonomous-emergence claim is made.

Run the focused shipped-handler checks:

```sh
node --test src/ui/rabbita-town/pack_candidate_sources.test.js src/ui/rabbita-town/pack_material_groups.test.js
```

All 30 focused tests pass, covering the connected journey, exclusions, cancel and
refresh retention, stale/invalid/unavailable groups, limits, literal rendering,
repeated continuation, preflight overlap, lost-response replay and asset
declarations. Tests use a minimal event DOM and substitute fetch responses;
they do not qualify browser layout, focus behavior, accessibility or live intake.

The broader frontend suite has seven reproduced baseline failures: five runtime
asset tests lack the assembled `landmark-studio` asset directory, one intersection
view assertion differs from current map source, and one transit portal assertion
differs from current map source. They also fail on the verified baseline.
No native production source or schema changed. Full production assembly, native
intake execution and real-browser/installed workflow qualification remain
separate release gates; a focused pass is not a full release pass.
