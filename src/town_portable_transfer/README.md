# Exact private package store

This native package owns only the dedicated private byte index, exact-byte
objects, reservations, receipts, and package grants. Its actor constructor takes
an authoritative account context. The HTTP coordinator remains responsible for
fresh session resolution, authoritative listing/archive checks and same-tenant
recipient resolution. Legacy listing/card grants are never consulted here.

The default limits are 64 MiB raw bytes, 64 KiB chunks, 512 MiB retained plus
reserved bytes per publisher/tenant, 30-second idle I/O, five-minute transfer,
and a ten-minute recovery lease. The strict JSON index is separately limited to
8 MiB and fails closed at capacity. Constructor overrides may lower the package
and chunk bounds; they cannot raise those hard bounds.

Quota accounting charges each retained indexed object's expected raw size and
each reservation's full expected size, including partial or failed cleanup.
This is conservative accounting for service-managed writes, not a filesystem
quota against external same-user mutation, hard links or other disk consumers.

Reservations are durable before temporary-file creation. Create-new temporary
files are 0600; newly created namespace directories are 0700. A process mutex
and scoped index file lock coordinate this store, while each active temporary
file holds its own lock. Recovery skips a locked attempt even past its lease.
Full-sync index-next writes and atomic rename provide restart recovery, without
a claim of universal power-loss durability or cross-store serializability.

Receipts attest only the original raw SHA-256 and length. Available bytes are
never modified in place. Downloads prehash with positional bounded reads and
stream the same descriptor. Failed repair retains previous receipts and grants;
failed unlink retains charged reservation/cleanup state. Withdrawal persists
denial and grant tombstones before cleanup and never permits revival.

Every managed path is generated internally. Existing symlink or nonregular
entries are rejected, and opened file kinds are checked. The installed async
filesystem API does not expose atomic no-follow/openat traversal: this assumes
the private namespace is controlled by the service and cooperating processes,
not a hostile process concurrently swapping paths under the same operating
system user. No new system permission changes or filesystem hardening API is
introduced.

Focused socket-free tests exercise real owned temporary files, streaming
Readers/Writers, active locks, cancellation, timeouts, strict corruption,
same-descriptor reads, quota, restart states, grant durability and withdrawal.
The package-private I/O checkpoints inject failures in the same production
create/write/sync/rename/index/unlink path; they do not simulate an actual full
filesystem, machine power loss, or a live multihost service.
