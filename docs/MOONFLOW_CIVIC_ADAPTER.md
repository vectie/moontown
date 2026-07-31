# MoonFlow civic synthesis adapter

MoonTown publishes one executable cross-product operation:

```text
moontown/civic.communication.synthesize@0.1.0
```

`research-salon` is a `communication_pattern_id` inside the input scenario. It
is not an operation name. A canvas node such as `civic.research-salon` is
therefore non-conformant and must be replaced by the manifest-derived
operation.

## Capability truth

| Contract | Identity |
| --- | --- |
| Pack | `pack.json`, `moontown@0.1.0` |
| Tool | `civic.communication.synthesize` |
| Input | `moontown/civic-communication-handoff@1.0.0` |
| Output | `moontown/civic-synthesis-result@1.0.0` |
| Authority | `workspace-mutation` |
| Claim ceiling | `execution-result` |
| Adapter protocol | `moonflow.adapter.v2` |
| Reconciliation | required |
| Human review | required |

The product-owned manifest declares semantics and schemas. The host-owned
[`adapter-declaration.v1.json`](../adapters/moonflow/adapter-declaration.v1.json)
binds the installed pack to the executable adapter. A short-lived health
attestation is generated at the installation; health is never claimed by the
static manifest.

## Commands

```sh
moon run src/cmd/moonflow_adapter -- capability

moon run src/cmd/moonflow_adapter -- health \
  --workspace /path/to/workspace \
  --checked-at 2026-07-31T00:00:00Z \
  --valid-until 2026-07-31T01:00:00Z \
  --evidence health/moontown-civic-synthesis-v1.json \
  --attestation health/moontown-civic-synthesis-v1.attestation.json

moon run src/cmd/moonflow_adapter -- execute \
  --workspace /path/to/workspace \
  --request .moonsuite/products/moonflow/runs/RUN/dispatch/REQUEST.request.json \
  --result .moonsuite/products/moonflow/runs/RUN/dispatch/RESULT.result.json

moon run src/cmd/moonflow_adapter -- reconcile \
  --workspace /path/to/workspace \
  --request .moonsuite/products/moonflow/runs/RUN/dispatch/REQUEST.request.json \
  --result .moonsuite/products/moonflow/runs/RUN/dispatch/RESULT.result.json
```

Execution verifies MoonFlow's declared input digest, consumes a typed civic
handoff, and calls the existing civic runtime with the existing MoonClaw
reducer. It writes an immutable adapter result plus a native execution receipt
and evidence-bound synthesis result.

Reconciliation never invokes MoonClaw. It validates an existing result or
reconstructs it from the durable native receipt. When neither exists, it
reports an unknown outcome and forbids automatic retry.

## Acceptance boundary

A succeeded adapter result means execution produced a reviewable,
evidence-bound artifact. Its result always records `accepted: false`, uses the
`execution-result` claim ceiling, and leaves completed synthesis at
`review_status: pending`.

MoonFlow owns durable attempt reconciliation. A named reviewer and MoonBook own
acceptance. MoonTown cannot use its adapter, health attestation or native
receipt to accept its own synthesis.
