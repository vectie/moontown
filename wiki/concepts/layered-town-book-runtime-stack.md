# Layered town-book-runtime stack

## Definition

The layered town-book-runtime stack is the architectural split where:

- `moontown` owns town-wide orchestration and visibility
- `moonbook` owns per-domain harness and durable domain memory policy
- `moonclaw` owns role-specialized runtime behavior and execution-oriented agent surfaces

This concept is evidenced in both docs and code-visible role metadata, and it is narrower than any claim about all behavior inside the adjacent repositories.

## Why the split matters

The repo repeatedly distinguishes three scopes of responsibility:

- town-wide control and persistence should remain in `moontown` (`docs/ARCHITECTURE.md:15`)
- domain-specific durable memory and review belong in `moonbook` (`docs/ARCHITECTURE.md:35`)
- task/session execution surfaces belong in `moonclaw` (`docs/ARCHITECTURE.md:52`)

That separation prevents this repo from collapsing control-plane, domain-memory, and executor concerns into one layer.

## Operational shape in this repo

The split appears operationally through a packet-first handoff chain:

- MoonBook adapter code provides catalog, goal, task-batch, context, persistence, summary, and health surfaces (`adapters/moonbook/client.mbt:425`)
- Mayor code turns hydrated book work into keeper-facing packets (`roles/mayor.mbt:93`)
- MoonClaw adapter code defines planner and executor runtime profiles and imports packets into proposal/run lifecycle handling (`adapters/moonclaw/client.mbt:584`, `adapters/moonclaw/client.mbt:311`)

## Negative boundary

This concept should not be stretched into claims that are not directly supported here, including:

- exact provider-target failure diagnosis
- MoonBook internal keeper implementation details beyond the boundary named in this repo
- MoonClaw internal persistence or execution-log ownership beyond proposal import, run invocation, and polling seams

## Related pages

- [Moontown-MoonBook-MoonClaw stack](../sources/moontown-moonbook-moonclaw-stack.md)
- [Evidence notes](../synthesis/evidence.md)
