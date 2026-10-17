# Combine contributions into a peer-challenge experiment

The Collaboration work panel can now build a new question out of multiple
retained contributions. Rather than selecting one Book's proposal, connect each
successful Book's evidence into a shared hypothesis and ask the source Books to
try to disprove it in a fresh round.

## Workflow

1. Save, prepare, explicitly run and collect a normal one-off collaboration.
   All participants must be terminal and at least two must have successful,
   nonempty retained outputs. A missing runtime remains a real blocker.
2. Choose **Combine contributions into a new experiment**. Give the next round
   a new draft ID and experiment title, then state the combined hypothesis.
3. For every completed Book, paste an exact passage from its shown contribution,
   explain its connection to the proposal, and write a specific independent
   challenge for that Book. Excerpts are limited to 1,000 characters and checked
   against the retained output; the server derives all output/source identities.
4. Describe the smallest experiment, its observable falsifier, unresolved
   assumptions, and dissent. The original independently owned objection stays
   visible and is retained. Failed Books remain named failures, never evidence
   or implied agreement, and are not assigned the new successful-participant
   challenge round.
5. Choose **Save experiment as a new peer-challenge round**. Town verifies the
   original saved revision, immutable result, terminal receipts, output bytes,
   and current retained review history, then saves a fresh draft. The proposal
   and its attributed historical excerpts are durable in the draft question;
   each Book gets its authored independent challenge assignment.
6. Inspect the reopened new draft and its captured sources. Prepare and
   explicitly run it through the existing one-off path when appropriate. The
   new result can go through the existing named-owner review and optional Book
   outcome intake. No earlier approval or run is inherited.

## What changes and what stays historical

The proposal cites the original draft/revision/result digest, review version,
review decisions, source snapshots, proposal/run IDs and exact output excerpts.
These are historical observations. The new saved round captures current files
at the original selected paths in the currently registered source Books. Its
source snapshots may therefore differ from the original snapshots. Missing or
unreadable current files block saving; no substitute source is invented.

This action reads existing retained work. It does not collect/poll old work,
launch a runtime, edit any participating Book, execute the experiment, publish
anything or accept knowledge. New challenge execution still requires the
existing explicit run action and configured runtime. Source text and proposal
JSON are marked as data, not authority.

An identical fresh-ID request with unchanged current source bytes returns the
same saved revision after an interrupted response. Reusing a conflicting ID,
changing a request after saving, or changing current source bytes on retry
blocks rather than replacing the existing draft. Reopen the saved draft to
continue, or choose another new ID for changed work. The old round is available
in the saved draft list and retained outcome library.

Form notes survive interrupted requests and same-result refresh. Changing the
question, participants, source paths, opened revision or collected result clears
them. Comparison and experiment forms can be discarded independently. A changed
result-review version is revalidated by the server; refresh before retrying.

## Product and evidence scope

The authored MoonTown PRD's UC03/B03 calls for source-bound cross-Book synthesis
that preserves named gaps and remains review pending. Its proposed F02 calls
for explicit contradiction review without silently editing either Book.
`DOCUMENT_PROTOCOL_PHILOSOPHY.md` describes returning new questions to source
Books. This feature supplies a bounded composition and peer-challenge authoring
loop toward those needs, rather than a new scheduler or synthetic vote system.

The hypothesis, bridge explanations, challenges and experiment are
operator-authored. Exact quote matching proves attribution, not semantic
support or quality. Participation does not establish endorsement, consensus,
genuine emergence, founder time saved, live-provider quality, or business
outcomes. The proposal explicitly records `genuine_emergence_verified: false`
and `experiment_executed: false`. Book still owns accepted knowledge.

## Focused verification

Run `scripts/verify-cross-book-experiment.sh /absolute/external/output` from any
working directory. It uses the pinned environment, private HOME/XDG directories,
an external target directory and the shared single-job stripped-native lock.
It copies the exact production `collaboration_contract` package into an isolated
standard-library harness and runs its tests, then checks the generated public
interface. It does not replace product dependencies or certify the host/UI.

Additional fixtures live in `src/collaboration_authoring/collective_wbtest.mbt`
and `src/ui/rabbita-town/main/collaboration_collective_wbtest.mbt` for the actual
host persistence/API action and rendered UI/payload. Their execution requires
the declared dependency versions and paired MoonChat workspace. See the round's
verification receipt for passed, blocked and unrun checks.
