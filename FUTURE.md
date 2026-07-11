# MoonTown — A Futuristic Architecture Guide

This document captures the design philosophy, architectural principles, and
evolutionary path for MoonTown and its sibling systems (MoonBook, MoonClaw,
MoonDesk). It is not a specification. It is a **compass** — a shared
understanding of what we are building toward, so every small step moves in
the same direction.

---

## 1. The Core Loop

The system has exactly one fundamental loop:

```
for each book:
  read its policy → execute its skills → record results → evaluate health
```

A **policy** is just: *what skills does this book run, and what does "good"
look like?*

```moonbit
pub struct BookPolicy {
  skills : Array<SkillSpec>
  required_files : Array<FileSpec>
  quality_criteria : QualityCriteria
  output : OutputSpec
}
```

Everything else — the daemon, the catalog, the templates, the quality scores —
is support for this loop. The system does not need to know about
"research-book" or "toolbook" or "civic-protocol-support". It just needs to
know: *what skills does this book run, and what does good look like?*

Archetypes, capabilities, and surfaces are not separate dimensions. They are
**convenient groupings** of policy choices that tend to co-occur. The system
provides constructors like `research_policy()`, `with_pdf_watch()`,
`with_web_tool_surface()` — pure functions that compose policies.

---

## 2. Dual Lanes

The system has two fundamentally different kinds of work that cannot be merged
into one:

| | Lane 1: Execute | Lane 2: Tend |
|---|---|---|
| Question | Does this produce the result? | Is this the right way to produce the result? |
| Timescale | Every tick | Every N ticks (N >> 1) |
| Risk | Low — known procedure | High — might be worse |
| Feedback | Immediate (did it run?) | Delayed (did quality improve?) |
| Scope | Within a single book | Across books, across time |
| Agent | Watcher / Worker | Keeper / Philosopher |

**Lane 1** is the fast loop. It executes skills, checks sources, writes
findings, builds output. It is reliable, predictable, and efficient.

**Lane 2** is the slow loop. It reflects on what Lane 1 produced, notices
patterns, forms connections, proposes experiments, and tends to the book's
health over time. It is the part of the system that *improves the system
itself*.

Lane 2 cannot be reduced to Lane 1. You cannot optimize the philosophy from
inside the philosophy. You need a separate loop that treats the first loop as
its object of study. This is **double-loop learning**.

---

## 3. The Three Layers of Internal Distance

Every agent in the system must bridge three gaps to act effectively:

| Layer | Distance | Bridge |
|---|---|---|
| 1 — Information | Unknown → Known | Discovery, sensors, broadcast |
| 2 — Recognition | Known → Matters | Interpretation, relevance, connection |
| 3 — Decisiveness | Matters → Act | Confidence, urgency, safety |

Most systems only build bridges for Layer 1. They assume that if you *know*
something, you'll *recognize* its importance, and if you recognize it, you'll
*act*. But that is false at every step.

These three layers are the **growth vector** of the system. They are not a
third process. They are the competencies that make both lanes work better
over time. The archetype is the **fixed nature** — the soul given at birth.
The three layers are the **learned capacities** cultivated by the keeper
through experience.

---

## 4. The Six Conditions for Growth

The three layers are the *internal* distance an agent must bridge. The six
conditions are the *external* arrangements that make those bridges crossable:

```
Internal (what the agent must do)     External (what the environment provides)
──────────────────────────────────────────────────────────────────────────────

Layer 1: Information                  Receptors
  "I need to know what's out there."    Channels that bring signals in.
                                       Slack
                                         Room to receive without being
                                         overwhelmed.

Layer 2: Recognition                   Inspiration
  "I need to see why this matters."     Seeds from outside that crack open
                                        a new interpretation.
                                       Amplifiers
                                         Weak signals made visible so they
                                         can be recognized at all.

Layer 3: Decisiveness                  Encouragement
  "I need to actually act."             Safety to act without certainty.
                                       Slack
                                         Room to try without immediate
                                         consequence.
```

Slack appears twice because it is the most fundamental. Without slack,
receptors get clogged, inspiration has no room to land, and encouragement is
meaningless — there is no budget for anything but the known routine.

A keeper that has all six conditions will, over time, develop all three
competencies. A keeper that lacks any one condition will be stunted in the
corresponding layer — information-rich but blind, or perceptive but paralyzed,
or confident but isolated.

---

## 5. The Keeper's Processes

The keeper is the embodiment of Lane 2. It tends to a book over time through
a set of meta-cognitive processes, each running at a different rhythm:

| Process | Question | Rhythm | Artifact |
|---|---|---|---|
| Observe | What happened? | Every tick | Raw signal |
| Remember | What matters? | Every M ticks | MEMORY.md |
| Forget | What's obsolete? | Every M ticks | (deletion) |
| Reflect | What does it mean? | Every N ticks | Insight |
| Connect | Who else is relevant? | Every M ticks | Cross-book link |
| Imagine | What if we try X? | Every M ticks | Scenario |
| Question | What don't we know? | Every P ticks | Curiosity |
| Propose | Here's what to do. | On trigger | WORKING.md |
| Rest | Nothing needed now. | Default state | Silence |

Where N < M < P. The slower the rhythm, the more data the process has to
work with, and the more careful its output should be.

The existing keeper files map to some of these:

- `MEMORY.md` → Remember (durable compressed knowledge)
- `WORKING.md` → Attend (active context, proposals)
- `POLICY.md` → Evaluate (criteria for judgment)
- `USER.md` → Relate (who this serves)

**Connect**, **Imagine**, **Question**, **Propose**, and **Rest** do not have
files yet. They are the latent capacities waiting to be activated.

