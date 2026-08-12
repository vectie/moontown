# System settings

MoonTown keeps adjustable operational policy in one typed registry instead of
scattering unexplained numbers across runtime and interface code. Platform
administrators can open **Admin → Settings** to review and change the registry.

The page groups settings by responsibility:

- **Runtime** — heartbeat, town task concurrency and execution freshness.
- **Automation** — standing-goal dispatch, research bootstrap and daemon
  timing.
- **Agents** — supervisor worker capacity and MoonClaw import timeout.
- **Accounts** — session capacity, expiry and audit retention.
- **Interface** — snapshot cadence, stale-state detection and bounded UI
  projections.
- **Service** — HTTP connection capacity.

Each setting publishes a label, explanation, unit, safe minimum and maximum,
and an apply mode. Apply modes distinguish changes that take effect immediately,
on the next town tick, after a page reload, or after a service restart. The
editor validates individual ranges and relationships before saving. The server
repeats those checks, rejects stale revisions, writes atomically, and records
the actor and changed keys in a bounded audit trail.

The durable state is stored at:

```text
$MOONSUITE_ROOT/.moonsuite/products/moontown/system-settings/state.json
```

The authenticated management endpoint is `GET/POST
/miniapp/system/settings`. It requires the `ManageSystemHealth` entitlement.
The desktop server exposes a read-only `/system-settings.json` projection so
the interface can consume the same values without exposing the management
operation.

## What belongs in the registry

The registry owns numbers an operator may safely tune: capacities, intervals,
timeouts, retention bounds, freshness windows and projection limits. New
operational policy must be added to the typed settings value, validation,
catalog and consumer together, with tests proving its default and effect.

Numbers that define a data format, cryptographic size, schema version, map
geometry or algorithmic invariant remain code constants. Making those editable
would let an administrator create incompatible data or violate correctness;
they should be changed through a versioned code migration instead of the
settings page.

## Recovery

If no settings file exists, MoonTown installs the documented defaults. If a
file exists but is invalid, startup or request handling fails visibly rather
than silently replacing operator intent. Repair the invalid value or restore a
known-good state file, then restart the affected service.
