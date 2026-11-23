# Second issue first-prize product photo

The user supplied the newest Downloads photo (Nov23 12:39) for the second issue's
first prize. The photo shows a Judy Hopps detective figurine with a product box
and card. This is a PRIZE replacement, not a replacement for 魔法使's winning work.
First issue retains its Stitch plush prize; second issue now says 朱迪侦探手办.

Built-in ImageGen, background-extraction mode, extracted the actual photographed
toy on the right and removed the wall/table/box/card. Selected output:
`exec-bda7ed53-4c87-4c77-b1da-17f03dbbae3c.png`.
Saved asset: `src/ui/coffee-display/assets/prize-judy-v1.png`,1024×1536 RGBA,
2172467 bytes. `prize-judy-v1.webp` is a171×256 preview,13736 bytes, retaining
alpha. PNG alpha metadata is present; the top-left80×80 sample is entirely zero.
The cutout was inspected against the actual page's cream background.

`prizeItems.judy` supplies its own name, thumbnail and enlargement. Only issue2's
first-prize group references this key. The renderer now accepts an explicit
per-prize thumbnail instead of replacing the shared `figure` sprite globally.
Full PNG loads only when a visitor opens the existing enlargement dialog.
Warm cover-v4, layout-v4 CSS, partner marks, QR bytes and all12 work cards remain.
No account, role, vote, submitted work or formal contest state changes.

Release: `scripts/release-coffee-week02-prize.mbtx` stages five SHA-256-pinned
files, uses the existing authenticated management jump with host-key checking,
guards the previous HTML hash, and publishes assets/data/main module before HTML.
Both linked modules receive new immutable filenames to avoid mixed cached code.
Backup/receipt: management `/home/HwHiAiUser/coffee-week02-prize-20261123`.

Acceptance:10/10 focused tests, standalone script check/format, and all five
published hashes matched over validated public HTTPS. Actual390px live browser
opens the Judy PNG at1024px natural width, shows the correct name/caption, and
returns to the carousel without horizontal overflow. Computed backgrounds confirm
issue1 uses the old Stitch WebP and issue2 uses the new Judy WebP. The1920px
desktop view also retains the existing layout. Screenshots are
`output/coffee-week02-prize-20261123/live-mobile-prize.jpg` and `live-desktop.jpg`.
Published HTML SHA-256:
`271d3b8775032ce65386a804097b2502b523150cf88597ecfdc3aca1e7dff7e6`.

Final background-extraction prompt (built-in tool, verbatim):

> Use case: background-extraction. Input: an actual prize product photograph. Extract ONLY the real physical Judy Hopps detective figurine standing on the RIGHT of the photo: brown detective cap, small rabbit face with blue eyes, brown detective coat, pale hands/feet, yellow magnifying glass. Remove ALL background including the blue wall, tabletop, product box and illustrated card on the LEFT. Output a faithful photographic cutout of that single exact toy, whole cap through feet visible, centered upright with close clean framing and a small transparent margin, genuinely transparent alpha background. Preserve the exact photographed identity, proportions, paint colors, clothing, face, eyes, ears, magnifying glass, small cap bow and real product texture; do not redraw, beautify, stylize, reimagine, or generate a different toy. Preserve realistic product edge details and remove halos/leftover scenery between limbs and around the magnifying-glass shape. No text, no extra objects, no packaging, no new pedestal, no artificial opaque background.