---

## 6. Emergence and Governance

The system has two phases that alternate, not as a schedule but as a natural
rhythm:

**Emergence phase** — Books act locally, explore, form connections, discover
things the center did not plan for. This phase cannot be scheduled. It can
only be *enabled* through slack, receptors, and amplifiers.

**Governance phase** — The daemon consolidates what emerged, ensures quality,
handles conflicts, and broadcasts what was learned. This phase is reliable,
predictable, and can be scheduled.

The semiconductor industry demonstrates this loop at scale:

```
Bell Labs discovers the transistor (emergence)
  → Intel makes it manufacturable (governance)
    → Fabless ecosystem emerges (emergence)
      → EUV lithography requires coordination (governance)
        → Chiplet architectures emerge (emergence)
```

Each governance phase *consolidates* what emergence discovered. Each emergence
phase *opens new possibilities* that governance could not have planned.

The current MoonTown has governance without emergence. The daemon tick is all
consolidation, no discovery. A healthy autonomous system needs both.

---

## 7. Stigmergy: Coordination Through Shared State

Agents in the system do not communicate directly. They communicate through
shared state — the catalog, the ledgers, the watcher records, the keeper
files. This is **stigmergy**: the same mechanism termites use to build mounds.

A termite does not tell another termite "build here." It drops a pheromone,
and the next termite reacts to the pheromone. The coordination is *mediated
by the environment*.

The catalog is a pheromone trail. A book writes its presence. Another book
reads the catalog and discovers a neighbor. A capability propagates not
because the daemon commanded it, but because one book's success left a trace
that another book followed.

Design implication: **Make shared state readable, writable, and queryable by
every agent.** Do not route communication through a central dispatcher. Let
agents find each other through the traces they leave.

---

## 8. The System Boundaries

```
MoonDesk ──compose──→ MoonBook ──holds──→ Knowledge
                           ↑                    ↑
                      MoonTown orchestrates   MoonClaw works
```

- **MoonClaw** is the worker. It executes tasks. It should have a specialized
  "watcher" mode that reads SKILL.md, follows structured output contracts,
  and reports structured results.

- **MoonBook** is the memory keeper and workspace holder. It should hold not
  just chapters but the book's policy, its skill definitions, its quality
  history, its keeper notes. Right now that data is scattered across
  MoonTown's JSON files.

- **MoonTown** is the orchestrator and communication bus. It should delegate
  memory to MoonBook, execution to MoonClaw, and composition to MoonDesk.
  The daemon tick should shrink from "do everything" to "handle escalations
  and persist commons."

- **MoonDesk** is the human interface. It should be the place where you
  compose books from archetypes and capabilities, inspect policy, submit
  tasks, and see the system's health at a glance.

---

## 9. Key Principles

1. **Push agency to the edges.** Each book should own its own tick, its own
   policy, its own quality evaluation. The daemon should handle exceptions,
   not direct traffic.

2. **One representation.** Policy should be expressed in one place, in one
   type, not scattered across templates, quality heuristics, bootstrap
   functions, and installer branches.

3. **Slow before fast.** Build Lane 2 (the keeper) before optimizing Lane 1.
   A system that runs faster but doesn't learn is just a faster factory.

4. **Compose, don't enumerate.** Archetypes, capabilities, and surfaces are
   composable building blocks. Do not hardcode every combination as a
   separate template.

5. **Design for surprise.** Build receptors for weak signals. Build amplifiers
   for novel patterns. Build slack for unplanned exploration. The system
   should be *expecting* to be surprised.

6. **Satisficing over optimizing.** In complex environments, you do not
   optimize. You look for "good enough" and move on. The quality thresholds
   are not targets — they are satisficing bounds.

7. **Forget aggressively.** Memory that never dies becomes noise. The keeper
   should spend as much energy forgetting as remembering.

8. **Rest is productive.** The default state of the keeper should be silence.
   Action should be the exception, not the rule. A keeper that never rests
   becomes noise.

---

## 10. The Path Forward (Bottom-Up)

Do not rewrite. The system is already alive. Tend it plant by plant.

1. **Activate the keeper.** Give it an agent loop that runs on a slow cadence,
   reads the keeper files, and writes observations back. No MoonTown changes
   needed. Just a new skill that any book can opt into.

2. **Extract BookPolicy.** Once the keeper needs to read the book's policy
   to do its job, the policy struct becomes natural. Extract it from the
   template system, don't design it in isolation.

3. **Compose archetypes and capabilities.** Replace the flat template
   registry with composable policy constructors. Each template becomes a
   function, not a JSON entry.

4. **Shrink the daemon.** Move quality evaluation to the keeper. Move
   skill execution to the watcher. The daemon becomes an exception handler
   and state persister.

5. **Build the MoonDesk policy composer.** Let humans compose books from
   archetypes and capabilities through the UI. This is the last step, not
   the first.

Each step is independently useful. Each step is safe — you can roll it back.
Each step moves toward the vision without requiring the vision to be complete
first.

---

## 11. The Bet

The entire architecture is a bet on **emergence** — the idea that global
behavior worth having can arise from local interactions, without central
design.

This is not a passive bet. You cannot build a centralized scheduler, call it
a town, and hope emergence happens. You must actively design for it:

- Push agency to the edges
- Make books self-owning
- Let the daemon shrink
- Let the town be the *result* of book behavior, not the *cause* of it

And then you wait. And watch. And maybe something surprising happens.

The alternative is a centralized system that gets more brittle as it grows,
and we already know how that story ends.

---

*Started 2026-06-09. Will be wrong in places. That is the point.*
