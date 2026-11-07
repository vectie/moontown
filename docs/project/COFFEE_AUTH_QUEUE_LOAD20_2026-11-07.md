# Coffee authentication, queue, previews and 20-person acceptance · 2026-11-07–08

This is a second bounded load run against an isolated activity, with twenty real
ordinary account sessions and twenty newly generated images. The public first
event and existing programme activities are separate from these test works.

## Authentication fix

The native twenty-client diagnostic separated connection establishment,
`/user/auth/session` and `/user/v1/auth/self`. Connection establishment took
about 0.3s and session reads took milliseconds; profile reads reached 3.6s.

LunaNexa `AccountStore::authorize` acquired the global account-store mutex,
copied all sessions, touched `last_used_unix_ms`, then persisted the complete
account snapshot on every authenticated read. Twenty different identities
therefore serialized twenty durable snapshot writes. This exceeded MoonTown's
unchanged 3500ms identity deadline during the previous generation test.

The generic account fix continues checking the current account, session,
expiry, revocation and required role on every request. It updates session
activity in memory, coalescing durable activity checkpoints across **all users**
at a maximum frequency of one per 30 seconds. Security mutations still persist
immediately. The first read after process startup checkpoints once; a failed
checkpoint rolls back its touch and remains retryable. After a process crash,
the last-used telemetry can be older than the last request; it is not used as
an authorization cache or a replacement for the session's hard expiry.

The deployed controller source was patched against its exact existing release,
preserving onboarding and event features. Its previous executable and deployment
snapshot remain available. The unrelated dirty LunaNexa working tree was not
published. Two stale remote event-policy test fixtures needed their existing
optional limits filled with `None`; those are test-only changes, separately
backed up. Account tests: **15/15**, including distinct-user checkpoint
coalescing, persistence failure, suspension, role changes and session revocation.

## Queue and mobile behavior

The existing generation status area shows the number of people ahead and an
approximate time to start, then an approximate time to finish while running.
The estimate uses the latest ten valid execution durations and the worker's
scheduling interval; the initial estimate uses a ten-second service interval.
Position follows the worker's FIFO order. Only the viewer's own generation
receives this projection; other accounts, prompts and job identifiers are not
exposed by it.

Abnormal states suppress numeric estimates: activity pause/revocation, a job
requiring reconciliation, the submission deadline and an execution overrun.
The existing polite live region is retained. Polls are spaced by four to five
seconds while active, reducing synchronized browser bursts. The load harness
continues stressing with synchronized twenty-client polling.

The 375px creation screen has 16px input text, a 54px generate button and no
horizontal overflow. Gallery images already use lazy loading and reserved
square space. Actual twenty-work mobile screens and load measurements are
recorded below after the new run.

Focused native checks: creative contest **23/23**, gateway **9/9**, image preview
**2/2**, curation bridge **5/5**, account identity **6/6**, activity program
**11/11**. Browser source tests **194/194**. Static production assembly and
manifest verification passed (809 files, 72.2 MiB). The final complete MoonTown
native run passed **2,067/2,067**, with the required local Claw oneoff fixture
and Book outcome receiver executables configured. No real provider is used by
those crossing fixtures. An earlier aggregate run had one concurrent voting
fixture conflict; the focused rerun and final complete run passed.

Root source pins async 0.16.6 while the deployed gateway pins 0.22.4. Preview
writes and voting/backfill test fixtures now select their creation modes
explicitly, matching the deployed version's existing CreateOrTruncate default.
This also makes the root package tests reproducible under the older default.
The first complete root attempt exhausted the development filesystem; generated
caches were cleaned with `moon clean` and the complete run succeeded with two
build jobs. A run without the documented Claw/Book fixture environment passed
2,061 and rejected six crossings; configuring the existing fixtures resolved
all six. Source, runtime data, backups and test evidence were preserved.

## Image delivery and mobile verification

Original PNGs remain the source of truth. CPU-only libpng/libwebp processing
creates a 384px thumbnail and 768px preview, preserving aspect ratio without
upscaling. Gallery cards use responsive thumbnail/preview candidates and lazy
loading; history uses thumbnails, while generation results and review use
previews. An original is requested only by explicit zoom or save. A saved image
retains the original 1024px artwork plus the existing visible AI footer.

The native decoder accepts only bounded PNGs (12 MiB, at most 2048×2048);
encoding strips ancillary metadata and uses WebP quality 82. Owned files use
atomic, synced replacement. New generation completion attempts both derivatives;
idle worker iterations backfill older completed jobs without inference, quota,
state, voting or original-image changes. A bounded file-presence cache avoids
repeated NFS stats; it never caches identities or approval decisions. Missing
requested derivatives invalidate that cache and can be repaired.

