# Creative contest built-in voting

Trusted `Config.voting_mode: "builtin"` opts in. Omitted or `"external"` keeps
the existing Tencent/explicit non-counting preview behaviour. Existing official
events are not silently changed. New activities must publish these rules:
one active vote per signed-in account; change or cancel before closing; no
self-vote; approved roster only; withdrawals before close invalidate votes.
Identity registration currently does not prevent multiple-account abuse; do not
advertise person-level or verified-email fraud prevention.

All existing creative endpoints and `execute` / `image` signatures survive.
The gateway continues to supply the verified actor and reject forged identities.

## Actions

- `vote`: `{entry_id: string, intent: UUID string}`. Replaying the same intent
  and choice is idempotent; reusing it for another action/choice conflicts.
- `cancel-vote`: `{intent: UUID string}`. Cancels only the caller's current vote.
- `settlement`: `{}`. Read-only authorized host export, after voting closes.
  Returns standalone `{settlement:{...}}`, not a regular creative snapshot.
- `disqualify`: `{entry_id, reason}`. Authorized host only, approved works only,
  with a mandatory reason. Removes public visibility; an append-only private
  review event records actor, revision, previous/resulting state, time and reason.
  These events are not published, and legacy history is not fabricated.
  Live votes stop counting.

## Snapshot addition

`voting` is always present:

```
{
  mode: "builtin" | "external",
  phase: "waiting" | "open" | "closed",
  can_vote: boolean,
  my_entry_id: string,
  roster_version: integer,
  roster_digest: string,
  settled: boolean,
  settlement_version: integer,
  settlement_digest: string,
  counts: [{entry_id, votes, rank, eligible, status}],
  total_votes: integer,
  rules: string
}
```

`my_entry_id` is only the current viewer's active eligible choice. No voter IDs,
vote intents, account lists or per-voter timestamps appear in public or host
exports. `counts` includes eligible zero-vote works; ties share competition rank
(1, 1, 3). IDs provide stable ordering within a tie. Withdrawn rows have
`eligible:false`; no identifying metadata is added through voting projections.
During open voting the UI polls every four seconds and labels that cadence.

Builtin `voting_url` is empty and `voting_preview:false`; the page uses the
builtin controls, not an external link. `set-voting-url` is unavailable in this
mode. The legacy fields keep their existing meanings in external mode.

## Frozen data

At the first operation/worker tick at or after opening, persist one roster
containing the exact approved entry IDs, generation IDs, PNG digests, names and
titles. A canonical public-row digest binds the roster and its schedule.
Approved entries cannot be added after opening. Once frozen, changing the
configured vote window or voting mode fails closed.

At the first operation/worker tick at or after closing, persist one immutable
tally and digest. New vote changes are rejected. Later withdrawals revoke public
image access and mask exported metadata, while the sealed tally/version/digest
stay unchanged. Settlements contain frozen counts and an explicit withdrawal
flag; they never expose voter identities. Public gallery remains only currently
approved works.

The host export has challenge_id, roster_version, roster_digest, version,
digest, closed_ms, total_votes, rows. Each row has entry_id, votes, rank,
eligible_at_close, withdrawn, title, display_name, generation_id, sha256;
identifying fields are empty for currently withdrawn works. Export privacy
redaction does not rewrite the original sealed counts or roster digest.
`status` distinguishes approved, withdrawn and disqualified works; the existing
export `withdrawn` flag means identifying metadata is withheld for any removal.

State migration fills absent ballot/roster/settlement arrays for old files.
New fields are required arrays rather than nullable Option payloads, so a newly
saved state round-trips safely. Existing generation claims and locking survive.
Once real ballots exist, retain a compatible native writer on rollback: an old
State serializer could otherwise discard voting fields. Static-UI rollback does
not require rolling back the native service or its state schema.
