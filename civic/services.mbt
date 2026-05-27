///|
pub struct CivicServiceDefinition {
  id : String
  title : String
  book_id : String
  service_kind : String
  module_mode : String
  book_role : String
  skill_mode : String
  purpose : String
  workflow : Array[String]
  agent_work : Array[String]
  place_work : Array[String]
  schema_pages : Array[String]
  wiki_pages : Array[String]
  review_queues : Array[String]
  skill_pack : String
  skill_path : String
  output_contract : String
  worker_role : @core.WorkerRole
  target_pages : Array[String]
  acceptance : Array[String]
  projection_summary : String
  legacy_book_ids : Array[String]
} derive(Show, Eq)

///|
pub fn wenyu_civic_services() -> Array[CivicServiceDefinition] {
  [
    civic_service(
      id="town-shell",
      title="Town Shell",
      service_kind="town-supervision",
      module_mode="projection-surface",
      book_role="town-journal",
      skill_mode="mayor-supervision",
      purpose="Live valley map, mayor supervision, town projection, operator console, and 24x7 service visibility.",
      workflow=[
        "read the latest town snapshot and daemon status", "detect stalled modules, missing projections, and stale workers",
        "publish a projection-safe mayor digest with recovery actions",
      ],
      agent_work=[
        "diagnose stalled modules and stale workers", "write mayor recovery directives",
        "publish an operator-safe town digest",
      ],
      place_work=[
        "show whole-town state", "route operator commands", "link into module interiors",
      ],
      schema_pages=[
        "wiki/schemas/town-runtime.md", "wiki/schemas/module-registry.md",
      ],
      wiki_pages=[
        "wiki/civic/town-shell.md", "wiki/synthesis/town-runtime.md", "wiki/history/mayor-journal.md",
      ],
      review_queues=["wiki/reviews/town-operations.md"],
      skill_pack="civic-town-supervisor",
      output_contract="wenyu.civic.town_supervision.v1",
      worker_role=@core.WorkerRole::Operator,
      acceptance=[
        "detects module/workspace/projection gaps", "writes a mayor digest", "updates the visible town projection without exposing private book memory",
      ],
      projection_summary="Mayor-controlled shell for module health, worker activity, projection freshness, and civic service readiness.",
    ),
    civic_service(
      id="resident-twins",
      title="Resident Twin Homes",
      service_kind="resident-memory",
      module_mode="hybrid",
      book_role="private-memory-with-projection",
      skill_mode="resident-memory-keeping",
      purpose="Projection-safe resident profiles, preferences, needs, reflection summaries, and daily autonomous routines.",
      workflow=[
        "ingest resident-safe updates and explicit preferences", "separate private memory from public projection",
        "propose next helpful actions without leaking sensitive data",
      ],
      agent_work=[
        "promote explicit resident preferences into private memory", "draft projection-safe resident summaries",
        "queue sensitive changes for review",
      ],
      place_work=[
        "host resident-facing presence", "hide private memory from public town views",
        "surface only consented projection cards",
      ],
      schema_pages=[
        "wiki/schemas/resident-profile.md", "wiki/schemas/privacy-projection.md",
      ],
      wiki_pages=[
        "wiki/civic/resident-twins.md", "wiki/entities/residents.md", "wiki/concepts/privacy-boundaries.md",
      ],
      review_queues=["wiki/reviews/resident-memory.md"],
      skill_pack="civic-resident-keeper",
      output_contract="wenyu.civic.resident_memory.v1",
      worker_role=@core.WorkerRole::MemoryKeeper,
      acceptance=[
        "keeps private and projection-safe fields separate", "records resident next-action candidates",
        "queues review for sensitive profile changes",
      ],
      projection_summary="Resident memory lane for personal context, projection safety, and everyday town participation.",
    ),
    civic_service(
      id="policy-hall",
      title="Policy Hall",
      service_kind="policy-service",
      module_mode="agent-workspace",
      book_role="source-backed-service-workspace",
      skill_mode="policy-intelligence",
      purpose="Policy discovery, eligibility interpretation, cited civic answers, application checklists, and review-gated guidance.",
      workflow=[
        "search official policy sources before summaries", "extract eligibility, deadlines, documents, and responsible offices",
        "draft a cited checklist and queue uncertainty for review",
      ],
      agent_work=[
        "discover official policy updates", "extract eligibility and deadline facts",
        "draft cited checklists with uncertainty notes",
      ],
      place_work=[
        "receive resident policy questions", "display reviewed checklists", "route application-advice requests to review",
      ],
      schema_pages=[
        "wiki/schemas/policy-source.md", "wiki/schemas/eligibility-check.md",
      ],
      wiki_pages=[
        "wiki/civic/policy-hall.md", "wiki/sources/policies.md", "wiki/concepts/eligibility.md",
        "wiki/queries/policy-questions.md",
      ],
      review_queues=["wiki/reviews/policy-citations.md"],
      skill_pack="civic-policy-researcher",
      output_contract="wenyu.civic.policy_service.v1",
      worker_role=@core.WorkerRole::Specialist,
      acceptance=[
        "uses official or clearly labeled secondary sources", "separates cited facts from interpretation",
        "requires review before user-facing application advice",
      ],
      projection_summary="Policy quest desk for source-backed eligibility checks, checklists, and reviewable civic answers.",
    ),
    civic_service(
      id="contest-express",
      title="Contest Express",
      service_kind="contest-service",
      module_mode="agent-workspace",
      book_role="coaching-workspace",
      skill_mode="contest-coaching",
      purpose="Contest calendars, readiness scoring, submission checklists, team preparation, mock judge feedback, and champion-wall stories.",
      workflow=[
        "discover relevant contests and deadlines", "score readiness against explicit criteria",
        "produce a revision plan and mock-judge review packet",
      ],
      agent_work=[
        "track contest deadlines and requirements", "score team readiness", "produce mock-judge feedback and revision plans",
      ],
      place_work=[
        "show contest calendar", "collect team submissions", "display reviewed champion-wall stories",
      ],
      schema_pages=[
        "wiki/schemas/contest.md", "wiki/schemas/readiness-score.md",
      ],
      wiki_pages=[
        "wiki/civic/contest-express.md", "wiki/sources/contests.md", "wiki/entities/teams.md",
        "wiki/queries/contest-readiness.md",
      ],
      review_queues=["wiki/reviews/contest-submissions.md"],
      skill_pack="civic-contest-coach",
      output_contract="wenyu.civic.contest_service.v1",
      worker_role=@core.WorkerRole::Planner,
      acceptance=[
        "tracks deadline and submission state", "produces actionable readiness gaps",
        "does not submit externally without operator confirmation",
      ],
      projection_summary="Competition service lane for calendars, readiness, mock review, and next preparation actions.",
    ),
    civic_service(
      id="social-square",
      title="Social Square",
      service_kind="social-matching",
      module_mode="exchange-place",
      book_role="consent-ledger-and-social-graph",
      skill_mode="consent-aware-matchmaking",
      purpose="Community feed, consent-aware weak-tie introductions, event plans, RSVP reminders, and follow-up memory.",
      workflow=[
        "identify match hypotheses from explicit interests and needs", "explain why the introduction is useful and low-risk",
        "draft a consent-gated introduction and follow-up plan",
      ],
      agent_work=[
        "infer low-risk match hypotheses from explicit interests", "draft consent-gated introductions",
        "record follow-up outcomes after interaction",
      ],
      place_work=[
        "host agent/resident exchange", "collect consent state", "surface public event and RSVP activity",
      ],
      schema_pages=[
        "wiki/schemas/social-match.md", "wiki/schemas/event-plan.md",
      ],
      wiki_pages=[
        "wiki/civic/social-square.md", "wiki/entities/social-graph.md", "wiki/concepts/weak-ties.md",
        "wiki/queries/community-requests.md",
      ],
      review_queues=["wiki/reviews/social-introductions.md"],
      skill_pack="civic-social-matchmaker",
      output_contract="wenyu.civic.social_matching.v1",
      worker_role=@core.WorkerRole::Specialist,
      acceptance=[
        "requires consent before external introductions", "explains match rationale and uncertainty",
        "records follow-up outcomes in MoonBook",
      ],
      projection_summary="Community matching square for reasoned introductions, event loops, and reviewable follow-ups.",
    ),
    civic_service(
      id="talent-avenue",
      title="Talent Avenue",
      service_kind="talent-graph",
      module_mode="hybrid",
      book_role="talent-graph-workspace",
      skill_mode="talent-curation",
      purpose="Talent cards, skill graph curation, project matching, mentor routes, VIP reception paths, and portfolio surfaces.",
      workflow=[
        "normalize talent evidence into skills, projects, needs, and availability",
        "build match candidates with explicit evidence", "prepare a reception or project-match route for operator review",
      ],
      agent_work=[
        "verify talent claims and project evidence", "maintain skill graph edges",
        "draft mentor or project-match routes",
      ],
      place_work=[
        "display public talent cards", "host project matching requests", "support VIP/reception journeys",
      ],
      schema_pages=["wiki/schemas/talent-card.md", "wiki/schemas/skill-edge.md"],
      wiki_pages=[
        "wiki/civic/talent-avenue.md", "wiki/entities/talent-graph.md", "wiki/entities/projects.md",
        "wiki/queries/talent-matches.md",
      ],
      review_queues=["wiki/reviews/talent-claims.md"],
      skill_pack="civic-talent-curator",
      output_contract="wenyu.civic.talent_graph.v1",
      worker_role=@core.WorkerRole::Specialist,
      acceptance=[
        "distinguishes verified achievements from self-claims", "links every match to evidence",
        "keeps reception notes projection-safe",
      ],
      projection_summary="Talent graph lane for skills, portfolios, mentor links, and evidence-backed project matching.",
    ),
    civic_service(
      id="vitality-dashboard",
      title="Vitality Tower",
      service_kind="vitality-analytics",
      module_mode="projection-surface",
      book_role="operational-health-journal",
      skill_mode="observability-and-accounting",
      purpose="Town health metrics, resource budgets, service response, points flow, retention signals, alerts, and recovery loops.",
      workflow=[
        "read daemon, watcher, worker, and projection ledgers", "separate operational activity from real domain updates",
        "publish a service-health digest and recovery queue",
      ],
      agent_work=[
        "audit daemon/watch/service records", "separate operational events from domain progress",
        "draft recovery queue items for stale modules",
      ],
      place_work=[
        "display town vitality metrics", "surface warnings and freshness", "explain what changed versus what merely ran",
      ],
      schema_pages=[
        "wiki/schemas/vitality-metric.md", "wiki/schemas/service-alert.md",
      ],
      wiki_pages=[
        "wiki/civic/vitality-dashboard.md", "wiki/synthesis/health.md", "wiki/history/daemon-digest.md",
      ],
      review_queues=["wiki/reviews/service-alerts.md"],
      skill_pack="civic-vitality-analyst",
      output_contract="wenyu.civic.vitality_analytics.v1",
      worker_role=@core.WorkerRole::Watcher,
      acceptance=[
        "does not count operational retries as domain progress", "publishes stale-worker and stale-book alerts",
        "summarizes what changed and what did not change",
      ],
      projection_summary="Health and vitality lane for real-time town metrics, recovery signals, and domain-change accounting.",
    ),
    civic_service(
      id="ai-garden",
      title="AI Science Garden",
      service_kind="education-service",
      module_mode="agent-workspace",
      book_role="learning-content-workspace",
      skill_mode="ai-tutoring",
      purpose="AI literacy tutorials, tool trials, scenario templates, learning quests, before/after examples, and safe experiments.",
      workflow=[
        "choose an educational scenario based on current resident needs", "create a small tutorial with examples and safety notes",
        "record before/after learning evidence and next practice",
      ],
      agent_work=[
        "design learning quests", "write novice-safe examples", "record before/after practice evidence",
      ],
      place_work=[
        "show learning quests", "host tool-trial demos", "collect learner feedback for review",
      ],
      schema_pages=[
        "wiki/schemas/learning-quest.md", "wiki/schemas/tool-trial.md",
      ],
      wiki_pages=[
        "wiki/civic/ai-garden.md", "wiki/concepts/ai-literacy.md", "wiki/queries/learning-quests.md",
      ],
      review_queues=["wiki/reviews/education-content.md"],
      skill_pack="civic-ai-tutor",
      output_contract="wenyu.civic.education_service.v1",
      worker_role=@core.WorkerRole::Specialist,
      acceptance=[
        "writes novice-safe tutorials", "shows concrete before/after examples", "queues unsafe or uncertain advice for review",
      ],
      projection_summary="Education garden for AI tutorials, tool trials, scenario quests, and reviewed learning artifacts.",
    ),
    civic_service(
      id="physical-bridge",
      title="Physical Bridge",
      service_kind="physical-bridge",
      module_mode="gateway",
      book_role="offline-handoff-ledger",
      skill_mode="confirmation-gated-handoff",
      purpose="Virtual-to-real venue, robot, QR, display, room booking, and offline handoff workflows with confirmation gates.",
      workflow=[
        "draft the offline request and required confirmation", "verify venue, robot, or display constraints",
        "write a handoff packet without finalizing external action automatically",
      ],
      agent_work=[
        "draft offline handoff packets", "check venue or robot constraints", "queue confirmation-gated actions",
      ],
      place_work=[
        "act as virtual-to-real gateway", "show confirmation state", "prevent unapproved external actions",
      ],
      schema_pages=[
        "wiki/schemas/physical-request.md", "wiki/schemas/handoff-confirmation.md",
      ],
      wiki_pages=[
        "wiki/civic/physical-bridge.md", "wiki/entities/venues.md", "wiki/entities/robots.md",
        "wiki/queries/offline-service.md",
      ],
      review_queues=["wiki/reviews/physical-handoffs.md"],
      skill_pack="civic-bridge-operator",
      output_contract="wenyu.civic.physical_bridge.v1",
      worker_role=@core.WorkerRole::Operator,
      acceptance=[
        "never finalizes bookings or robot actions without approval", "records offline constraints and confirmation status",
        "publishes only projection-safe telemetry",
      ],
      projection_summary="Virtual-physical connector for venue, robot, display, and offline-service handoff packets.",
    ),
    civic_service(
      id="valley-market",
      title="Valley Market",
      service_kind="market-service",
      module_mode="exchange-place",
      book_role="points-ledger-and-review-log",
      skill_mode="market-ledger-keeping",
      purpose="Valley points, benefit redemption, local opportunity exchange, lightweight reward loops, and anti-abuse review.",
      workflow=[
        "record reward or redemption candidates", "check policy, evidence, abuse risk, and budget limits",
        "write a ledger update proposal for operator review",
      ],
      agent_work=[
        "draft reward or redemption proposals", "check budget and abuse risk", "maintain reviewed points-ledger entries",
      ],
      place_work=[
        "host exchange requests", "show point/reward flow", "route redemption actions to review",
      ],
      schema_pages=[
        "wiki/schemas/points-ledger.md", "wiki/schemas/reward-offer.md",
      ],
      wiki_pages=[
        "wiki/civic/valley-market.md", "wiki/entities/rewards.md", "wiki/synthesis/points-ledger.md",
        "wiki/queries/market-requests.md",
      ],
      review_queues=["wiki/reviews/market-ledger.md"],
      skill_pack="civic-market-keeper",
      output_contract="wenyu.civic.market_service.v1",
      worker_role=@core.WorkerRole::MemoryKeeper,
      acceptance=[
        "keeps a reviewable points ledger", "marks anti-abuse and budget risks",
        "does not execute financial or redemption actions automatically",
      ],
      projection_summary="Market lane for valley points, rewards, redemption proposals, and reviewable benefit flows.",
    ),
    civic_service(
      id="broadcast-tower",
      title="Story Radar",
      service_kind="story-service",
      module_mode="hybrid",
      book_role="story-draft-and-redaction-workspace",
      skill_mode="public-story-editing",
      purpose="Public-safe town moments, achievement stories, resident/company highlights, privacy redaction, and operator-reviewed broadcasts.",
      workflow=[
        "detect story-worthy changes from reviewed book updates", "redact private or uncertain details",
        "draft a story with evidence links and publication approval state",
      ],
      agent_work=[
        "detect story-worthy reviewed changes", "redact private or uncertain details",
        "draft publication-ready stories for approval",
      ],
      place_work=[
        "display approved public stories", "show broadcast review state", "avoid leaking private book memory",
      ],
      schema_pages=[
        "wiki/schemas/story-draft.md", "wiki/schemas/redaction-check.md",
      ],
      wiki_pages=[
        "wiki/civic/broadcast-tower.md", "wiki/synthesis/story-radar.md", "wiki/queries/public-stories.md",
      ],
      review_queues=["wiki/reviews/broadcast-drafts.md"],
      skill_pack="civic-story-editor",
      output_contract="wenyu.civic.story_service.v1",
      worker_role=@core.WorkerRole::Reviewer,
      acceptance=[
        "redacts private or unverified information", "links every public claim to reviewed evidence",
        "requires operator approval before publication",
      ],
      projection_summary="Story radar for public-safe highlights, achievement narratives, and reviewed broadcast drafts.",
    ),
  ]
}