Approved image variants are already public and now check their live approved
entry before making any identity calls. Unsubmitted/pending works retain owner
and manager checks; withdrawal immediately makes public access fail even if a
derivative still exists. Responses have an explicit Content-Length and no-store.
Native gateway tests cover private variants, approval, withdrawal and public
image delivery during an identity outage. Original-read and vote ACLs remain.

R5's twenty real originals total **20,350,146 bytes**, thumbnails **200,534
bytes**, previews **548,040 bytes**. Every original matched its server SHA256;
all forty first-download WebPs decoded successfully. Twenty visitors each
loaded all twenty approved R2 thumbnails: **400/400 HTTP 200**. This is about
99% less image transfer for the thumbnail set than for the original set.

Actual 320px/375px browser views have no horizontal overflow. DOM inspection
found zero original artwork image elements before zoom; the opened original
decoded at 1024×1024. The Save button produced a 1024×1084 PNG, including the
existing 60px AI footer. The 375px host view contained twenty 768px review
images; one review was performed in the mobile UI, then the other nineteen via
attributable API operations. Screenshots are under
`output/coffee-auth-queue-20261107/`.

AddressSanitizer native image tests: **2/2** (macOS, leak sanitizer unavailable).
Linux native preview tests: **2/2**. The backfill regression also verifies byte
identical state/original preservation and repair after a cached thumbnail is
removed.

## Remaining authentication layers and failed iterations

The account checkpoint fix improved a sixty-profile diagnostic P95 from 3632ms
to 262ms. This probe did not qualify the entire activity under sustained load.
R2 still had 20 HTTP 503s, R3 had 49. R4 had no HTTP 503s but one original body
timed out at 30 seconds, so it was not a complete pass. R5 completed all twenty
generations and sixty image downloads, but had **150 HTTP 503s / 790 measured
requests**. Its errors were profile-stage identity timeouts. These failures are
retained in private evidence; no failed image download triggered GPU resubmission.

The browser gateway also used one synchronous PostgreSQL connection and mutex
for every live session read and activity refresh. It now uses the project's
existing asynchronous four-worker pool. Reads, expiry, logout and bearer matching
still consult the live database. Gateway tests **44/44**, including a real
dedicated `lunanexa_test` database test which locks one session row while reading
another within 500ms. Native host tests resolve the database service's ClusterIP;
cluster DNS names do not resolve on the management host. Never aim these tests
at the production database.

After this change session-read P95 was 93ms, while direct controller profile
reads still reached 2239ms and gateway profile reads 3365ms. Operational request
recording was still on the profile response path. The controller change sends
a freshly authorized GET `/v1/auth/self` response before recording its ordinary
operational event in the same request task. Security mutations keep the existing
audit-before-response path; recording failures get a credential-free diagnostic.
The real HTTP regression confirms 200 for a valid live session and 401 after
revocation even when operational persistence fails (**1/1**). No authorization
cache, timeout increase, TLS bypass or alternate identity authority was added.

Two private preview image candidates failed startup: an OCI directory inherited
umask restrictions, then a shared libm dependency was missing. Both were rolled
back before application execution. The qualified image normalizes directory
modes and includes libpng, libwebp, zlib, libm and their copyright files. The
gateway hostPath similarly needs explicit chmod 0755 after mkdir under umask.

## Release artifacts

- Runtime: `sha256:b760272cdac808f232d468873add989dbfe374cef0d2ddf19ce7d538caa7e743`.
- Final UI: `sha256:7dccb07f24d9dde7bcb446a74c19a5f0ee2adcca7d2cb5059cf7ccc8dac2c1bc`.
- The qualified native MoonBook CLI, its seed and the restricted 1.2.0 curator
  package are preserved in the new runtime.
- Management release root:
  `/home/HwHiAiUser/coffee-auth-queue-20261107` (operator private).
- Each repeat uses a separate PVC and event (`coffee-load20-rN-20261107`),
  an allowlist of exactly twenty ordinary participants, one generation per
  person, a total cap of twenty and the existing scoped QA host.
- No model settings, provider grant expansion or GPU reservation changes.

Formal and QA runtime/UI upgrades are Ready. Both complete PVCs were backed up
and restored for validation before switching runtimes. The formal registry and
legacy state were absent before upgrade and remained absent; an empty registry
was not fabricated. Formal backup `formal-previews-v2` accepts this absence only
when the entire programme volume is empty apart from a zero-byte regular lock.
Failed/Succeeded historical Pods are not active writers; an old Failed Pod must
not keep a stop-and-backup procedure waiting for its deletion. The first formal
attempt restored the compatible runtime when its QA-specific registry check
failed; the corrected second attempt passed. Private backups are mode 0600.

