# MoonMold presentation ingestion

MoonTown consumes only portable `visual-styled-model` artifacts whose transform
is `styled-from` accepted engineering geometry. It preserves three identities:
the immutable MoonMold artifact, the durable MoonTown building, and an
independent placement. Moving or deleting a placement never mutates the
building or source artifact.

## Input, output, quality

Input is a serialized `moonmold-portable-ingestion-v1` envelope plus the
accepted engineering parent digest and explicit building/placement identities.
Output is `TownPresentationAsset` with spatial conventions, parent lineage,
declared losses, authority, payload, and separate civic identities.

Acceptance requires exact child identity/digest agreement, current engineering
parent, styled lineage, digital-only claim ceiling, MoonTown consumer
authorization, explicit losses/assumptions, and complete units/frame. Stale,
engineering, manufacturing, loss-stripped, physical-claim, and conflated-
identity inputs fail closed.

The test fixture is a byte-for-byte MoonMold portable export copied into this
repository. Runtime ingestion has no MoonMold sibling-source dependency.

