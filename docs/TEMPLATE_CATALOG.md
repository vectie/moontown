# MoonTown civic template catalog

MoonTown owns six `local-qualified` civic scenario envelopes in
`assets/templates/catalog.v1.json`:

- Policy triage desk
- Contest review council
- Consent-aware match market
- Town vitality signal watch
- AI learning cohort
- Evidence-backed story forge

Every envelope binds an existing source under `assets/templates/civic-patterns`
by SHA-256. It declares the civic synthesis operation, input/output schemas,
authority and effect ceiling, provider-dependent cost status, licensing class,
and named human review gate. The catalog does not include finance, AIGC, or
other packs' domain templates.

MoonDesk passes template ID/version, catalog ID/version/digest, and source
digest in the launch URL. MoonTown matches every pin against its installed
catalog before mapping the template to its own building and dashboard section
in `src/ui/rabbita-town/main/template_launch.mbt`. Unknown, partial, stale, or
mismatched identities are rejected visibly and cannot highlight a civic system.
The canonical Energy Valley seed remains `20260727`; the manifest uses the safe
path `/index.html`, while generic presentation metadata supplies the seed as a
strict launch query. Route validation is not relaxed.

Each envelope also declares an owner-reviewed migration policy, `/index.html`
preview, and a digest-bound retained qualification report. Preview selection
does not create `moonsuite.template-instance.v1` or start a civic workflow;
instance creation remains a later owner action and the current host CTA is
therefore **Review**, not **Start**.

MoonTown is also the sole writer for the exercised request and standing-watch
journey. Its versioned `moontown.api.v1` contract provides:

- `GET` and `POST /api/operator-requests`;
- `GET /api/standing-goals`.

An unavailable owner service is a visible blocked state, not permission for a
host application to recreate MoonTown's ledgers.
