///|
async fn reduce_civic_salon_ideas(
  scenario : CivicSalonScenario,
  round_id? : String = "civic-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
  mode? : CivicSalonReductionMode = MoonClawReducer,
) -> CivicSalonReductionResult {
  if mode == FixtureReducer {
    fixture_civic_salon_reduction(scenario, round_id, workspace_base)
  } else if mode == PersistedReducer {
    persisted_civic_salon_reduction(scenario, round_id, workspace_base)
  } else {
    moonclaw_civic_salon_reduction(
      scenario, round_id, round_number, workspace_base,
    )
  }
}

///|
fn civic_salon_reducer_output_path(
  scenario : CivicSalonScenario,
  workspace_base : String,
) -> String {
  "\{civic_salon_workspace_root(scenario.building_book_id, workspace_base)}/raw/bootstrap/civic-salon-ideas.json"
}

///|
fn civic_salon_reducer_packet_path(
  scenario : CivicSalonScenario,
  round_id : String,
  workspace_base : String,
) -> String {
  "\{civic_salon_workspace_root(scenario.building_book_id, workspace_base)}/raw/bootstrap/civic-salon-reducer-\{scenario.id}-\{round_id}.packet.json"
}

///|
async fn fixture_civic_salon_reduction(
  scenario : CivicSalonScenario,
  round_id : String,
  workspace_base : String,
) -> CivicSalonReductionResult {
  let ideas = scenario.ideas
  persist_civic_salon_reducer_output(scenario, ideas, workspace_base)
  {
    ideas,
    status: if ideas.length() > 0 {
      @core.TaskExecutionStatus::Completed
    } else {
      @core.TaskExecutionStatus::Failed
    },
    summary: "Fixture reducer loaded \{ideas.length()} template idea(s) for explicit deterministic smoke execution of `\{round_id}`.",
    packet_id: None,
    packet_path: None,
    proposal_id: None,
    run_id: None,
    workspace_root: civic_salon_workspace_root(
      scenario.building_book_id,
      workspace_base,
    ),
    reducer_kind: "fixture",
  }
}

///|
async fn persisted_civic_salon_reduction(
  scenario : CivicSalonScenario,
  round_id : String,
  workspace_base : String,
) -> CivicSalonReductionResult {
  let root = civic_salon_workspace_root(
    scenario.building_book_id,
    workspace_base,
  )
  match load_persisted_civic_salon_reducer_output(scenario, workspace_base) {
    Some(loaded) => {
      let ideas = loaded
      CivicSalonReductionResult::{
        ideas,
        status: if ideas.length() > 0 {
          @core.TaskExecutionStatus::Completed
        } else {
          @core.TaskExecutionStatus::Failed
        },
        summary: if ideas.length() > 0 {
          "Persisted reducer replayed \{ideas.length()} prior MoonClaw idea(s) for projection refresh of `\{round_id}`."
        } else {
          "Persisted reducer output exists but contains no valid CivicSalonIdea records for `\{round_id}`."
        },
        packet_id: None,
        packet_path: None,
        proposal_id: None,
        run_id: None,
        workspace_root: root,
        reducer_kind: "persisted",
      }
    }
    None =>
      {
        ideas: [],
        status: @core.TaskExecutionStatus::Failed,
        summary: "No persisted civic salon reducer output found at `raw/bootstrap/civic-salon-ideas.json`; refresh skipped instead of falling back to template seed ideas.",
        packet_id: None,
        packet_path: None,
        proposal_id: None,
        run_id: None,
        workspace_root: root,
        reducer_kind: "persisted",
      }
  }
}

