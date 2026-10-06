# Explicit Wenyu already-satisfied completion

New native goal launches remain mutation-required by default. To deliberately
permit an honest already-satisfied result for a new Wenyu code-patch request:

```text
moontown run --wenyu-allow-no-change --book <wenyu-book-id> <goal>
```

The option requires native execution. It is incompatible with explicit ACP.
Programmatic callers can use `wenyu_allow_no_change=true` on `run_goal` or
`render_goal_run`, or `allow_no_change=true` on `freeze_wenyu_launch`.
Existing callers and the original four-value argument parser retain their
contracts; the CLI uses the additive `parse_options` parser.

This permission is frozen into that new request. A saved launch, reserved
command, retry or restart keeps its exact original policy, model and command
bytes. Repeating an old task with the flag does not upgrade it. An operator must
explicitly supersede old work before creating a new generation with permission.
Unsupported extension kinds do not gain no-change permission.

## Evidence and result

The existing six Wenyu validation commands are unchanged: formatting, interface
generation, source checks, the scoped pipeline/runtime/Town tests, the required
Town UI release build, and the whitespace diff check. The opt-in policy derives
its exact checks from that same command list. Every command remains required.

Only the original `implementation` milestone can resolve as `already_satisfied`.
All other original milestones and typed evidence requirements still apply.
The accepted checkpoint and finish must contain the same structured no-change
proposal, with source evidence, a nonempty observation and all required check
references. Checks must be fresh after the final source change or failed tool.
Formatting and interface generation may mutate source and require rerunning
checks. A fabricated edit must never be used to manufacture success.

A verified no-change result has matching source-inventory digest, root, HEAD
and index observations and no changed source files. It may include ignored build
artifacts or an attested edit-and-restore history. It means **no net source
change**, not that nothing anywhere on disk was ever written.

MoonTown writes a **Wenyu Code Validation** report at the existing
`build/CODE_PATCH.md` destination, the real `build/TEST_RESULTS.md` file, and an
immutable output package. The result stays engineering-only: original-task
acceptance is unevaluated, Book evidence/review remains pending, and the event
has `accepted=false`. No goal, backlog criterion or selected feature is accepted
automatically. An older unrelated blockers file is preserved.

Existing mutation and failure output-package bytes remain replay-compatible.
Failed, cancelled and superseded work cannot become no-change success. Human
edits, newer Book results and later review decisions remain protected on replay.
