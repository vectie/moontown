# Third cover: 暖暖

The user renamed the third theme to 暖暖 and identified the tail as appearing to
grow from the head. This supersedes 杯中暹罗 as the current display name. The page
title, description, visible h1 and accessible section name are updated together.
This remains the third-issue preview; no event dates or competition state change.

Built-in ImageGen was used in precise-object-edit mode. Starting from the
existing master, the correction separates the cream chest/front leg from the
tail, places one visible tail root at the rounded rear haunch above/right of
the head, routes the tail outside the saucer, and tapers toward the lower center.
The final pass raised its foreground tip to account for the existing footer.
The head has only two ears and a clean neck contour. The cat/latte faces, morning
light, overhead framing and warm paper illustration remain the same direction.

Final saved master:
`src/ui/coffee-display/assets/warm-cover-original-v1.png` (1672×941).
Public derivatives: `warm-cover-v1.webp` (329326 bytes) and
`warm-cover-mobile-v1.webp` (91042 bytes). Original art remains available alongside
the new version. No CSS, JS, logo, QR, prize or award data changed in this release.
The runtime display still uses the previous accepted layout-v4 resources.

The source tests now validate the current local HTML/module/asset references
directly, allowing a clean checkout to run them without historical output files.
`release-coffee-warm.mbtx` builds the WebPs, stages and hashes exactly two images
and HTML, guards the previous public HTML digest, publishes images before HTML,
and verifies the public byte hashes with TLS validation. Management backup and
receipt: `/home/HwHiAiUser/coffee-warm-20261122`.

Image edit lineage (built-in outputs retained):

1. `exec-900efbe4-0995-441b-b719-c72cc031d186.png`: first anatomy clarification.
2. `exec-3efae37a-d84c-474e-b530-abdaf6a715d2.png`: explicit upper-right hip root,
   tail along outside of cup, free tip lower left; remove lower-left neck join.
3. `exec-cbecdfb9-bd0e-4544-a90e-2bedcd8f55f6.png`: selected final, lifted tail tip.

Final prompt (verbatim):

> Precise final production adjustment of this exact wide illustration. The single-tail anatomy is now correct: preserve its visible root at the upper-right rear hip, its route down the outside right of the saucer, and the clean cream chest/front-leg at lower left. Keep the Siamese head, blue eyes, cup with latte face, body, paw, warm flat painterly style, paper texture, window shadows, exact wide framing unchanged. Only lift the tail's LOWER foreground curve and tapered free tip approximately 80 pixels upward in this 1672x941 composition, so the whole tail INCLUDING ITS TIP stays ABOVE y=835 (top 88% of the image). The lower 10% of the image should be calm cream tabletop and soft shadows, because an existing website footer overlays it. Do NOT add or depict that footer, text or any graphics. Make the tail curve pass comfortably below the cup and beside the front paw, no collision or second tail, and let its slim free tip end around lower-center left with clear tabletop space separating it from the neck and front leg. Exactly one tail from the rear rump, no tail from head. Preserve all other composition, colors, light, subject proportions and painterly detail.

The numeric safe-area coordinate is prompt intent, not a pixel-perfect guarantee;
the selected result is accepted by inspecting the actual composed page. Native
art dimensions are1672×941, independent of the4K browser layout.

Acceptance:9/9 focused source tests, standalone script check/format, all three
published hashes verified over validated public HTTPS. Live desktop title/h1 are
暖暖 and the loaded image is1672px wide. At390px the960px derivative loads, both
QR frames are132px, the direct action remains48px, and the page has no horizontal
overflow. At3840×2160 the footer remains172.8px with no horizontal overflow.
All12 work cards remain present. Screenshots are in
`output/coffee-warm-20261122/{live-desktop,live-mobile,live-4k}.jpg`.
Final published HTML SHA-256:
`ce029fec779f7b38c1e10ab0afdf63f804fc194be0327d4f88320af2c80272db`.
