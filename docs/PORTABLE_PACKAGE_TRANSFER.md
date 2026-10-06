# Exact MoonBook package transfer through Town

This native miniapp service extension moves the original `.moonbook-agent`
bytes through Town's private store after an explicit decision to upload and a
separate decision to grant one recipient access. It uses existing Town account
sessions and entitlements. Source code and socket-free tests do not mean that a
live service has been deployed or that any real package has been shared.

## Sender

1. Accept the intended learning in the existing Book/Desk workflow. Explicitly
   select output files, then inspect the **entire** exported Book, including
   accepted learning and identity files. Output selection alone is not a privacy
   review. Reference-only outputs do not carry their bytes.
2. Use existing `moonbook agent pack`, `inspect`, `verify`, and `source`. Retain
   the exact original package and descriptor. Repacking changes its identity.
3. Save a Town agent listing with the descriptor using the existing authenticated
   listing route and retain its immutable `moontown.portable-listing-binding.v1`.
4. Explicitly upload that local file and expected binding. Only its owner can
   access stored bytes at this point. The returned byte receipt proves received
   raw SHA-256 and length; it does not claim semantic Book validation or rights.
5. Preview sharing with one known, active same-tenant principal and an expiry.
   The disclosure covers the **entire** package: learning, identity and included
   output bytes. Then explicitly submit a new exact-package grant ID. A preview
   never grants access. Existing card, message and collaborator grants never
   authorize bytes or preselect package recipients.

An unrecognized recipient must first obtain a normal active account/membership
through the existing account workflow. This feature does not create accounts,
credentials, cross-tenant membership, or a new subscription requirement.

## Recipient

1. Use your own Town session to list packages explicitly granted to you.
2. Select the exact package ID and saved v1 binding and choose a new local output
   filename. Download verifies response identity, raw length and SHA-256 before
   exposing the completed file. Its `.binding.json` and `.receipt.json` sidecars
   keep publisher-declared source identity and Town raw-byte verification separate.
3. Explicitly choose a new local Book directory and run the existing command:

   `moonbook agent import-exact RECEIVED_FILE NEW_BOOK RECEIVED_FILE.binding.json`

4. Run `moonbook agent verify-import RECEIVED_FILE NEW_BOOK`, then refresh normal
   Desk discovery. Exact import remains the authority for member bytes, source
   tuple, bundle digest and outputs manifest. A raw-byte receipt alone is not a
   semantic or safety approval of a Book or its outputs.

Download never installs a Book, executes an output, invokes hosted Try, or grants
collaborator/runtime authority. The original v1 binding remains unchanged,
including `reuse_mode=local_file_import`, `transport=local_file` and
`verification_scope=publisher_declared_expected_source`. The separate byte
receipt records `delivery_transport=authenticated_town_download`.

## Versions, retries and removal

- Package identity is a domain-separated hash of the immutable binding. A new
  Book/output version needs a new listing/package and a fresh grant. The old
  recipient continues to receive byte-identical v1, never a latest-version fallback
- An exact completed upload retry verifies its bytes again and retains the same
  receipt. Only the owner can repair a missing/corrupt object by reuploading that
  exact version. Failed repair does not erase an existing receipt or grants
- Revoke one package grant to deny future downloads under that grant. Metadata
  grants remain independent; revoke each kind whose access should end
- Withdraw a stored package to tombstone its byte availability and revoke all
  its package grants before cleanup. A pending cleanup is reported honestly and
  still consumes storage budget. Intentional withdrawal cannot be undone by
  reupload or listing restore; use a new listing/package/grant for a new decision
- Archiving the listing denies new uploads, grants and downloads. Ordinary restore
  preserves original unexpired grants; use revoke/withdraw for permanent cutoff
- Revocation applies at admission and the response-start recheck. An already
  started download may finish, and bytes already received cannot be recalled

## Bounds and deployment

Defaults are feature-local: 64 MiB raw package, 64 KiB chunks, 512 MiB retained
plus reserved bytes per publisher/tenant, 30-second idle timeout, five-minute
transfer deadline, and ten-minute recovery lease. A larger valid Book package
can still use the existing original-file plus v1-binding handoff. Book's existing
per-member selection limits are unchanged.

Normal JSON writes stay capped at 128 KiB. Only exact `PUT
/miniapp/marketplace/portable-packages/content` accepts the larger raw body.
The private index and client metadata responses are bounded separately at 8 MiB;
this lets listing and owner grant history grow beyond a single control request.
`deploy/Caddyfile.example` documents that narrow exception and disables encoding
for the exact binary response path. It must be deliberately applied and tested
in the deployment environment; source assertions do not prove live TLS/proxy
behavior.

The store is under the configured product state directory at
`marketplace/portable-packages`, outside static/UI/output roots. Include its
index **and** objects in backups. Private directories/files are created with
0700/0600 permissions; generated object IDs are internal, never bearer URLs or
caller-selected paths. There is no public/static route, range variant,
compression, redirect, cross-tenant deduplication, automatic age purge of valid
packages, or second hosting/provider stack.

## Real client and sessions

Use the dedicated native `cmd/portable_transfer` executable, not the existing
synthetic `miniapp dev-login` fixtures. It accepts an explicit `--session-stdin`
input ending at EOF. Reusable applications inject their own current-session
supplier. No token flag, secret environment lookup, credential generation, or
credential saving is part of this client. Supply only the established Town
origin; production sessions should use its existing HTTPS endpoint. The client
never follows redirects or forwards a session to another origin.

Commands are `upload`, `list`, `preview-share`, `share`, `revoke`, `download`, and
`withdraw`; invoking the executable without arguments prints usage. Inspect the
preview before explicitly running `share`. Metadata/status is printed to stdout;
package bytes and sessions are never printed.
Expiry is decimal Unix milliseconds in the CLI and a decimal string in JSON,
matching the existing UInt64 serialization.

Command form (the session is read from stdin through EOF, never included below):

```text
portable_transfer --base-url ORIGIN --session-stdin upload FILE LISTING_ID BINDING_JSON
portable_transfer --base-url ORIGIN --session-stdin list
portable_transfer --base-url ORIGIN --session-stdin preview-share PACKAGE_ID BINDING_JSON RECIPIENT_ID GRANT_ID EXPIRES_AT_MS
portable_transfer --base-url ORIGIN --session-stdin share PACKAGE_ID BINDING_JSON RECIPIENT_ID GRANT_ID EXPIRES_AT_MS
portable_transfer --base-url ORIGIN --session-stdin revoke GRANT_ID
portable_transfer --base-url ORIGIN --session-stdin download PACKAGE_ID BINDING_JSON NEW_OUTPUT_FILE
portable_transfer --base-url ORIGIN --session-stdin withdraw PACKAGE_ID BINDING_JSON
```

## Verification boundaries

The native tests call the actual production handler core with real authoritative
AccountApplication resolution, a real private temporary filesystem store, and
the client's injected streaming exchange. They do not start sockets/listeners,
use provider services, read actual credentials, or share/upload user data.
An opt-in retained synthetic 495,683-byte exported Book fixture covers exact
upload → explicit grant → recipient list/download → unchanged Book exact import
→ member verification → existing Desk discovery. Test reports separately state
which fixture and importer/discovery checks actually ran.

File locking coordinates cooperating writers of this new substore. It does not
claim cross-store serializable transactions, arbitrary power-loss guarantees,
or protection against a malicious process already running as the same OS user.
Live HTTPS deployment, actual user sessions and a new Bunnia UI remain separate
verification work.