///|
async fn moonclaw_civic_salon_reduction(
  scenario : CivicSalonScenario,
  round_id : String,
  round_number : Int,
  workspace_base : String,
) -> CivicSalonReductionResult {
  let root = civic_salon_workspace_root(
    scenario.building_book_id,
    workspace_base,
  )
  write_civic_salon_reducer_workspace(scenario, root, round_id, round_number)
  let packet_id = "civic-salon-reducer-\{scenario.id}-\{round_id}"
  let packet_path = civic_salon_reducer_packet_path(
    scenario, round_id, workspace_base,
  )
  let packet = civic_salon_reducer_packet(
    scenario, packet_id, round_id, round_number,
  )
  let imported = @moonclaw.import_packet(
    packet,
    packet_path,
    cwd=root,
    confirm=true,
    run_inline=moontown_moonclaw_inline_enabled(),
  ) catch {
    error =>
      return failed_civic_salon_reduction(
        root,
        Some(packet_id),
        Some(packet_path),
        "MoonClaw reducer import failed for `\{scenario.id}`: \{error}",
      )
  }
  let execution = match imported.run_id {
    Some(run_id) => ensure_run_execution(packet_id, run_id, root)
    None => None
  }
  let status = execution
    .map(fn(result) { result.0.status })
    .unwrap_or(imported.status)
  let worker_summary = execution
    .map(fn(result) { result.0.summary })
    .unwrap_or(imported.summary)
  let ideas = load_civic_salon_reducer_output_after_run(
    scenario,
    workspace_base,
    root,
    imported.run_id,
  )
  if status is @core.TaskExecutionStatus::Completed && ideas.length() > 0 {
    persist_civic_salon_reducer_output(scenario, ideas, workspace_base)
    {
      ideas,
      status,
      summary: "MoonClaw reducer completed with \{ideas.length()} idea(s). \{worker_summary}",
      packet_id: Some(packet_id),
      packet_path: Some(packet_path),
      proposal_id: Some(imported.proposal_id),
      run_id: imported.run_id,
      workspace_root: root,
      reducer_kind: "moonclaw",
    }
  } else if civic_salon_reduction_status_live(status) {
    {
      ideas: [],
      status,
      summary: "MoonClaw reducer is still active for `\{scenario.id}`. status=\{status}; \{worker_summary}",
      packet_id: Some(packet_id),
      packet_path: Some(packet_path),
      proposal_id: Some(imported.proposal_id),
      run_id: imported.run_id,
      workspace_root: root,
      reducer_kind: "moonclaw",
    }
  } else {
    failed_civic_salon_reduction(
      root,
      Some(packet_id),
      Some(packet_path),
      "MoonClaw reducer did not produce a valid non-empty CivicSalonIdea contract. status=\{status}; \{worker_summary}",
      proposal_id=Some(imported.proposal_id),
      run_id=imported.run_id,
    )
  }
}

///|
fn civic_salon_reduction_status_live(
  status : @core.TaskExecutionStatus,
) -> Bool {
  status is @core.TaskExecutionStatus::ProposalImported ||
  status is @core.TaskExecutionStatus::RunConfirmed ||
  status is @core.TaskExecutionStatus::Running ||
  status is @core.TaskExecutionStatus::AwaitingPersistence
}

///|
fn failed_civic_salon_reduction(
  root : String,
  packet_id : String?,
  packet_path : String?,
  summary : String,
  proposal_id? : String? = None,
  run_id? : String? = None,
) -> CivicSalonReductionResult {
  {
    ideas: [],
    status: @core.TaskExecutionStatus::Failed,
    summary,
    packet_id,
    packet_path,
    proposal_id,
    run_id,
    workspace_root: root,
    reducer_kind: "moonclaw",
  }
}

