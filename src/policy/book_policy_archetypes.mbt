///|
fn default_projection_output(contract : String) -> OutputSpec {
  output(
    default_generated_site_surface(),
    contract,
    default_generated_site_projection_path(),
  )
}

///|
fn execute_skill(id : String, purpose : String) -> SkillSpec {
  skill(id, execute_lane(), "every-due-tick", purpose)
}

///|
fn tend_skill(id : String, cadence : String, purpose : String) -> SkillSpec {
  skill(id, tend_lane(), cadence, purpose)
}

///|
pub fn research() -> BookPolicy {
  new(
    [
      execute_skill(
        "standing-watch", "Search or inspect sources, compare against the book baseline, and record only meaningful deltas.",
      ),
      execute_skill(
        "source-diarize", "Turn inspected evidence into source cards, claim packets, and blockers.",
      ),
      tend_skill(
        "synthesis-revise", "slower-than-watch", "Improve cross-source synthesis, contradictions, and open questions.",
      ),
      tend_skill(
        "claim-audit", "review-cadence", "Protect durable claims from unsupported confidence.",
      ),
    ],
    [
      file("wiki/synthesis/overview.md", true, "durable synthesis"),
      file("wiki/sources/", true, "source cards"),
      file("wiki/history/standing-watch.md", true, "watch decisions"),
      file("raw/bootstrap/evidence-matrix.md", false, "bootstrap evidence"),
    ],
    quality(
      90, 80, true, "Research quality is proven by useful evidence, scoped claims, and synthesis that improves future queries.",
    ),
    default_projection_output("moontown.book.research.v1"),
  )
}

///|
pub fn course() -> BookPolicy {
  new(
    [
      execute_skill(
        "course-project", "Generate beginner-usable lessons, exercises, checkpoints, and project progression.",
      ),
      tend_skill(
        "course-review", "review-cadence", "Review whether the course teaches clearly instead of resembling a research report.",
      ),
    ],
    [
      file("wiki/course/outline.md", true, "course outline"),
      file("wiki/course/lessons.md", true, "lesson progression"),
      file("wiki/course/exercises.md", true, "hands-on practice"),
    ],
    quality(
      88, 80, true, "Course quality is proven by teachability, progressive difficulty, exercises, and learner checkpoints.",
    ),
    default_projection_output("moontown.book.course.v1"),
  )
}

///|
pub fn planbook() -> BookPolicy {
  new(
    [
      execute_skill(
        "code-plan", "Turn product gaps into bounded implementation plans with acceptance criteria.",
      ),
      execute_skill(
        "repair-dispatch", "Dispatch one bounded self-healing repair when evidence proves a gap.",
      ),
      tend_skill(
        "architecture-review", "slow-loop", "Reflect on whether the implementation still matches the intended architecture.",
      ),
    ],
    [
      file("wiki/planning/index.md", true, "plan index"),
      file("wiki/planning/role-model.md", true, "role and boundary model"),
      file("wiki/reviews/active-plan-review.md", true, "active review"),
    ],
    quality(
      92, 85, true, "PlanBook quality is proven by executable plans, repair receipts, validation evidence, and updated architecture memory.",
    ),
    default_projection_output("moontown.book.planbook.v1"),
  )
}

///|
pub fn cookbook() -> BookPolicy {
  new(
    [
      execute_skill(
        "stable-state-refresh", "Refresh docs, definitions, and current runtime state into a stable cookbook surface.",
      ),
      tend_skill(
        "drift-review", "slow-loop", "Detect drift between docs, code, live state, and operator mental models.",
      ),
    ],
    [
      file("wiki/cookbook/index.md", true, "stable operating index"),
      file("wiki/cookbook/definitions.md", true, "canonical definitions"),
      file("wiki/cookbook/runtime-state.md", true, "runtime state summary"),
    ],
    quality(
      88, 80, true, "Cookbook quality is proven by stable definitions, current runtime facts, and low-drift operating guidance.",
    ),
    default_projection_output("moontown.book.cookbook.v1"),
  )
}

///|
pub fn civic_protocol() -> BookPolicy {
  new(
    [
      execute_skill(
        "protocol-round", "Run inbox, contribution, reduction, review, and distribution over building documents.",
      ),
      tend_skill(
        "service-review", "review-cadence", "Review social responsibility, safety, persistence mode, and protocol usefulness.",
      ),
    ],
    [
      file(
        "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md", true, "protocol contract",
      ),
      file("wiki/ledgers/exchange-ledger.md", true, "exchange ledger"),
      file("wiki/reviews/pending.md", true, "review queue"),
    ],
    quality(
      84, 78, true, "Civic quality is proven by protocol-native information exchange, accepted distribution, and reviewable service history.",
    ),
    default_projection_output("moontown.book.civic.v1"),
  )
}

///|
pub fn operational() -> BookPolicy {
  new(
    [
      execute_skill(
        "operational-keeper", "Maintain operational memory, safe execution boundaries, and review policy.",
      ),
      tend_skill(
        "boundary-review", "slow-loop", "Review whether operational memory remains useful, safe, and non-noisy.",
      ),
    ],
    [
      file("wiki/operations/review-policy.md", true, "review policy"),
      file("wiki/history/journey.md", true, "operational journey"),
      file("keeper/MEMORY.md", false, "keeper memory"),
    ],
    quality(
      82, 75, true, "Operational quality is proven by useful memory, safe boundaries, and low-noise journey accounting.",
    ),
    default_projection_output("moontown.book.operational.v1"),
  )
}

///|
pub fn general() -> BookPolicy {
  new(
    [
      execute_skill(
        "workspace-bootstrap", "Create or repair the minimum files required for a typed book workspace.",
      ),
      tend_skill(
        "workspace-classify", "slow-loop", "Decide which composed policy the book should adopt next.",
      ),
    ],
    [
      file("index.md", true, "workspace index"),
      file(
        default_generated_site_projection_path(),
        false,
        "projection surface",
      ),
    ],
    quality(
      70, 65, true, "General book quality is provisional until a more specific composed policy is selected.",
    ),
    default_projection_output("moontown.book.general.v1"),
  )
}
