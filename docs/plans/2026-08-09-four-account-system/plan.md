# Four-account system implementation

## Problem

MoonTown has user, session, organization, workspace, and permission primitives,
but production request authentication, marketplace principals, subscription
tiers, and the Rabbita UI are not yet one coherent account system. The product
needs four clearly different experiences: visitor, paid member, enterprise,
and administrator.

## Product decision

Expose four experiences while keeping billing and authority orthogonal:

- `Visitor`, `Paid`, and `Enterprise` are plans.
- member/editor/publisher/organization-admin/platform-admin are scoped roles.
- an administrator is never inferred from payment.
- the server derives identity from an opaque session; request bodies and user
  headers cannot select the acting principal.
- UI visibility follows server entitlements but never replaces authorization.

## Scope

| Area | Change |
| --- | --- |
| `src/account_system` | Own plans, scoped roles, entitlements, account context, account home surface, session registry, tenant switching, and JSON projections. |
| `src/cmd/miniapp_server` | Resolve one account context from opaque sessions, expose visitor-session, `/me`, tenant-switch, and guarded admin endpoints, and retire caller-selected user identity. |
| `src/miniapp_contracts` | Publish account endpoint contracts. |
| `src/ui/rabbita-town/main` | Add a stable account banner/navigation layer and select visitor, paid, enterprise, or admin experience from trusted bootstrap account context. |
| tests | Cover entitlement boundaries, opaque-session resolution, tenant switching, admin denial, UI account-view selection, and safe fallback. |

## Implementation steps

1. Add the account domain package with fixtures for all four experiences.
2. Add a durable-compatible session registry whose stored records contain token
   digests, expiry, revocation state, plan, roles, and tenant memberships.
3. Add a server adapter that provisions the configured operator, optionally
   loads account state, creates bounded visitor sessions, and derives every
   protected request context from `x-miniapp-session`.
4. Add account routes: visitor session, `/miniapp/me`, tenant switch, enterprise
   member summary, and admin summary.
5. Route supervisor operations with the session-derived user id and protect
   runtime/operator administration with explicit entitlements.
6. Add account-aware UI navigation and distinct home summaries while preserving
   the spatial Wenyu town as the primary visitor/member surface and the quiet
   operations console as the administrator surface.
7. Run targeted tests, full `moon check`/`moon test`, then `moon info && moon fmt`.
8. Render and inspect visitor, paid, enterprise, and admin states at phone and
   desktop widths.

## Acceptance criteria

- Visitor sessions can read public account/town context but cannot run personal,
  enterprise, or administrative mutations.
- Paid members receive personal-agent/workspace/marketplace entitlements without
  enterprise administration.
- Enterprise capabilities require an active enterprise tenant membership.
- Organization-admin and platform-admin authority are explicit and scoped.
- No production operation derives its actor from `x-miniapp-user-id`.
- `/miniapp/me` returns the server-derived plan, tenant, roles, entitlements,
  allowed tenant choices, and home surface.
- Tenant switching rejects tenants outside the session principal's membership.
- Admin endpoints reject non-admin sessions even when the client displays or
  submits admin-shaped data.
- The UI provides four distinct, accessible experiences without forking the
  entire application or mixing operational controls into the public town.

## Verification

```text
moon check --warn-list +73
moon test src/account_system
moon test src/cmd/miniapp_server
moon -C src/ui/rabbita-town test main/account_experience_wbtest.mbt --target js
moon -C src/ui/rabbita-town check --target js
moon -C src/ui/rabbita-town build --target js --release
moon test
moon info
moon fmt
```

## Document protocol fit

This plan owns the account-system change. Durable identity and authorization
remain server/account-package concerns; marketplace, town projections, and UI
consume the resulting principal context rather than inventing identity. Test
receipts and generated interfaces are the restart and review evidence.