///|
fn civic_service(
  id~ : String,
  title~ : String,
  service_kind~ : String,
  module_mode~ : String,
  book_role~ : String,
  skill_mode~ : String,
  purpose~ : String,
  workflow~ : Array[String],
  agent_work~ : Array[String],
  place_work~ : Array[String],
  schema_pages~ : Array[String],
  wiki_pages~ : Array[String],
  review_queues~ : Array[String],
  skill_pack~ : String,
  output_contract~ : String,
  worker_role~ : @core.WorkerRole,
  acceptance~ : Array[String],
  projection_summary~ : String,
) -> CivicServiceDefinition {
  let book_id = "wenyu-\{id}"
  {
    id,
    title,
    book_id,
    service_kind,
    module_mode,
    book_role,
    skill_mode,
    purpose,
    workflow,
    agent_work,
    place_work,
    schema_pages,
    wiki_pages,
    review_queues,
    skill_pack,
    skill_path: "skills/\{skill_pack}/SKILL.md",
    output_contract,
    worker_role,
    target_pages: unique_strings(
      [
        "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md",
        "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
        "skills/wenyu-civic-service/SKILL.md",
        "skills/\{skill_pack}/SKILL.md",
        ..schema_pages,
        ..wiki_pages,
        ..review_queues,
        "book/moonbook-ui-state.json",
        "book/site/generated/index.html",
      ],
    ),
    acceptance,
    projection_summary,
    legacy_book_ids: if id == "town-shell" ||
      id == "resident-twins" ||
      id == "contest-express" ||
      id == "physical-bridge" {
      []
    } else {
      [id]
    },
  }
}

