///|
fn wenyu_policy_hall_service() -> CivicServiceDefinition {
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
    worker_role=Specialist,
    acceptance=[
      "uses official or clearly labeled secondary sources", "separates cited facts from interpretation",
      "requires review before user-facing application advice",
    ],
    projection_summary="Policy quest desk for source-backed eligibility checks, checklists, and reviewable civic answers.",
  )
}

///|
fn wenyu_contest_express_service() -> CivicServiceDefinition {
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
    schema_pages=["wiki/schemas/contest.md", "wiki/schemas/readiness-score.md"],
    wiki_pages=[
      "wiki/civic/contest-express.md", "wiki/sources/contests.md", "wiki/entities/teams.md",
      "wiki/queries/contest-readiness.md",
    ],
    review_queues=["wiki/reviews/contest-submissions.md"],
    skill_pack="civic-contest-coach",
    output_contract="wenyu.civic.contest_service.v1",
    worker_role=Planner,
    acceptance=[
      "tracks deadline and submission state", "produces actionable readiness gaps",
      "does not submit externally without operator confirmation",
    ],
    projection_summary="Competition service lane for calendars, readiness, mock review, and next preparation actions.",
  )
}

///|
fn wenyu_ai_garden_service() -> CivicServiceDefinition {
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
    worker_role=Specialist,
    acceptance=[
      "writes novice-safe tutorials", "shows concrete before/after examples", "queues unsafe or uncertain advice for review",
    ],
    projection_summary="Education garden for AI tutorials, tool trials, scenario quests, and reviewed learning artifacts.",
  )
}
