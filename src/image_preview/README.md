# Native contest previews

`make` decodes a bounded PNG and creates a metadata-free WebP with a maximum
edge of 384 or 768 pixels, preserving aspect ratio and avoiding upscaling.
PNG input is limited to 12 MiB and 2048 × 2048 pixels; encoded output is limited
to 1 MiB. The original bytes are borrowed and never modified. Gallery/review
cards use 384px (768px for larger or dense displays), review and creation results use 768px, and explicit zoom/download uses the
original. The UI retains its visible AI label on every variant.

Native development needs libpng and libwebp headers/libraries. On macOS the
package uses the existing Homebrew include/library location. The qualified
Ubuntu build extracts the distribution's packages into a private build folder,
using `CPATH` and `LIBRARY_PATH`; it does not install packages into the host.
Executable consumers linking this package must link `png16`, `webp` and `jpeg` too.
The release image includes the matching shared libraries and copyright files.

Encoding is CPU-only, one job at a time. Both derivatives are generated before
a new image is shown as complete. Older images are backfilled between worker
iterations without changing generation records, votes, quotas or originals.
A failed derivative can be retried by the worker without resubmitting inference.

External uploads use `sanitize_upload`: allowlisted PNG/JPEG/still WebP, at most
8 MiB and 2048×2048 pixels. It checks the container, fully decodes pixels and
reconstructs a new PNG without metadata or appended bytes before persistence.
Unsupported, animated, malformed, mislabeled or oversized inputs fail closed.
This is image content reconstruction, not an antivirus scan or a guarantee of
malware absence. Human review still gates all public images. Production JPEG
decoding uses the official pinned libjpeg-turbo 3.2.1 package in a private build
prefix; no host package installation or GPU work is needed.
