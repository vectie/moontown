# 第三期封面：杯中暹罗

The user requested a name unrelated to 半醒, then rejected 对味 as insufficiently
evocative. The implemented recommendation is 杯中暹罗: a Siamese cat beside the
cup and another face within the coffee. The source is one complete overhead
illustration, preserving the curled cat, paw/saucer contact and shared window
shadow. Only the footer moves; the cover is static as explicitly requested.

Public surface: https://suanli.kechuangfuwu.com:8443/disp/

## Scope and award attribution

The display announces the third cover as a preview. No third-round start/end
dates were supplied, so the release does not invent them or advertise generation
into the closed second event. QR and phone CTA are labelled 活动与作品 / 查看历届作品;
they use campaign `coffee-03`. Existing community QR and partner marks remain.

The bottom ticker has six groups: two issues, each with first/second/third prize
display slots in counts 1/2/3. Twelve work cards comprise four organizer-confirmed
participant works and eight clearly attributed AI supplements.

- First issue: 小王《深秋半醒，刚刚好》 first; 勺子《勺子》 and 草莓奶昔《森林氧吧》
  third, as previously selected by the organizer. Existing AI works supplement
  the two second slots and remaining third slot.
- Second issue: the user explicitly selected 魔法使《执豆为杖 予你醇香》 as first
  on Nov22. Its original is tied to approved entry `c14d65aa…`. The five remaining
  slots use new AI exhibition images in five different visual media.
- Every AI card says AI 补位 and 主办方 AI 创作, including the enlargement caption.
  No imaginary participant account, submission, vote or award record is created.
- The second event has zero votes and its native three-prize publication requires
  three positive-vote works. This cover is an organizer-confirmed display award
  announcement; it does not claim native vote-based prize publication succeeded.
  Formal event state, its rules, roles, closed voting and schedule remain intact.

## Assets and performance

`display-awards.js` carries period/rank, participant attribution, AI provenance and
the confirmed second entry ID. Covers are 492 KiB desktop / 108 KiB phone WebP;
new work thumbnails are 24–48 KiB. Full PNG works load only after explicit click.
The native cover source is1672×941, retained as `siamese-cover-original.png` with
its prompt. The page was composed and inspected at3840×2160, with a complete 4K
screenshot; this does not turn the underlying source into native4K detail.

The desktop footer is9.5% with a90px floor; phone footer is166px. A48px/s minimum
scroll speed prevents the screen-relative formula from making a phone cycle take
over ten minutes. At390px, one complete two-issue cycle is about61 seconds.
Pause, focus, background-tab and reduced-motion behavior are retained. Thumbnails
open a local dialog and keep clear title, source and return controls.

## Publication and verification

The dedicated scripts prepare exact assets/QR, stage a41-file SHA-256 manifest,
upload through the existing authenticated port32123 management jump, and verify
the old live HTML digest before writing. Changed files have private backups;
versioned modules/data are served before HTML. The second pass includes cache-
busting queries for both linked modules after the phone-speed correction.

First release backup:
`/home/HwHiAiUser/coffee-third-cover-20261122`.
Final release backup/receipt:
`/home/HwHiAiUser/coffee-third-cover-20261122-final`.
The original second-cover HTML/scripts and all media remain available for rollback.
The native service, GPU workloads, contest runtime and permissions are unchanged.

Validation: nine focused source/manifest tests; formatted and checked standalone
MoonBit scripts; actual browser desktop4K and phone390px checks, twelve cards in
six groups, no horizontal page overflow, matching QR dimensions,48px phone CTA,
second-winner enlargement and AI-provenance enlargement. Internal HTTPS443 and
public HTTPS8443 verify all41 published file hashes with TLS validation enabled.
Do not infer public443 reachability from the internal test. Screenshots and
verification JSON live under `output/coffee-third-cover-20261122`.

To reproduce the manifest check in a clean checkout, run
`moon run scripts/prepare-coffee-third-cover.mbtx stage` before
`node --test src/ui/coffee-display/display-awards.test.mjs`.
The final live HTML SHA-256 is
`00272dc583661bf32b0a7277b343b6de1e2ffb173170763ca2cae898745d56a1`.
Final phone browser measurement was61.2928 seconds per cycle at390px;
the3840×2160 live browser showed six groups and eighteen buttons (twelve works,
six prizes), with no horizontal page overflow. Final screenshots are
`live-desktop.jpg`, `live-desktop-4k.jpg` and `live-mobile-cover.jpg` in that output
directory.
