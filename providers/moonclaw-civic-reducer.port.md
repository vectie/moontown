# MoonClaw civic reducer port

MoonTown does not implement an agent runtime. The production adapter invokes
the existing civic communication reducer through the installed MoonClaw
runtime.

The host must provide:

- a healthy MoonClaw installation and permitted model provider;
- a workspace-bound runner;
- durable proposal/run storage;
- the exact `CivicCommunicationIdea` output contract;
- no silent fixture fallback.

The pack's health attestation covers the MoonTown adapter and workspace seam.
Provider/model availability remains a separate host observation and can still
block an otherwise conformant operation.