///|
async fn write_civic_salon_reducer_workspace(
  scenario : CivicSalonScenario,
  root : String,
  round_id : String,
  round_number : Int,
) -> Unit {
  write_text_file(
    "\{root}/skills/\{scenario.skill_name}/SKILL.md",
    civic_salon_reducer_skill_text(scenario),
  )
  write_text_file(
    "\{root}/raw/bootstrap/civic-salon-participants.json",
    scenario.participants.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{root}/raw/bootstrap/civic-salon-reducer-input.md",
    civic_salon_reducer_input_markdown(scenario, round_id, round_number),
  )
  write_text_file(
    "\{root}/raw/bootstrap/civic-salon-reducer-contract.md",
    civic_salon_reducer_contract_markdown(scenario),
  )
  write_text_file(
    "\{root}/moonclaw.jobs.json",
    merged_civic_salon_reducer_profile_json(root, scenario),
  )
}

///|
async fn merged_civic_salon_reducer_profile_json(
  root : String,
  scenario : CivicSalonScenario,
) -> String {
  let path = "\{root}/moonclaw.jobs.json"
  let existing = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text()) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  let reducer_root = @json.parse(civic_salon_reducer_profile_json(scenario)) catch {
    _ => Json::object({})
  }
  let reducer_root_object = json_object_copy(Some(reducer_root))
  let reducer_jobs = json_object_copy(reducer_root_object.get("jobs"))
  let reducer_profiles = json_object_copy(reducer_jobs.get("profiles"))
  let reducer_profile = match
    reducer_profiles.get("civic_salon_reducer_worker") {
    Some(profile) => profile
    None => Json::object({})
  }
  upsert_root_moonclaw_job_profile_json(
    existing, "civic_salon_reducer_worker", reducer_profile,
  ).stringify(indent=2)
}

///|
fn civic_salon_reducer_packet(
  scenario : CivicSalonScenario,
  packet_id : String,
  round_id : String,
  round_number : Int,
) -> @moonclaw.ExternalProposalPacket {
  let pattern = civic_salon_pattern_for_scenario(scenario)
  @moonclaw.ExternalProposalPacket::new(
    packet_id~,
    title="Reduce \{scenario.title} round \{round_number}",
    summary="Run the \{scenario.domain_label} \{pattern.title} reducer and emit CivicSalonIdea JSON for \{scenario.title}.",
    request_text=civic_salon_reducer_request(scenario, round_id, round_number),
    profile="civic_salon_reducer_worker",
    output_contract=pattern.output_contract,
    context_pages=[
      "raw/bootstrap/civic-salon-reducer-contract.md", "raw/bootstrap/civic-salon-participants.json",
      "raw/bootstrap/civic-salon-reducer-input.md",
    ],
    skill_paths=["skills/\{scenario.skill_name}/SKILL.md"],
    notes=[
      "Read the generated SKILL.md before reducing ideas.", "Do not use template-provided seed ideas; only participant context and contract files are input.",
      "Write raw/bootstrap/civic-salon-ideas.json with the exact CivicSalonIdea contract.",
    ],
    tags=[
      "civic-communication-pattern",
      pattern.id,
      "reducer",
      scenario.id,
      scenario.building_id,
    ],
    metadata={
      "producer": "moontown".to_json(),
      "building_id": scenario.building_id.to_json(),
      "book_id": scenario.building_book_id.to_json(),
      "round_id": round_id.to_json(),
      "round_number": round_number.to_json(),
      "communication_pattern_id": pattern.id.to_json(),
      "communication_pattern_title": pattern.title.to_json(),
      "disable_waiting_for_input": true.to_json(),
      "best_effort_on_missing_input": true.to_json(),
      "profile_metadata": {
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
      },
      "step_metadata": {
        "kind": "civic_salon_reducer".to_json(),
        "output_contract": pattern.output_contract.to_json(),
        "preferred_skills": [scenario.skill_name].to_json(),
        "target_pages": ["raw/bootstrap/civic-salon-ideas.json"].to_json(),
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
      },
    },
  )
}

