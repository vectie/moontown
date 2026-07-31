# Civic synthesis authority

`moontown/civic.communication.synthesize@0.1.0` requires
`workspace-mutation`. It may create or update MoonTown and MoonBook artifacts
inside the supplied workspace.

Its claim ceiling is `execution-result`. A successful adapter result means the
declared civic procedure produced a reviewable result and bound evidence. It
does not mean that MoonTown accepted the result as book truth.

The adapter cannot request external-effect or physical-effect authority,
publish externally, accept a MoonBook claim, or elevate a review candidate.
MoonFlow reconciliation moves successful execution into review.
