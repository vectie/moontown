///|
fn research_bootstrap_sources_step_json() -> Json {
  research_bootstrap_step_json(
    id="research_bootstrap_sources",
    title="Run bounded web discovery and source screening",
    prompt_template=research_bootstrap_sources_prompt(),
    preferred_skills=["web-first-research", "source-diarize"],
    board_order=0,
    output_contract="moontown.research.sources.v1",
    retry_max_attempts=3,
  )
}

///|
fn research_bootstrap_source_expansion_step_json() -> Json {
  research_bootstrap_step_json(
    id="research_bootstrap_source_expansion",
    title="Expand weak source screens with command fallback",
    prompt_template=research_bootstrap_source_expansion_prompt(),
    preferred_skills=["web-first-research", "source-diarize"],
    board_order=1,
    output_contract="moontown.research.source_expansion.v1",
    retry_max_attempts=2,
  )
}

///|
fn research_bootstrap_report_step_json() -> Json {
  research_bootstrap_step_json(
    id="research_bootstrap_report",
    title="Synthesize evidence and write research reports",
    prompt_template=research_bootstrap_report_prompt(),
    preferred_skills=[
      "research-evidence-synthesis", "research-report", "wiki-marketing",
    ],
    board_order=2,
    output_contract="moontown.research.report.v1",
    retry_max_attempts=2,
    web_search=false,
  )
}

///|
fn research_bootstrap_quality_repair_step_json() -> Json {
  research_bootstrap_step_json(
    id="research_bootstrap_quality_repair",
    title="Review gate and repair research report if needed",
    prompt_template=research_bootstrap_quality_repair_prompt(),
    preferred_skills=["research-report", "research-evidence-synthesis"],
    board_order=3,
    output_contract="moontown.research.quality_repair.v1",
    retry_max_attempts=2,
    web_search=false,
  )
}

///|
fn research_bootstrap_step_json(
  id~ : String,
  title~ : String,
  prompt_template~ : String,
  preferred_skills~ : Array[String],
  board_order~ : Int,
  output_contract~ : String,
  retry_max_attempts~ : Int,
  web_search? : Bool = true,
) -> Json {
  {
    "id": id,
    "title": title,
    "kind": "job.analysis",
    "prompt_template": prompt_template,
    "metadata": research_bootstrap_step_metadata(
      preferred_skills~,
      board_order~,
      output_contract~,
      retry_max_attempts~,
      web_search~,
    ),
  }
}

///|
fn research_bootstrap_step_metadata(
  preferred_skills~ : Array[String],
  board_order~ : Int,
  output_contract~ : String,
  retry_max_attempts~ : Int,
  web_search~ : Bool,
) -> Json {
  let fields = @moonclaw_policy.non_adaptive_no_input_policy_fields()
  fields["preferred_skills"] = preferred_skills.to_json()
  fields["enable_tools"] = true.to_json()
  fields["web_search"] = web_search.to_json()
  fields["best_effort_on_timeout"] = true.to_json()
  fields["retry_max_attempts"] = retry_max_attempts.to_json()
  fields["retry_backoff_ms"] = (4000).to_json()
  fields["timeout_ms"] = (900000).to_json()
  fields["board_lane"] = "Bootstrap".to_json()
  fields["board_order"] = board_order.to_json()
  fields["role_runtime"] = research_bootstrap_role_runtime(output_contract)
  Json::object(fields)
}

///|
fn research_bootstrap_role_runtime(output_contract : String) -> Json {
  {
    "planning_layer": "execution",
    "runtime_mode": "executor",
    "tool_access": "full",
    "memory_scope": "workspace",
    "allow_delegate": false,
    "allow_workspace_write": true,
    "allow_execution_tools": true,
    "output_contract": output_contract,
  }
}
