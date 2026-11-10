# Coffee invitation design v10

This replaces the rejected v9 floating prize arrangement. The user found both the surrounding layout and its proportions poor.

## Design

- Treat the footer as one orange invitation band: original English invitation at left, three equally sized prize illustrations in one row, then a primary participation QR and a smaller community QR. Keep the existing title and upper-right partner marks.
- Desktop visible poster area remains the same. Clip only the video's baked footer and rebuild the orange footer as actual responsive HTML. This prevents the original fixed footer from forcing tiny floating cards, cramped captions or oversized gaps. No video re-encoding or new media.
- All three prize sprites use equal square view boxes and preserve the source image's720×240 three-cell aspect ratio. Desktop illustration boxes are86×86px at1920px; mobile64px, or56px on320px. The naturally wide coffee voucher remains wide rather than being stretched.
- Desktop primary/community QR widths are9.4/6.2cqw, with captions on the same bottom baseline. On375px mobile they are144/80px; on320px the secondary code is72px. Mobile puts the48px “开始创作” button before the QR row, so a phone user can participate directly.
- Body text in the orange band has about4.93:1 contrast. Existing logos, QR payloads, prize illustrations and font family remain intact. No additional dependency, asset request, animation or GPU inference.

## Acceptance and release

- Browser layouts verified at1920×1080,1280×720,375×812 and320×740. No horizontal overflow or prize-label overflow. All images decoded. The375px primary action occupies y530–578;320px occupies y497–545. Desktop primary/community caption bottoms both equal1039.44px.
- A native screenshot immediately after changing viewport briefly showed a stale enlarged crop despite correct DOM metrics. Browser-tab `screenshot()` produced the correct composition; exported evidence uses that API after checking actual viewport dimensions.
- Formal screenshot evidence: `/Users/kq/Workspace/moontown/output/coffee-invitation-design-20261110/live-desktop.jpg` and `live-mobile.jpg`.
- Both443/8443: HTML200, exact CSS/brand/prize/QR bytes, video Range206, entry page200. Receipt: `/home/HwHiAiUser/moontown-display-20261108/verification-invitation-v10.json`.
- Cache key `20261110-invitation-10`; manifest SHA256 `b6297af4f9446c12d9d5d3fa44a55d30a0a8a81436fa96910f38aa57132f163e`. Pre-publication backups and staged sources: `/home/HwHiAiUser/moontown-display-20261108/copy-invitation-v10/`.
- Changed HTML/CSS only, published atomically with previous-version guards. Scripts checked; scoped `moon info`, `moon fmt`, and whitespace verification passed. No new implementation-mirroring tests for this reversible visual correction.
