# Supplied Banxing logo release · 2026-11-12

The user requested replacement of the old 半醒工坊 logo with the new Downloads raster and publication. Both the display partnership and contest activity details now use the complete supplied artwork, including the cup, Chinese lettering and “Half light studio”. Existing poster/video reference artwork is unchanged.

## Assets and rendering

- Original: `src/ui/coffee-display/assets/banxing-original-20261112.png`,4000×4000 PNG,2036221 bytes; SHA256 `97378d193b9603eaeef97e6db8cb8bdcbe0614144d9ab1ea10b216a81cb27887`.
- `scripts/prepare-banxing-logo-20261112.mbtx` detects near-white pixels for transparency and crops with20 original pixels of quiet space beyond the visible alpha bounds. It resizes proportionally to960×934 and verifies the corner alpha is0. No vector tracing or generative reconstruction.
- Web PNG: `src/ui/coffee-display/assets/banxing-logo-20261112.png`, duplicated at `src/ui/assets/coffee/banxing-logo-20261112.png`;282734 bytes,86% smaller transfer than the original. Display packaging excludes the original.
- Display uses6cqw logo height on desktop and64px on phones. Contest uses108×106 desktop and80×78 mobile, containing the full native aspect ratio. Explicit image dimensions reserve space; contest logo remains lazy-loaded.
- Display CSS key `20261112-banxing-logo-14`; contest CSS key `banxing-20261112`. Existing equal QR sizes, vertical prize stack, motion preferences and labels remain in place.

## Deployment and preservation

Management SSH alias `lunanexa-management` now reaches192.168.2.173. Namespace remains `aigc-acceptance-20260915`. The release used the exact qualified Nov11 UI rather than rebuilding or replacing the account runtime from the older checkout.

Display release: `/home/HwHiAiUser/moontown-display-20261108/copy-banxing-v14`, manifest SHA256 `9f32d9f139287a1622fcbdbf6d93bf585660d9c1dfe99861db5672926be3e5d3`. The publisher checks the previous live hashes, saves rollback files, publishes the PNG first and then atomically replaces CSS/HTML. Receipt: `/home/HwHiAiUser/moontown-display-20261108/verification-banxing-v14.json`.

Contest UI layers:

1. Qualified Nov11 parent `moon/hosted-apps@sha256:083e402f1515d397ce441e89bba609f1e4bedf976186eb02ce47b3efb6f71217`.
2. Logo-only overlay584792 bytes: `sha256:a09d209b53070e5d6a03d1a38d895d65f9d5536daf2c059a38a1f4edc8e40d53`; initial release `/home/HwHiAiUser/coffee-logo-20261112`.
3. Final20,961-byte module overlay: **`moon/hosted-apps@sha256:2fe3c7de29c44b0f16cd13f7c21e52dd94a748448b657e231d56260408e9cffe`**, tag `account-binding-banxing-logo-final-20261112`; release `/home/HwHiAiUser/coffee-logo-20261112/final`.

QA was rolled out and checked before formal. Only the `public-assets` init image changed. The verifier compares complete runtime-container and volume specifications with the pre-release snapshot. Formal runtime remains `moon/moontown-account-gateway@sha256:5baf6c9c2c930abf41ab2a4ba839adedf7cc80ee624145ccc64954928803325e`, preserving Nov11's account-storage fix. QA runtime remains `sha256:dfc9d4d371874dc3348e8139bd5e0a09ea70c907ff0bf8afd6a6ed8adf90278e`. No contest records, user accounts, model configuration or GPU jobs were changed.

Final scripts: `package-banxing-logo-ui.mbtx`, `deploy-banxing-logo-ui.mbtx`, `verify-banxing-logo-ui.mbtx`. They guard immutable image identity and current deployment resourceVersion. Final backups/receipts: `final/before-{qa,formal}.json` and `final/verification-{qa,formal}.json`. To revert the entire UI release, restore the pre-logo083 init digest; runtime remains unchanged. That original UI lacks the modules described below, so prefer a corrective overlay over restoring its broken coffee entry.

## Existing production loading defect fixed

During actual formal-page acceptance, the event heading stayed “正在载入活动…” and schedule fields remained empty. Nov11's production UI lacked `coffee-share.js` and `coffee-qr.js` (HTTP404); the entry module imports sharing, which prevents initialization when absent. The already-existing source modules were restored with raw, gzip and ETag variants in the final overlay.

`assemble-production-build.mjs` now includes both modules; `verify-production-build.mjs` requires all coffee browser modules. `runtime_asset_manifest.js` includes the new PNG. New regression checks walk the actual entry's static/dynamic relative ESM graph and validate HTML coffee-image references against runtime assets. These verify shipping behavior rather than merely checking the changed names.

## Acceptance

-204/204 browser tests passed; no failures/skips (`/tmp/banxing-logo-browser-tests-final.log`). Standalone MoonBit scripts passed focused `moon check` and formatting; scoped interface/format checks completed. No full native rebuild or GPU concurrency run was necessary or claimed.
- Display: both443 and8443 returned exact HTML/CSS/JS/brand/QR assets, video Range206 and participant HTTP200. Mobile320px had no horizontal overflow. Desktop1920×1080 retained the full composition and new mark.
- Final QA and formal: both443/8443 returned the exact compressed HTML, CSS, logo and two restored modules. Container/volume specifications were unchanged.
- Actual formal browser at375×812 rendered “半醒咖啡 · 第01期”, real schedule and enabled generation action. New image decoded at natural960×934, mobile layout80×78, no horizontal overflow. QA also loaded its real rehearsal event/gallery and no warning/error logs.
- Screenshots: `/Users/kq/Workspace/moontown/output/banxing-logo-release-20261112/live-desktop-display.jpg`, `live-brand-strip.jpg`, `live-mobile-display.jpg`, `live-mobile-contest.jpg`.

Live routes: `https://suanli.kechuangfuwu.com/disp/` and `https://suanli.kechuangfuwu.com/moontown/coffee-contest.html`, also available on8443.