///|
pub fn wenyu_civic_service_for_module_id(
  module_id : String,
) -> CivicServiceDefinition? {
  let key = civic_binding_key(module_id)
  for service in wenyu_civic_services() {
    if civic_binding_key(service.id) == key {
      return Some(service)
    }
  }
  None
}

///|
pub fn wenyu_civic_service_for_book_id(
  book_id : String,
) -> CivicServiceDefinition? {
  let key = civic_binding_key(book_id)
  for service in wenyu_civic_services() {
    if civic_binding_key(service.book_id) == key ||
      civic_binding_key(service.id) == key {
      return Some(service)
    }
    for legacy_id in service.legacy_book_ids {
      if civic_binding_key(legacy_id) == key {
        return Some(service)
      }
    }
  }
  None
}

///|
pub fn is_wenyu_civic_book_id(book_id : String) -> Bool {
  wenyu_civic_service_for_book_id(book_id) != None
}

///|
pub fn wenyu_civic_book_entry(
  service : CivicServiceDefinition,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=service.book_id,
    name="Wenyu Valley / \{service.title}",
    purpose=service.purpose,
    workspace_root=@moonbook.default_workspace_root(service.book_id),
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=[
      "wenyu-valley",
      "civic-service",
      service.id,
      service.service_kind,
      "module-mode:\{service.module_mode}",
      "book-role:\{service.book_role}",
      "parallel-lane",
    ],
    skills=[
      "civic-service",
      service.skill_pack,
      service.service_kind,
      service.skill_mode,
      service.module_mode,
      "memory",
      "review",
      "projection",
    ],
  )
}

