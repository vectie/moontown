# Display QR / partner position swap

- User correction: “互换” means swap the QR and partner areas. Desktop partners now occupy the upper right; the participation/community QR area occupies the lower right. The first/second/third prize illustrations surround the participation QR above/left/right.
- Mobile DOM order is title, partners, moving posters, QR/prizes, community QR and direct entry, then the original orange English invitation. Preserve the original stacked 半醒工坊 bitmap and filled 向量贴贴 logo. The desktop invitation/orange stripe remains in the original video; the QR area's background is transparent so that stripe stays complete.
- Existing prize WebP sprite, QR SVG payload, community QR and brand files remain byte-identical. Only HTML/CSS changed. No new GPU job, dependency, animation loop or runtime restart.

## Verification

- Browser: 1920×1080 desktop, 375×812 and 320×740 mobile. No horizontal overflow or prize text overflow; all images decoded. The 320px QR has clear gaps from the side prizes, while desktop has a 10.5px gap between the upper prize and QR frame. Mobile direct entry is48px high.
- Production: both443/8443 HTML200, exact CSS/brand/prize/QR bytes, HD video Range206 and participant-page200. Receipt `/home/HwHiAiUser/moontown-display-20261108/verification-swap-v9.json`.
- Scripts checked with `moon check`, scoped `moon info` / `moon fmt`, and `git diff --check` passed. No new tests for this reversible layout-only change.
- Screenshots: `/Users/kq/Workspace/moontown/output/coffee-display-swap-20261110/live-desktop.jpg` and `live-mobile.jpg` (full mobile page).
- Local screenshot write initially hit ENOSPC. Removed only this task worktree's generated root `_build` via `moon clean`, recovering about1.5GiB; source, assets, retained test state and screenshots were preserved.

## Release

- Cache key `20261110-qr-prizes-9`.
- Manifest SHA256 `ba0622ede08b10bc2b8f0200eef42df7d5299f53f59a093a405b009f27c11caa`.
- Staged package and pre-publication HTML/CSS backups: `/home/HwHiAiUser/moontown-display-20261108/copy-swap-v9/`. Publisher pins the prior v8 HTML/CSS hashes before atomically replacing CSS then HTML.
