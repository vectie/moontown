# Coffee titles, nickname memory and approved sharing

## Delivered behavior

- Empty work names get a local suggestion from the selected image's prompt; uploads use a generic suggestion. “换个建议” is explicit. Typed names survive reopening/reload. Automatically suggested names follow a newly selected image; manually edited names remain intact. “森林绿” is a color, not a forest theme.
- Nicknames persist by authenticated account across events, with IndexedDB and synchronous localStorage backup. Account switching retains each draft without copying another account's nickname. Names are local convenience data, not authentication.
- Only entries in the authoritative public gallery expose sharing. The on-demand 1080×1560 PNG includes the 768px preview, work name, public nickname, AI attribution and a work-specific QR with four quiet modules. No prompt, private account ID or existing URL credential/query is included. Sharing has save/copy fallbacks and native file sharing where supported; no external recipient was selected during acceptance.
- A shared link opens the public wall at that work. Withdrawn or unavailable links show a generic explanation. Revocation removes the sharing button and closes an open card. Already saved pictures cannot be recalled; cards explicitly defer current status/voting to the activity page.
- First/second/third prizes use the existing illustrative toy/tote/coffee-voucher art with aligned cream/orange/sage cards in the display, activity details and published award results. Prize artwork remains illustrative, not a promise of a particular purchased product.

## Acceptance

Private native HTTP fixture: `http://127.0.0.1:4400/user/`, retained state `/private/tmp/coffee-participation-sharing-state-20261109`. Static cup fixture, **no new GPU inference**. Roles A, B and host were switched sequentially through the visible fixture UI; these were not simultaneous independent browser sessions.

1. A generated with an empty prompt, received a suggestion, edited title/nickname, reopened after reload, submitted, was returned with a reason, revised and resubmitted.
2. B generated the cloud theme, received “云朵还没醒”, initially had no A nickname, entered “云朵同学” and submitted.
3. Host reviewed both and approved. A saved a real PNG, copied its link, and opened the exact work. B opened its own card at 320×568. At 375×400 the close control remained visible and usable. Widths 320/375 had no horizontal overflow.
4. B withdrew; its share button disappeared and its old link displayed the unavailable explanation. B's nickname survived resubmission, which the host approved again.
5. Only the isolated event config was advanced into builtin voting. A and B each voted for the other's work; the server counted two valid ballots, one per work, tied rank1. Own-work voting was disabled. Production schedule and entries were untouched.

Screenshots in `/Users/kq/Workspace/moontown/output/coffee-titles-sharing-20261109/`: `mobile-submit-draft.png`, `mobile-host-two-entries.png`, `mobile-share-a.png`, `mobile-share-b-320.png`, `mobile-voting-two-users.png`, `mobile-prizes-activity.png`, `live-mobile-prizes.png`. Downloaded card: `share-card-a.png`. The private images are interface evidence, not different model outputs.

Checks: browser 202/202; root native 2072/2072 with documented local Claw/Book fixtures; gateway `src/main` native 10/10; QR module JS 1/1; scripts checked, scoped info/fmt and diff whitespace clean. Initial root run omitted the required fixture environment and failed six integration guards; rerun with actual built local fixtures passed all 2072. An accidentally unscoped gateway workspace run hit unrelated cached moonlib/async API compilation errors; the required gateway package run passed 10/10.

## Publication

- UI: `sha256:b171719c9adef06f88c030b90d898089b3ab2305807d6d11cc725764d6b7729d`.
- Runtime retained: `sha256:dfc9d4d371874dc3348e8139bd5e0a09ea70c907ff0bf8afd6a6ed8adf90278e`.
- QA then formal static-init image rollout, deployment backups and receipts: `/home/HwHiAiUser/coffee-sharing-20261109/`. Six changed files compare byte-identically through compressed delivery on both 443 and8443 for QA and formal. Formal durable state compared identical to the private pre-rollout backup.
- Initial formal GET verification immediately after rollout returned one503. Subsequent GET200 and complete asset comparisons passed. Separate HEAD probes returned502/empty reply; do not treat HEAD results as a substitute for actual GET acceptance.
- `/disp/` v8 manifest `a2067cbbfeaa7d817b03c08fe0910eb03972e755b3fc82b9b67e53c04669cc07`. CSS/HTML-only publication, immutable backup `/home/HwHiAiUser/moontown-display-20261108/copy-prizes-v8/`, receipt `verification-v8.json`. Both public ports pass exact bytes, QR preservation and video Range206.
- QR browser dependency is compiled from the already-used Apache-2.0 PaiGack MoonBit QR library. Lazy module is about20KiB uncompressed; it does not load during initial creation or ordinary gallery browsing. Cards use a bounded768px preview, generated only on request, and release Blob URLs on close/account change.
