# Exact Town package client

This native client uploads the original file and downloads an exact selected
package through the authenticated miniapp service. It never repacks, imports,
installs, executes, or opens package contents.

## Authentication and transport

PortableClient::new takes an injected asynchronous session supplier and an
Exchange. Each request obtains its own session from that supplier. There is
no token creation, environment lookup, token argv flag, credential file write,
cookie persistence, automatic retry, redirect following, or implicit proxy.

native_exchange(origin) is the production HTTP adapter. It requires an
HTTP(S) origin without userinfo, path, query or fragment. Use HTTPS for remote
services. TLS verification remains enabled. HTTP should be used only for a
trusted local deployment. Request Content-Length is supplied in per-request
headers, and Accept-Encoding is explicitly identity. The underlying HTTP
client therefore does not automatically decompress these responses.

All operations use bounded body readers. Packages use the store's configured
maximum and chunk size, with idle and total deadlines. Response JSON has an
8 MiB feature-local bound matching the private store index. Control request
JSON and explicitly named binding files keep their 128 KiB bounds.

## Public operations

- upload(file_path, listing_id, binding) verifies local size and raw SHA-256
  before invoking the transport, then streams and verifies again through the
  same open descriptor
- list() returns current owner/exact-grant package views
- preview_share(draft) returns the service's full-package disclosure
- share(draft) creates the explicitly named exact-package byte grant
- revoke(grant_id) revokes that byte grant
- withdraw(package_id, binding) returns the withdrawal and cleanup status
- download(package_id, binding, new_output_path) first fetches exact authorized
  list metadata and then requests the pinned package/digest

Download requires matching v1 binding, separate raw-byte receipt, status,
response identity headers, identity encoding, fixed length and digest. It
rejects redirects, partial/range responses, nonidentity content encoding and
transfer encoding. Server errors are reported as stable codes, never reflected
with paths, arbitrary remote bodies or session contents.

The output is created privately and committed without replacement only after
complete verification. The companion files are OUTPUT.binding.json and
OUTPUT.receipt.json, both mode 0600, like the package. All three destinations
must be new. Sidecars are committed first, with the verified package's final
rename as the commit point. Precommit failure or cancellation removes only this
attempt's files. Cancellation after that commit keeps the complete verified
package and both sidecars; another attempt will not overwrite them. Cleanup
failure is reported explicitly.

receive_download(view, response, reader, output_path) is the same public
stream-to-file seam used by the native client and socket-free handler acceptance
fixture. It does not fetch metadata itself; a caller must supply the exact
authorized PackageView. PortableClient::download enforces that fetch.

## Follow-on work stays explicit

The receipt proves received raw SHA-256 and length only. It does not prove
semantic correctness or publication rights. After downloading, explicitly run
the existing MoonBook agent import-exact with the retained binding into a new
Book, then verify-import and existing Desk discovery.

The focused tests use synthetic sessions, in-memory Reader/Writer exchanges and
temporary files. They exercise the production streaming callbacks and receive
commit code, including malformed responses, truncation, mutation, cancellation,
racing output destinations, bounded metadata and grant/control request shapes.
No test opens a socket. Live TLS/proxy/service deployment remains unverified.