///|
pub fn wenyu_civic_service_task(
  service : CivicServiceDefinition,
  objective : String,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id="goal-\{service.book_id}-civic-service",
    goal=Some(objective),
    title="Operate civic service workflow for \{service.title}",
    kind="civic-service-workflow",
    prompt=civic_service_task_prompt(service, objective),
    priority=138,
    requires_review=true,
    target_pages=service.target_pages,
    required_role=Some(service.worker_role),
  )
}

///|
pub fn civic_service_task_prompt(
  service : CivicServiceDefinition,
  objective : String,
) -> String {
  [
    "Operate the Wenyu Valley civic module `\{service.title}` as a module-native civic service lane.",
    "",
    "This is not a marketing-card task and not a generic research task. Use the module skill pack and decide the best next action from the module mode, current place state, current MoonBook memory, user goal, and review gates.",
    "",
    "## Service Purpose",
    "",
    service.purpose,
    "",
    "## Module Mode",
    "",
    "- Module mode: `\{service.module_mode}`.",
    "- MoonBook role: `\{service.book_role}`.",
    "- Skill mode: `\{service.skill_mode}`.",
    "- Do not force this module into a generic research-report workflow; perform the module-native work described by the skill pack.",
    "",
    "## Agent Work",
    "",
    bullet_lines(service.agent_work),
    "",
    "## Place / Exchange Work",
    "",
    bullet_lines(service.place_work),
    "",
    "## Workflow Hints",
    "",
    bullet_lines(service.workflow),
    "",
    "## Required Contract",
    "",
    "- Output contract: `\{service.output_contract}`.",
    "- Skill pack: `\{service.skill_path}`.",
    "- Building protocol contract: `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`.",
    "- Use MoonBook according to its role for this module: `\{service.book_role}`.",
    "- Queue review when the action touches external publication, application advice, bookings, redemptions, personal data, or uncertain evidence.",
    "- Do not hard-code the exact workflow; choose the next useful service action from the current book state and the skill rules.",
    "",
    "## Required Artifacts",
    "",
    bullet_lines(service.target_pages),
    "",
    "## Acceptance",
    "",
    bullet_lines(service.acceptance),
    "",
    "Town objective: \{objective}",
  ].join("\n")
}

///|
fn civic_binding_key(text : String) -> String {
  let stripped = strip_prefix(strip_prefix(text, "book-"), "wenyu-")
  stripped.to_lower()
}

///|
fn strip_prefix(text : String, prefix : String) -> String {
  if text.length() >= prefix.length() &&
    text[:prefix.length()].to_string() == prefix {
    text[prefix.length():].to_string()
  } else {
    text
  }
}

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    if !result.contains(value) {
      result.push(value)
    }
  }
  result
}

///|
fn bullet_lines(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("- ")
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string().trim().to_string()
}