///|
fn civic_salon_reducer_request(
  scenario : CivicSalonScenario,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
  [
    "You are the MoonClaw reducer for `\{scenario.title}` using the `\{pattern.title}` communication pattern.",
    "Round: `\{round_id}` (#\{round_number}).",
    "Read `skills/\{scenario.skill_name}/SKILL.md` first, then read the reducer contract and participant JSON.",
    "Reduce participant perspectives according to this pattern: \{pattern.summary}",
    "Write the result to `raw/bootstrap/civic-salon-ideas.json`.",
    "Do not wait for user input. If evidence is incomplete, produce best-effort pattern outputs with explicit follow-up questions and next experiments/artifacts.",
  ].join("\n")
}

///|
fn civic_salon_reducer_skill_text(scenario : CivicSalonScenario) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
  [
    "---",
    "name: \{scenario.skill_name}",
    "description: \{scenario.skill_description}",
    "---",
    "",
    "# \{scenario.title} Reducer Skill",
    "",
    "This skill controls the building-level reducer for the `\{pattern.title}` communication pattern. The reducer is an agentic map-reduce place: internal participant workspaces map perspectives, requests, constraints, signals, or artifacts into packets, then this worker reduces them into useful reviewable outputs for return-home work.",
    "",
    "Pattern summary: \{pattern.summary}",
    "",
    "## Required Behavior",
    "",
    civic_salon_markdown_bullets(scenario.skill_rules),
    "",
    "## Quality Rules",
    "",
    civic_salon_markdown_bullets(scenario.quality_rules),
    "",
    "## Reduction Rules",
    "",
    "- Read every participant in `raw/bootstrap/civic-salon-participants.json`.",
    "- Use at least two participant workspaces for each idea unless the participant set itself has only one workspace.",
    "- Generate outputs from tensions, dependencies, missing interfaces, evaluation gaps, shared bottlenecks, matching opportunities, routing needs, or safety gates.",
    "- Prefer follow-up questions that can become benchmarks, protocols, schemas, experiments, service actions, matched introductions, lesson plans, stories, recovery steps, or review gates.",
    "- Do not claim the output is accepted knowledge. It is a returned direction for the owning books and review gate.",
    "- Do not copy or consume template seed ideas. If seed examples exist elsewhere, ignore them.",
    "",
    "## Output Contract",
    "",
    "Emit the same `CivicSalonIdea` contract that Moontown materializes into building ledgers, internal participant workspaces, review queues, and projections. For non-research patterns, treat `research_questions` as testable follow-up or review questions and `next_experiment` as the smallest useful next artifact/action.",
    "",
    "Write `raw/bootstrap/civic-salon-ideas.json` exactly as JSON:",
    "",
    "```json",
    "{",
    "  \"ideas\": [",
    "    {",
    "      \"id\": \"lowercase-stable-id\",",
    "      \"title\": \"Short pattern output title\",",
    "      \"summary\": \"One or two precise sentences explaining the cross-area dependency, routing decision, match, lesson plan, story angle, or recovery action.\",",
    "      \"participating_books\": [\"workspace-a\", \"workspace-b\"],",
    "      \"research_questions\": [",
    "        \"A testable question that belongs in follow-up work\",",
    "        \"A second question that forces a concrete experiment or review gate\"",
    "      ],",
    "      \"why_it_matters\": \"Why this could change the domain program or civic service outcome.\",",
    "      \"next_experiment\": \"The smallest useful next experiment, prototype, benchmark, schema, service action, story draft, match review, lesson exercise, or recovery drill.\"",
    "    }",
    "  ],",
    "  \"summary\": \"Reducer-level summary.\"",
    "}",
    "```",
    "",
    "## Concrete Example",
    "",
    "For a robotics research salon with VLA, world-model, manipulation, and safety workspaces, a good idea links perception-action policy limits to world-model uncertainty and proposes a concrete benchmark. For a policy triage desk, a good output routes a resident question to official-source extraction plus review instead of inventing eligibility advice. A poor output merely says \"combine sources\" or \"help the resident\" without owner workspaces, a checkable follow-up question, or a review gate.",
  ].join("\n")
}

