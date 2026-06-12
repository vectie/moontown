///|
fn wenyu_social_square_service() -> CivicServiceDefinition {
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
    schema_pages=["wiki/schemas/social-match.md", "wiki/schemas/event-plan.md"],
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
  )
}

///|
fn wenyu_talent_avenue_service() -> CivicServiceDefinition {
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
  )
}

///|
fn wenyu_valley_market_service() -> CivicServiceDefinition {
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
      "keeps a reviewable points ledger", "marks anti-abuse and budget risks", "does not execute financial or redemption actions automatically",
    ],
    projection_summary="Market lane for valley points, rewards, redemption proposals, and reviewable benefit flows.",
  )
}

///|
fn wenyu_broadcast_tower_service() -> CivicServiceDefinition {
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
  )
}
