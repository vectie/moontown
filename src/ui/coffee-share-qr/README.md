# Coffee share QR

Thin MoonBit wrapper over [PaiGack/moonbitqrcode 0.1.0](https://github.com/PaiGack/moonbit-qr), Apache-2.0, already used for the display participation QR. Uses medium error correction; the canvas renderer adds a four-module quiet zone and integer pixel modules.

Rebuild the checked-in browser module with `moon run scripts/build-coffee-share-qr.mbtx` from the repository root after installing the existing Rabbita UI esbuild dependency. An esbuild executable path can be passed as its only argument. The resulting ESM is loaded on demand when opening a share card.

`matrix(text)` returns `[size, ...row-major black-module bits]`. Callers supply only a validated public activity URL, never prompts, credentials or private account IDs.