///|
fn civic_salon_reducer_input_markdown(
  scenario : CivicSalonScenario,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
  [
    "# Civic Communication Pattern Reducer Input",
    "",
    "- Scenario: \{scenario.title}",
    "- Communication pattern: \{pattern.title} (`\{pattern.id}`)",
    "- Domain: \{scenario.domain_label}",
    "- Topic: \{scenario.topic}",
    "- Building: `\{scenario.building_id}`",
    "- Round: `\{round_id}` (#\{round_number})",
    "- Protocol channel: `\{scenario.protocol_channel}`",
    "- Output channel: `\{scenario.output_channel}`",
    "- Review gate: `\{scenario.review_gate}`",
    "",
    "The only authoritative inputs for reduction are the participant records and the generated skill/contract files. Template fixture ideas are intentionally not present in this reducer workspace.",
  ].join("\n")
}

///|
fn civic_salon_reducer_contract_markdown(
  scenario : CivicSalonScenario,
) -> String {
  [
    "# Civic Communication Pattern Output Contract",
    "",
    "Emit a non-empty set of `CivicSalonIdea` records to `raw/bootstrap/civic-salon-ideas.json`. The legacy type name is reused for every civic communication pattern while the runtime is experimental.",
    "",
    "Each idea must include:",
    "",
    "- `id`: stable lowercase id",
    "- `title`: human-readable idea title",
    "- `summary`: cross-area dependency, routing decision, match proposal, lesson plan, story angle, or recovery action",
    "- `participating_books`: participant workspace ids from the input JSON",
    "- `research_questions`: at least one testable follow-up or review question",
    "- `why_it_matters`: judgement about why the output is worth tracking",
    "- `next_experiment`: smallest useful next experiment, action, artifact, drill, or review exercise",
    "",
    "The reducer must not create accepted facts. It creates reviewable directions or service outputs that are distributed back to internal participant workspaces through `\{scenario.output_channel}` and reviewed by `\{scenario.review_gate}`.",
  ].join("\n")
}

///|
fn civic_salon_reducer_profile_json(scenario : CivicSalonScenario) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
  let parsed = @json.parse(
    "{ \"jobs\": { \"profiles\": { \"civic_salon_reducer_worker\": { \"family\": \"civic_salon_reducer_worker\", \"role\": \"worker\", \"priority\": 155, \"tags\": [\"civic\", \"communication-pattern\", \{json_string(pattern.id)}, \"reducer\", \{json_string(scenario.building_id)}], \"match\": { \"all\": [\"civic-communication-pattern\", \"reducer\"], \"any\": [\{json_string(pattern.id)}, \{json_string(scenario.id)}, \{json_string(scenario.building_id)}] }, \"steps\": [{ \"id\": \"reduce_civic_pattern_outputs\", \"title\": \"Reduce communication-pattern participant packets into reviewable outputs\", \"kind\": \"job.analysis\", \"prompt_template\": \"Read ${proposal.request_text}. Then read the listed context pages and skill_paths. Write raw/bootstrap/civic-salon-ideas.json only after validating the CivicSalonIdea compatibility contract. Do not wait for input and do not use template seed ideas.\", \"metadata\": { \"preferred_skills\": [\{json_string(scenario.skill_name)}], \"enable_tools\": true, \"web_search\": false, \"disable_waiting_for_input\": true, \"best_effort_on_missing_input\": true, \"timeout_ms\": 600000, \"board_lane\": \{json_string(pattern.title)}, \"board_order\": 0, \"communication_pattern_id\": \{json_string(pattern.id)}, \"role_runtime\": { \"planning_layer\": \"domain\", \"runtime_mode\": \"reducer\", \"tool_access\": \"workspace\", \"memory_scope\": \"domain\", \"allow_delegate\": false, \"allow_workspace_write\": true, \"allow_execution_tools\": true, \"output_contract\": \{json_string(pattern.output_contract)} } } }] } } } }",
  ) catch {
    _ => Json::object({})
  }
  parsed.stringify(indent=2)
}

