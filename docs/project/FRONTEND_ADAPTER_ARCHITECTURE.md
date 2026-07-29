# Frontend Adapter Architecture

MoonTown has one product core and two frontend adapters. It does not have two
independent product backends.

```text
Rabbita / Lepusa desktop UI
  -> cmd/desktop_server (trusted localhost adapter)
     \
      -> town_application (shared use cases)
      -> MoonTown runtime, MoonBook, MoonClaw
      -> $MOONSUITE_ROOT/.moonsuite/products/moontown (durable truth)
     /
Bunnia / WeChat mini-app UI
  -> cmd/miniapp_server (session-scoped network adapter)
```

The adapters are separate processes because their transport and trust needs are
different:

- The desktop adapter serves static Rabbita assets, Energy Valley projections,
  local book output, and same-origin operator writes.
- The mini-app adapter serves a smaller phone-safe projection and requires a
  session token whenever it is exposed beyond localhost.

They share:

- `src/town_application`: durable operator use cases, including standing
  watches and evidence-book requests.
- `src/town_contract`: versioned capability and route discovery.
- `src/storage` and the MoonTown runtime: the canonical product state under
  `$MOONSUITE_ROOT/.moonsuite/products/moontown`.

The mini-app projection translates live MoonTown books into buildings, workers
into agents, and tasks/executions into runs. It deliberately excludes local
workspace paths, packet paths, skill paths, raw prompts, and other
operator-machine internals. Building placements are regenerated
deterministically from the canonical book order on the Energy Valley layer, so
layout is procedural without becoming a second durable map database.

## Ownership Rules

- A frontend owns presentation and local interaction state.
- An adapter owns HTTP, authentication, input limits, and audience-specific
  projection.
- `town_application` owns shared use-case behavior and durable writes.
- MoonTown/MoonBook ledgers own product truth.
- Bunnia may keep mock data for visual development, but its local fixture state
  must not be treated as production MoonTown state.

Adding another frontend should normally mean adding another thin adapter or
projection, not copying use-case logic or creating another database.

## Current Endpoint Surface

Desktop:

- `GET /api/contract`
- `POST /api/operator-requests`
- `POST /api/book-template-requests`
- existing Energy Valley and local runtime projection routes

Mini-app:

- `GET /miniapp/health`
- `GET /miniapp/contract`
- `GET /miniapp/town/snapshot`
- `POST /miniapp/research/watches`
- `POST /miniapp/research/evidence-books`

The current mini-app adapter covers live town observation and the two real
research request flows. Bunnia's broader social-product routes—ownership,
publishing, discovery, chat, moderation, and multi-user administration—remain
separate policy packages and local fixtures until each is connected to a
MoonTown application use case and durable product ledger. They must not be
advertised as live work merely because the fixture animates successfully.

## Running The Adapters

Desktop:

```bash
moon run src/cmd/desktop_server
```

Mini-app, localhost development:

```bash
moon run src/cmd/miniapp_server
```

Mini-app, non-loopback deployment:

```bash
export MOONTOWN_MINIAPP_BIND=0.0.0.0:18191
export MOONTOWN_MINIAPP_SESSION_TOKEN='replace-with-a-secret'
moon run src/cmd/miniapp_server
```

The process refuses a non-loopback bind without
`MOONTOWN_MINIAPP_SESSION_TOKEN`. TLS should terminate at a reverse proxy or
platform gateway; the adapter contract describes HTTPS as the production
transport.
