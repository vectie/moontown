///|
priv struct CivicProjectionChip {
  label : String
  tone : String
} derive(ToJson)

///|
priv struct CivicProjectionMetric {
  label : String
  value : String
  note : String
  tone : String
} derive(ToJson)

///|
priv struct CivicProjectionItem {
  title : String
  detail : String
  meta : String
} derive(ToJson)

///|
priv struct CivicProjectionJourney {
  title : String
  stage : String
  status : String
  summary : String
  highlights : Array[String]
} derive(ToJson)

///|
priv struct CivicProjectionState {
  title : String
  summary : String
  status_chips : Array[CivicProjectionChip]
  metrics : Array[CivicProjectionMetric]
  readiness : Array[CivicProjectionItem]
  review_queue : Array[CivicProjectionItem]
  page_families : Array[CivicProjectionItem]
  journey : Array[CivicProjectionJourney]
} derive(ToJson)

///|
pub async fn bootstrap_wenyu_civic_workspaces(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let services = @civic.wenyu_civic_services()
  let merged = merge_wenyu_civic_catalog(catalog, services)
  @moonbook.save_catalog_file(book_catalog_path, merged)
  let objective = "Bootstrap Wenyu Valley civic service MoonBook workspaces, schemas, review queues, projections, and MoonClaw skill contracts."
  for service in services {
    let entry = @civic.wenyu_civic_book_entry(service)
    write_wenyu_civic_workspace_seed_for_service(entry, service, objective)
  }
  ignore(bootstrap_wenyu_building_protocols())
  "Bootstrapped \{services.length()} Wenyu civic MoonBook workspaces, building protocol definitions, and updated \{book_catalog_path}."
}

///|
fn merge_wenyu_civic_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
  services : Array[@civic.CivicServiceDefinition],
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if !@civic.is_wenyu_civic_book_id(entry.id) {
      merged.push(entry)
    }
  }
  for service in services {
    merged.push(@civic.wenyu_civic_book_entry(service))
  }
  merged
}

///|
async fn write_wenyu_civic_workspace_seed(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      write_wenyu_civic_workspace_seed_for_service(entry, service, objective)
    None => ()
  }
}

///|
async fn write_wenyu_civic_workspace_seed_for_service(
  entry : @moonbook.BookCatalogEntry,
  service : @civic.CivicServiceDefinition,
  objective : String,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  write_text_file_if_missing(
    "\{root}/wiki/index.md",
    civic_workspace_index_text(entry, service),
  )
  write_text_file(
    "\{root}/raw/bootstrap/CIVIC_SERVICE_CONTRACT.md",
    civic_service_contract_text(entry, service, objective),
  )
  write_text_file(
    "\{root}/raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
    civic_workspace_building_protocol_contract_text(service),
  )
  write_text_file(
    "\{root}/skills/wenyu-civic-service/SKILL.md",
    wenyu_civic_service_skill_text(),
  )
  write_text_file(
    service_skill_path(root, service),
    civic_module_skill_text(service),
  )
  write_civic_schema_pages(root, service)
  write_civic_wiki_pages(root, service)
  write_civic_review_queues(root, service)
  write_civic_projection(root, service)
  write_civic_html_pages(root, service)
  ensure_wenyu_civic_moonclaw_profile(root)
}

///|
async fn write_civic_schema_pages(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.schema_pages {
    write_text_file_if_missing(
      "\{root}/\{path}",
      civic_schema_page_text(service, path),
    )
  }
}

///|
async fn write_civic_wiki_pages(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.wiki_pages {
    write_text_file_if_missing(
      "\{root}/\{path}",
      civic_wiki_page_text(service, path),
    )
  }
}

///|
async fn write_civic_review_queues(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.review_queues {
    write_text_file_if_missing(
      "\{root}/\{path}",
      civic_review_queue_text(service, path),
    )
  }
}

///|
async fn write_civic_projection(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    civic_projection_state(service).to_json().stringify(indent=2),
  )
}