///|
async fn load_civic_salon_reducer_output_after_run(
  scenario : CivicSalonScenario,
  workspace_base : String,
  root : String,
  run_id : String?,
) -> Array[CivicSalonIdea] {
  let run_ideas = match run_id {
    Some(run_id) =>
      match @moonclaw.run_workspace_dir(run_id, cwd=root) {
        Some(workspace_dir) =>
          match
            load_civic_salon_ideas_file(
              "\{workspace_dir}/raw/bootstrap/civic-salon-ideas.json",
            ) {
            Some(loaded) => {
              let ideas = loaded
              if ideas.length() > 0 {
                persist_civic_salon_reducer_output(
                  scenario, ideas, workspace_base,
                )
              }
              ideas
            }
            None => []
          }
        None => []
      }
    None => []
  }
  if run_ideas.length() > 0 {
    return run_ideas
  }
  match load_persisted_civic_salon_reducer_output(scenario, workspace_base) {
    Some(ideas) => ideas
    None => []
  }
}

///|
async fn load_persisted_civic_salon_reducer_output(
  scenario : CivicSalonScenario,
  workspace_base : String,
) -> Array[CivicSalonIdea]? {
  match
    load_civic_salon_ideas_file(
      civic_salon_scenario_output_path(scenario, workspace_base),
    ) {
    Some(ideas) => return Some(ideas)
    None => ()
  }
  load_civic_salon_ideas_file(
    civic_salon_reducer_output_path(scenario, workspace_base),
  )
}

///|
async fn load_civic_salon_ideas_file(path : String) -> Array[CivicSalonIdea]? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text() catch { _ => return None }
  let parsed = @json.parse(text) catch { _ => return None }
  let ideas = match parsed {
    Array(_) => {
      let values : Array[CivicSalonIdea] = @json.from_json(parsed) catch {
        _ => return None
      }
      values
    }
    Object(object) =>
      match object.get("ideas") {
        Some(value) => {
          let values : Array[CivicSalonIdea] = @json.from_json(value) catch {
            _ => return None
          }
          values
        }
        _ => return None
      }
    _ => return None
  }
  Some(ideas)
}

///|
async fn persist_civic_salon_reducer_output(
  scenario : CivicSalonScenario,
  ideas : Array[CivicSalonIdea],
  workspace_base : String,
) -> Unit {
  write_text_file(
    civic_salon_reducer_output_path(scenario, workspace_base),
    Json::object({ "ideas": ideas.to_json() }).stringify(indent=2),
  )
  write_text_file(
    civic_salon_scenario_output_path(scenario, workspace_base),
    Json::object({ "ideas": ideas.to_json() }).stringify(indent=2),
  )
}

///|
fn civic_salon_scenario_output_path(
  scenario : CivicSalonScenario,
  workspace_base : String,
) -> String {
  "\{civic_salon_workspace_root(scenario.building_book_id, workspace_base)}/raw/bootstrap/\{scenario.id}-ideas.json"
}

///|
async fn write_civic_salon_reducer_blocker(
  scenario : CivicSalonScenario,
  reduction : CivicSalonReductionResult,
  round_id : String,
) -> Unit {
  write_text_file(
    "\{reduction.workspace_root}/raw/bootstrap/civic-salon-reducer-blocker.md",
    [
      "# Civic Salon Reducer Blocker",
      "",
      "- Salon: `\{scenario.id}`",
      "- Round: `\{round_id}`",
      "- Reducer: `\{reduction.reducer_kind}`",
      "- Status: `\{reduction.status}`",
      "",
      reduction.summary,
      "",
      "Moontown did not fall back to template seed ideas. The next retry must run the MoonClaw reducer or use an explicit fixture mode in tests.",
    ].join("\n"),
  )
}
