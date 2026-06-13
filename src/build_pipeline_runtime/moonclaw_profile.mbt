///|
pub async fn ensure_wenyu_build_moonclaw_profile(root : String) -> Unit {
  let path = "\{root}/moonclaw.jobs.json"
  let profile = wenyu_build_moonclaw_profile_json()
  if !@fs.exists(path) {
    @support.write_text_file(
      path,
      @support.upsert_moonclaw_job_profile_json(
        Json::object({}),
        "wenyu_build_controller",
        profile,
      ).stringify(indent=2),
    )
    return
  }
  let text = @support.read_text_or_empty(path)
  let parsed = @json.parse(text) catch {
    _ => {
      insert_wenyu_build_profile_text(path, text, profile)
      return
    }
  }
  @support.write_text_file(
    path,
    @support.upsert_moonclaw_job_profile_json(
      parsed, "wenyu_build_controller", profile,
    ).stringify(indent=2),
  )
}

///|
async fn insert_wenyu_build_profile_text(
  path : String,
  text : String,
  profile : Json,
) -> Unit {
  if text.contains("\"wenyu_build_controller\"") {
    return
  }
  let marker = "\"profiles\": {"
  let replacement = "\"profiles\": {\n      \"wenyu_build_controller\": \{profile.stringify(indent=6)},"
  if text.contains(marker) {
    @support.write_text_file(path, text.replace(old=marker, new=replacement))
  }
}

///|
fn wenyu_build_moonclaw_profile_json() -> Json {
  {
    "family": "wenyu_build_controller",
    "role": "controller",
    "priority": 150,
    "tags": ["wenyu", "build", "code", "asset", "implementation"],
    "match": {
      "all": ["wenyu"],
      "any": ["build", "implementation", "code", "asset", "projection"],
    },
    "steps": [wenyu_build_execute_step_json(), wenyu_build_review_step_json()],
    "metadata": {
      "profile_metadata": @moonclaw_runtime.moonclaw_no_input_policy_json(),
      "role_runtime": wenyu_build_role_runtime_json(),
    },
  }
}

///|
fn wenyu_build_execute_step_json() -> Json {
  {
    "id": "execute_wenyu_build",
    "title": "Execute Wenyu build packet",
    "kind": "job.analysis",
    "execution_mode": "acp",
    "execution_target": "wenyu-codex-moontown",
    "prompt_template": @build_pipeline.wenyu_build_execute_prompt_template(),
    "metadata": wenyu_build_step_metadata(
      preferred_skills=["wenyu-build", "wenyu-code-patch", "wenyu-asset-pack"],
      board_lane="Build",
      board_order=0,
    ),
  }
}

///|
fn wenyu_build_review_step_json() -> Json {
  {
    "id": "review_wenyu_build",
    "title": "Review Wenyu build output",
    "kind": "job.analysis",
    "execution_mode": "acp",
    "execution_target": "wenyu-codex-moontown",
    "prompt_template": @build_pipeline.wenyu_build_review_prompt_template(),
    "metadata": wenyu_build_step_metadata(
      preferred_skills=["wenyu-build"],
      board_lane="Review",
      board_order=1,
    ),
  }
}

///|
fn wenyu_build_step_metadata(
  preferred_skills~ : Array[String],
  board_lane~ : String,
  board_order~ : Int,
) -> Json {
  let fields = @moonclaw_runtime.moonclaw_step_metadata_fields(
    preferred_skills~,
    enable_tools=true,
    web_search=false,
    timeout_ms=600000,
    board_lane~,
    board_order~,
  )
  fields["model"] = @codex.model().to_json()
  Json::object(fields)
}

///|
fn wenyu_build_role_runtime_json() -> Json {
  {
    "planning_layer": "domain",
    "runtime_mode": "builder",
    "tool_access": "workspace",
    "memory_scope": "domain",
    "allow_delegate": false,
    "allow_workspace_write": true,
    "allow_execution_tools": true,
    "output_contract": @build_pipeline.wenyu_build_packet_contract(),
  }
}