///|
async fn write_civic_html_pages(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  let html = civic_generated_site_html(service)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

///|
async fn ensure_wenyu_civic_moonclaw_profile(root : String) -> Unit {
  let path = "\{root}/moonclaw.jobs.json"
  let existing = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text()) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  let profile = @json.parse(wenyu_civic_moonclaw_profile_json()) catch {
    _ => Json::object({})
  }
  write_text_file(
    path,
    upsert_root_moonclaw_job_profile_json(
      existing, "wenyu_civic_service_worker", profile,
    ).stringify(indent=2),
  )
}

///|
fn upsert_root_moonclaw_job_profile_json(
  config : Json,
  profile_id : String,
  profile : Json,
) -> Json {
  let root = json_object_copy(Some(config))
  let jobs = json_object_copy(root.get("jobs"))
  let profiles = json_object_copy(jobs.get("profiles"))
  profiles[profile_id] = profile
  jobs["profiles"] = Json::object(profiles)
  root["jobs"] = Json::object(jobs)
  Json::object(root)
}

///|
fn service_skill_path(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> String {
  "\{root}/\{service.skill_path}"
}

///|
fn civic_workspace_index_text(
  entry : @moonbook.BookCatalogEntry,
  service : @civic.CivicServiceDefinition,
) -> String {
  [
    "# \{service.title}",
    "",
    "This workspace supports the Wenyu Valley `\{service.title}` civic module. It is not automatically a research lane; its role is `\{service.book_role}` for a `\{service.module_mode}` building.",
    "",
    "## Ownership",
    "",
    "- Moontown owns routing, daemon supervision, UI projection, and cross-module resource policy.",
    "- MoonBook owns this workspace's schemas, wiki pages, review queues, memory, and generated site.",
    "- MoonClaw owns bounded execution through the service skill pack `\{service.skill_pack}`.",
    "",
    "## Service",
    "",
    "- Book: `\{entry.id}`",
    "- Kind: `\{service.service_kind}`",
    "- Module mode: `\{service.module_mode}`",
    "- MoonBook role: `\{service.book_role}`",
    "- Skill mode: `\{service.skill_mode}`",
    "- Output contract: `\{service.output_contract}`",
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md`",
    "- `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`",
    "- `\{service.skill_path}`",
    "- `book/moonbook-ui-state.json`",
  ].join("\n")
}

///|
fn civic_service_contract_text(
  entry : @moonbook.BookCatalogEntry,
  service : @civic.CivicServiceDefinition,
  objective : String,
) -> String {
  [
    "# \{service.title} Civic Service Contract",
    "",
    "## Objective",
    "",
    objective,
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Module id: `\{service.id}`",
    "- Service kind: `\{service.service_kind}`",
    "- Module mode: `\{service.module_mode}`",
    "- MoonBook role: `\{service.book_role}`",
    "- Skill mode: `\{service.skill_mode}`",
    "- Output contract: `\{service.output_contract}`",
    "- Skill pack: `\{service.skill_path}`",
    "- Building protocol: `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`",
    "",
    "## Purpose",
    "",
    service.purpose,
    "",
    "## Workflow Hints",
    "",
    markdown_bullets(service.workflow),
    "",
    "## Agent Work",
    "",
    markdown_bullets(service.agent_work),
    "",
    "## Place / Exchange Work",
    "",
    markdown_bullets(service.place_work),
    "",
    "## Required Schemas",
    "",
    markdown_bullets(service.schema_pages),
    "",
    "## Durable Wiki Pages",
    "",
    markdown_bullets(service.wiki_pages),
    "",
    "## Review Queues",
    "",
    markdown_bullets(service.review_queues),
    "",
    "## Acceptance",
    "",
    markdown_bullets(service.acceptance),
    "",
    "## Safety Boundary",
    "",
    "- External publication, applications, bookings, redemptions, robot actions, and sensitive personal data changes require review.",
    "- If evidence is thin, write the blocker and next source class instead of inventing confidence.",
    "- Operational records must not inflate domain evidence counts.",
    "- Do not turn this module into generic research unless its skill mode explicitly requires source research.",
  ].join("\n")
}

///|
fn civic_workspace_building_protocol_contract_text(
  service : @civic.CivicServiceDefinition,
) -> String {
  let protocol = @civic.wenyu_building_protocol_for_service(service)
  [
    "# \{service.title} Building Protocol Contract",
    "",
    "This building is a protocol place, not just a MoonBook and not just a static UI card.",
    "",
    "## Social Responsibility",
    "",
    protocol.social_responsibility,
    "",
    "## Protocol Mode",
    "",
    "- Building id: `\{protocol.building_id}`",
    "- Protocol mode: `\{protocol.protocol_mode}`",
    "- Privacy scope: `\{protocol.privacy_scope}`",
    "- Projection contract: `\{protocol.projection_contract}`",
    "",
    "## Participants",
    "",
    markdown_bullets(protocol.participant_roles),
    "",
    "## Input Channels",
    "",
    markdown_bullets(protocol.input_channels),
    "",
    "## Output Channels",
    "",
    markdown_bullets(protocol.output_channels),
    "",
    "## Policies",
    "",
    "- Aggregation: \{protocol.aggregation_policy}",
    "- Exchange: \{protocol.exchange_policy}",
    "- Reduction: \{protocol.reduction_policy}",
    "- Distribution: \{protocol.distribution_policy}",
    "",
    "## Review Gates",
    "",
    markdown_bullets(protocol.review_gates),
    "",
    "## Runtime Ledgers",
    "",
    "- `.moontown/civic/protocols/\{protocol.building_id}/inbox.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/contributions.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/reductions.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/outbox.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/reviews.jsonl`",
    "",
    "## AI Reducer Boundary",
    "",
    "- Moontown hardcodes the envelope, routing, ledgers, idempotency, allowed channels, and review gates.",
    "- MoonClaw uses the skill pack to choose the building-native aggregation and reduction strategy.",
    "- MoonBook persists accepted civic records and review queues.",
  ].join("\n")
}

///|
fn wenyu_civic_service_skill_text() -> String {
  [
    "---", "name: wenyu-civic-service", "description: Operate one Wenyu Valley civic module as a MoonBook-backed service with review gates and projection-safe output.",
    "---", "", "# Wenyu Civic Service Skill", "", "Use this generic skill with the module-specific skill pack in the same workspace.",
    "", "## Rules", "", "- Read `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md` and `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md` before acting.",
    "- First identify the module mode: agent-workspace, exchange-place, projection-surface, gateway, or hybrid.",
    "- Do not force every civic module into research. Use research only when the module-specific skill asks for source discovery or evidence verification.",
    "- Choose the next useful service action from current book state, place state, and review gates; do not follow a fixed script.",
    "- For exchange-place modules, produce consent, ledger, match, request, or follow-up records rather than long reports.",
    "- For projection-surface modules, produce status, freshness, anomaly, and recovery records rather than domain research.",
    "- For gateway modules, produce confirmation-gated handoff packets and blockers; never imply external execution happened without approval.",
    "- For agent-workspace modules, produce the domain-specific artifact named by the dedicated skill pack.",
    "- Treat the building as a protocol place: map inputs into contributions, group compatible contributions, reduce them into a module-native output, and distribute only through allowed channels.",
    "- Use source evidence for knowledge claims and record source gaps clearly when knowledge claims are part of the module work.",
    "- Persist durable results to the MoonBook role defined in the contract and projection summaries to `book/moonbook-ui-state.json` only through review-safe records.",
    "- Queue review for public, legal, financial, personal, booking, robot, or offline-impact actions.",
    "- Separate operational activity from domain progress.", "", "## Required Output Shape",
    "", "Return Markdown with these fields:", "", "- `civic_service_decision: update | no_change | needs_review | blocked`",
    "- `book_changed: yes | no`", "- `wiki_pages_changed_count: <integer>`", "- `accepted_facts_count: <integer>`",
    "- `review_items_created_count: <integer>`", "- `projection_updated: yes | no`",
    "- `next_check_hint: normal | faster | slower | review`", "", "`accepted_facts_count` means accepted domain/service records for the module. For exchange-place, gateway, projection-surface, and hybrid modules, do not treat generic operational retries or daemon logs as accepted facts.",
    "", "## Concrete Example", "", "```md", "civic_service_decision: needs_review",
    "book_changed: yes", "wiki_pages_changed_count: 2", "accepted_facts_count: 3",
    "review_items_created_count: 1", "projection_updated: yes", "next_check_hint: review",
    "", "Summary: Policy Hall found a new official eligibility notice, updated the checklist, and queued an uncertain deadline interpretation for keeper review.",
    "Artifacts: `wiki/sources/policies.md`, `wiki/queries/policy-questions.md`, `wiki/reviews/policy-citations.md`",
    "```",
  ].join("\n")
}

///|
fn civic_module_skill_text(service : @civic.CivicServiceDefinition) -> String {
  [
    "---",
    "name: \{service.skill_pack}",
    "description: Role-specific MoonClaw skill pack for Wenyu Valley \{service.title}.",
    "---",
    "",
    "# \{service.title} Skill Pack",
    "",
    "You are operating the `\{service.title}` module for Wenyu Valley.",
    "",
    "## Mode",
    "",
    "- Module mode: `\{service.module_mode}`",
    "- MoonBook role: `\{service.book_role}`",
    "- Skill mode: `\{service.skill_mode}`",
    "",
    "## Purpose",
    "",
    service.purpose,
    "",
    "## What To Decide",
    "",
    "- Inspect the current MoonBook workspace and decide whether the next service action is an update, no-change digest, review queue, or blocker.",
    "- Prefer the highest-value action for a real civic operator and resident, not a generic wiki maintenance step.",
    "- Do not produce a generic research report unless this module's skill mode explicitly requires source research.",
    "- Use imagination, curiosity, and judgment: ask what would genuinely help the resident, operator, or town ecosystem, then constrain the answer by evidence and safety.",
    "",
    "## Agent Work",
    "",
    markdown_bullets(service.agent_work),
    "",
    "## Place / Exchange Work",
    "",
    markdown_bullets(service.place_work),
    "",
    "## Workflow Hints",
    "",
    markdown_bullets(service.workflow),
    "",
    "## Output Contract",
    "",
    "- Contract id: `\{service.output_contract}`",
    "- Must include changed pages, basis for the decision, review items, projection delta, and next check hint.",
    "- Count accepted facts only when they are accepted domain/service records for this module; do not count daemon retries, process logs, or generic activity.",
    "- Must not claim external action completion unless a reviewed external action actually happened.",
    "- Must respect `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`: allowed inputs, outputs, review gates, privacy scope, and distribution policy.",
    "",
    "## Mode-Specific Output",
    "",
    civic_mode_output_guidance(service),
    "",
    "## Durable Pages",
    "",
    markdown_bullets(service.target_pages),
    "",
    "## Acceptance",
    "",
    markdown_bullets(service.acceptance),
    "",
    "## Concrete Example",
    "",
    civic_skill_example(service),
  ].join("\n")
}

///|
fn civic_mode_output_guidance(
  service : @civic.CivicServiceDefinition,
) -> String {
  match service.module_mode {
    "agent-workspace" =>
      "- Produce the domain artifact named by `\{service.skill_mode}`. Use research only if the artifact requires source discovery or evidence verification."
    "exchange-place" =>
      "- Produce consent, match, request, event, ledger, or follow-up records. Keep the output short, action-oriented, and review-gated instead of report-shaped."
    "projection-surface" =>
      "- Produce status, freshness, anomaly, recovery, and accounting records. Separate what changed from what merely ran."
    "gateway" =>
      "- Produce handoff packets, required confirmations, blockers, and next offline owner. Never state that offline action happened unless confirmed."
    "hybrid" =>
      "- Produce the smallest useful mix of workspace artifact and place-facing projection. Explicitly separate private memory, public projection, and review items."
    _ =>
      "- Produce the module-native artifact described by the skill mode; do not default to generic research."
  }
}

///|
fn civic_skill_example(service : @civic.CivicServiceDefinition) -> String {
  let first_page = service.wiki_pages.get(0).unwrap_or("wiki/civic/module.md")
  let review_page = service.review_queues
    .get(0)
    .unwrap_or("wiki/reviews/module.md")
  [
    "```md",
    "civic_service_decision: update",
    "book_changed: yes",
    "wiki_pages_changed_count: 2",
    "accepted_facts_count: 4",
    "review_items_created_count: 1",
    "projection_updated: yes",
    "next_check_hint: normal",
    "",
    "Summary: \{service.title} followed `\{service.module_mode}` / `\{service.skill_mode}` mode, selected the most useful module-native action from current book and place state, updated `\{first_page}`, and queued one review item in `\{review_page}` because the action affects public/user-facing service behavior.",
    "",
    "Evidence and judgment:",
    "- What changed: one concrete service fact, exchange record, gateway request, projection state, or operating condition.",
    "- Why it matters: resident/operator impact.",
    "- What remains uncertain: source, policy, consent, budget, privacy, or offline-action risk.",
    "",
    "Artifacts:",
    "- `\{first_page}`",
    "- `\{review_page}`",
    "- `book/moonbook-ui-state.json`",
    "```",
  ].join("\n")
}

///|
fn civic_schema_page_text(
  service : @civic.CivicServiceDefinition,
  path : String,
) -> String {
  [
    "# \{schema_title(path)}",
    "",
    "Schema for `\{service.title}` (`\{service.service_kind}`).",
    "",
    "Module mode: `\{service.module_mode}`. MoonBook role: `\{service.book_role}`. Skill mode: `\{service.skill_mode}`.",
    "",
    "## Required Fields",
    "",
    "- `id`: stable record id",
    "- `source`: evidence, operator input, resident input, or runtime event",
    "- `summary`: one-sentence service meaning",
    "- `confidence`: high, medium, low, or blocked",
    "- `review_state`: none, pending, approved, rejected",
    "- `projection_scope`: private, book-only, town-safe, public-ready",
    "",
    "## Evidence Rules",
    "",
    "- Knowledge claims need source IDs or clear operator input.",
    "- Operational retries are not domain evidence.",
    "- External-impact actions require review before completion.",
  ].join("\n")
}

///|
fn civic_wiki_page_text(
  service : @civic.CivicServiceDefinition,
  path : String,
) -> String {
  [
    "# \{schema_title(path)}",
    "",
    "Durable MoonBook page for Wenyu Valley `\{service.title}`.",
    "",
    "## Current Service Thesis",
    "",
    service.projection_summary,
    "",
    "## Working Memory",
    "",
    "- The service should choose useful next actions from book evidence, resident/operator intent, and review gates.",
    "- The action should match module mode `\{service.module_mode}` and skill mode `\{service.skill_mode}`.",
    "- New claims must be grounded in sources or explicit operator input.",
    "- Projection state must remain safe for town UI.",
    "",
    "## Next Useful Questions",
    "",
    "- What changed since the last check?",
    "- Does the change create a resident-facing opportunity?",
    "- Does it require review before being shown, sent, booked, redeemed, or published?",
  ].join("\n")
}

///|
fn civic_review_queue_text(
  service : @civic.CivicServiceDefinition,
  path : String,
) -> String {
  [
    "# \{schema_title(path)}",
    "",
    "Review queue for Wenyu Valley `\{service.title}`.",
    "",
    "## Pending Review Items",
    "",
    "| ID | Trigger | Risk | Required Reviewer | Status |",
    "| --- | --- | --- | --- | --- |",
    "| seed-\{service.id}-1 | Initial service bootstrap | confirm schemas, projection, and skill boundaries | keeper/operator | pending |",
    "",
    "## Review Rules",
    "",
    markdown_bullets(service.acceptance),
  ].join("\n")
}

///|
fn civic_projection_state(
  service : @civic.CivicServiceDefinition,
) -> CivicProjectionState {
  {
    title: "Wenyu Valley / \{service.title}",
    summary: service.projection_summary,
    status_chips: [
      { label: "Civic workspace", tone: "healthy" },
      { label: service.service_kind, tone: "info" },
      { label: service.module_mode, tone: "info" },
      { label: "Review gated", tone: "review" },
    ],
    metrics: [
      {
        label: "Schemas",
        value: "\{service.schema_pages.length()}",
        note: "module-specific schemas",
        tone: "healthy",
      },
      {
        label: "Wiki pages",
        value: "\{service.wiki_pages.length()}",
        note: "durable civic pages",
        tone: "healthy",
      },
      {
        label: "Review queues",
        value: "\{service.review_queues.length()}",
        note: "keeper/operator gates",
        tone: "review",
      },
      {
        label: "Skill pack",
        value: service.skill_pack,
        note: service.output_contract,
        tone: "info",
      },
      {
        label: "Mode",
        value: service.module_mode,
        note: service.skill_mode,
        tone: "info",
      },
    ],
    readiness: projection_items(
      [
        ..service.schema_pages,
        ..service.wiki_pages,
        service.skill_path,
        "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md",
        "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
      ],
      "Ready",
    ),
    review_queue: projection_items(service.review_queues, "Pending"),
    page_families: projection_items(service.target_pages, "Workspace"),
    journey: [
      {
        title: "Civic workspace bootstrap",
        stage: "bootstrap",
        status: "projected",
        summary: "Moontown created the MoonBook-facing workspace scaffold, module skill pack, review queue, and projection fragment for \{service.title}.",
        highlights: [
          "Book id: \{service.book_id}",
          "Mode: \{service.module_mode}",
          "Book role: \{service.book_role}",
          "Skill: \{service.skill_path}",
          "Contract: \{service.output_contract}",
        ],
      },
    ],
  }
}

///|
fn projection_items(
  paths : Array[String],
  meta : String,
) -> Array[CivicProjectionItem] {
  let items : Array[CivicProjectionItem] = []
  for path in paths {
    items.push({ title: schema_title(path), detail: path, meta })
  }
  items
}

///|
fn civic_generated_site_html(service : @civic.CivicServiceDefinition) -> String {
  [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>Wenyu Valley / \{service.title}</title>",
    "  <style>",
    "    body{margin:0;font-family:Georgia,'Times New Roman',serif;background:#f5f0df;color:#20321f;}",
    "    main{max-width:960px;margin:0 auto;padding:48px 24px 72px;}",
    "    .hero{border:1px solid rgba(32,50,31,.18);border-radius:28px;padding:36px;background:linear-gradient(135deg,#fff9df,#dceec8);box-shadow:0 22px 70px rgba(55,81,46,.16);}",
    "    .eyebrow{letter-spacing:.14em;text-transform:uppercase;font:700 12px system-ui,sans-serif;color:#60733a;}",
    "    h1{font-size:48px;line-height:1;margin:10px 0 16px;}",
    "    h2{margin-top:34px;}",
    "    li{margin:8px 0;}",
    "    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin-top:22px;}",
    "    .card{border:1px solid rgba(32,50,31,.14);border-radius:18px;padding:18px;background:rgba(255,255,255,.68);}",
    "    code{background:rgba(32,50,31,.08);padding:2px 6px;border-radius:6px;}",
    "  </style>",
    "</head>",
    "<body>",
    "<main>",
    "  <section class=\"hero\">",
    "    <p class=\"eyebrow\">Wenyu Valley Civic MoonBook</p>",
    "    <h1>\{service.title}</h1>",
    "    <p>\{service.projection_summary}</p>",
    "    <p><code>\{service.module_mode}</code> <code>\{service.skill_mode}</code> <code>\{service.output_contract}</code></p>",
    "  </section>",
    "  <h2>Module Role</h2>",
    "  <p>MoonBook role: <code>\{service.book_role}</code>. This building should follow its dedicated skill and building protocol, not a generic research workflow.</p>",
    "  <div class=\"grid\">",
    "    <section class=\"card\"><h2>Agent Work</h2><ul>\{html_list_items(service.agent_work)}</ul></section>",
    "    <section class=\"card\"><h2>Place Work</h2><ul>\{html_list_items(service.place_work)}</ul></section>",
    "  </div>",
    "  <h2>Service Workflow</h2>",
    "  <ul>\{html_list_items(service.workflow)}</ul>",
    "  <div class=\"grid\">",
    "    <section class=\"card\"><h2>Schemas</h2><ul>\{html_list_items(service.schema_pages)}</ul></section>",
    "    <section class=\"card\"><h2>Wiki Pages</h2><ul>\{html_list_items(service.wiki_pages)}</ul></section>",
    "    <section class=\"card\"><h2>Review Queues</h2><ul>\{html_list_items(service.review_queues)}</ul></section>",
    "    <section class=\"card\"><h2>Skill Pack</h2><p><code>\{service.skill_path}</code></p></section>",
    "  </div>",
    "</main>",
    "</body>",
    "</html>",
  ].join("\n")
}

///|
fn wenyu_civic_moonclaw_profile_json() -> String {
  [
    "{", "  \"family\": \"wenyu_civic_service_worker\",", "  \"role\": \"worker\",",
    "  \"priority\": 145,", "  \"tags\": [\"wenyu\", \"civic\", \"service\", \"review\", \"projection\"],",
    "  \"match\": {", "    \"all\": [\"civic\"],", "    \"any\": [\"service\", \"policy\", \"contest\", \"social\", \"talent\", \"market\", \"bridge\", \"story\", \"education\"]",
    "  },", "  \"steps\": [", "    {", "      \"id\": \"execute_civic_service\",",
    "      \"title\": \"Execute Wenyu civic service packet\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Execute the imported Wenyu civic service packet for ${proposal.title}. Read raw/bootstrap/CIVIC_SERVICE_CONTRACT.md, raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md, skills/wenyu-civic-service/SKILL.md, the module-specific SKILL.md listed in skill_paths, and the existing wiki/review pages. This is a module-native building protocol operation, not a generic report or generic research lane. Follow the module mode, MoonBook role, skill mode, input channels, output channels, review gates, and distribution policy from the contracts. Map inputs into contributions, group useful compatible contributions, reduce them into a building-native output, and distribute only through allowed channels. Use web/source research only when the dedicated skill requires it; otherwise produce the appropriate exchange, projection, ledger, gateway, coaching, tutorial, story, or review artifact. Let the model choose the best next action from current book and place state, but obey review gates. Write or update only permitted artifacts unless the packet explicitly permits external output. Return Markdown with civic_service_decision, book_changed, wiki_pages_changed_count, accepted_facts_count, review_items_created_count, projection_updated, next_check_hint, artifacts, blockers, and review items. Do not wait for input; if a required source or authority is missing, write a blocker and a review item.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [\"wenyu-civic-service\"],",
    "        \"enable_tools\": true,", "        \"web_search\": true,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"timeout_ms\": 600000,",
    "        \"board_lane\": \"Civic Service\",", "        \"board_order\": 0,",
    "        \"role_runtime\": {", "          \"planning_layer\": \"domain\",", "          \"runtime_mode\": \"service\",",
    "          \"tool_access\": \"workspace\",", "          \"memory_scope\": \"domain\",",
    "          \"allow_delegate\": false,", "          \"allow_workspace_write\": true,",
    "          \"allow_execution_tools\": true,", "          \"output_contract\": \"wenyu.civic.service_packet.v1\"",
    "        }", "      }", "    },", "    {", "      \"id\": \"review_civic_service\",",
    "      \"title\": \"Review Wenyu civic service output\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Review the civic service output for ${proposal.title}. Confirm that changed pages, basis for the protocol decision, review items, projection delta, and next_check_hint are present. Reject outputs that use disallowed channels, count operational retries as domain progress, claim external completion without approval, or expose private memory. Return concise Markdown with pass/fail, blockers, and required in-place repairs.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [\"wenyu-civic-service\"],",
    "        \"enable_tools\": true,", "        \"web_search\": false,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"timeout_ms\": 300000,",
    "        \"board_lane\": \"Review\",", "        \"board_order\": 1", "      }",
    "    }", "  ],", "  \"metadata\": {", "    \"role_runtime\": {", "      \"planning_layer\": \"domain\",",
    "      \"runtime_mode\": \"service\",", "      \"tool_access\": \"workspace\",",
    "      \"memory_scope\": \"domain\",", "      \"allow_delegate\": false,", "      \"allow_workspace_write\": true,",
    "      \"allow_execution_tools\": true,", "      \"output_contract\": \"wenyu.civic.service_packet.v1\"",
    "    }", "  }", "}",
  ].join("\n")
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("- ")
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string().trim().to_string()
}

///|
fn html_list_items(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("<li>")
    builder.write_string(value)
    builder.write_string("</li>")
  }
  builder.to_string()
}

///|
fn schema_title(path : String) -> String {
  let name = path_basename(path)
    .replace(old=".md", new="")
    .replace(old="-", new=" ")
    .replace(old="_", new=" ")
  name
}