R2 completed twenty submissions, twenty approvals and twenty votes, naturally
sealing its 10/6/4 vote result. R5 repeats the twenty-work thumbnail review and
voting path. Neither rehearsal publishes real awards or enters the formal event.

## Final paired identity release and R6 evidence

A subsequent native controller release had overwritten the account checkpoint
source with its earlier version (SHA256 4151f3ff…). The first profile-response
candidate therefore did not retain both fixes; its direct diagnostic still
reached seconds. The final build restores the checkpoint in the current model
controller source, preserving the newer GLM controls/configuration. It requires
unchanged source hashes before/after compilation and a binary receipt for both
fixes. Current deployed-source account tests: **16/16**; live profile HTTP test:
**1/1**. The native controller is
`7bef5632a0cabb04ed42020e9a5651bf3a2c2f105b416bcd823141671027b463`;
browser gateway is
`2c973649c7d9c6d585289beb7f3d88cab01f9ea327a9b72815ccb5d4a26f7f9f`.
The gateway preserves monotonic last-used timestamps across out-of-order writes.
The narrow source fix was merged with current LunaNexa main, passed its strict
native check and **1,959/1,959** complete native workspace tests, and was pushed
to both main remotes as `0685c0e`. The unrelated dirty source changes were preserved.

With both fixes deployed, twenty live identities completed all sixty profile
checks: direct-controller profile P95 **6ms**, gateway profile P95 **57ms**,
session P95 **42ms**. A sustained twenty-client, fifty-round read-only run
returned **1,000/1,000 HTTP200**. No profile-observation failure diagnostic was
seen in the inspected deployed logs.

R6 admits **twenty concurrent generation requests within 1ms**, completes
**20/20 distinct new artworks**, and keeps GPU inference serialized at one job.
There are **1,147 HTTP200 responses and zero HTTP503s** in the measured run.
Generation execution P50 is **8.576s**, P95 **8.746s**; the first client observes
completion at **11.167s**, the last at **206.653s**. Queue and resource
distributions are in `output/coffee-auth-queue-20261107/load-r6-summary.json`.
While these jobs ran, twenty other visitors loaded twenty approved R5 thumbnails
each: **400/400 HTTP200**. All forty R6 thumbnail/preview downloads decoded.
An actual A-to-B request for an unsubmitted private thumbnail returned **404**.

Do not interpret HTTP200 as a complete original-image body: the initial
twenty-original burst had **19/20** SHA matches. One HTTP200 stream stopped at
134,934 of 884,536 bytes and curl timed out at 30s. The evidence and partial body
remain retained. A download-only recheck matched **20/20**, without inference.
A controlled HTTP/1.1 burst completed twenty originals on the first attempt;
an HTTP/2 burst had one first-attempt timeout and **20/20** complete hashes after
one bounded retry. This comparison does not prove whether the intermittent
transport fault lies in the client, proxy or network.

Zoom and save now share a twelve-second image fetch with one jittered retry for
transport/5xx failures. Authorization failures and invalid bodies are not
retried. Closing the viewer or switching identity cancels its request; late
responses cannot replace another user's view. Failed recovery leaves an explicit
retry action. The phone queue suppresses exhausted-quota copy while a job is
already queued/running. These final UI changes have deterministic failure,
authorization, cancellation and retry-bound tests; they were made after the R6
HTTP run and separately verified in the actual mobile UI.

R2/R3/R4/R6 inference rehearsals are stopped, their public routes and added
network policies removed, and all PVCs/evidence retained. R5 remains a read-only
twenty-work example, with twenty approved works, twenty votes and a naturally
sealed settlement. Its public entry is
`https://suanli.kechuangfuwu.com:8443/coffee-load20-r5/coffee-contest.html`.
No real awards were published. Formal activity still has zero public entries,
zero programme activities and its 500-generation allowance.

Final phone captures are under `output/coffee-auth-queue-20261107/`:
`mobile-final-gallery-320.png`, `mobile-final-gallery-375.png`,
`mobile-final-leaderboard.png` and `mobile-final-original.png`.
The 320px and 375px galleries have no horizontal overflow. The final viewer
decodes the original at 1024×1024; closing it clears its image URL. The actual
saved PNG is 1024×1084, retaining all artwork pixels plus the existing AI footer.
The sealed example shows twenty votes, with 9/6/5 on the top three works.

The previous load test is documented in `COFFEE_LOAD20_2026-11-07.md`.
