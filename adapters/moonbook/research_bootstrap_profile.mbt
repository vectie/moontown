///|
fn moontown_research_bootstrap_profile_json() -> Json {
  {
    "family": "moontown_research_bootstrap_worker",
    "role": "worker",
    "priority": 150,
    "tags": ["moontown", "research", "bootstrap", "web", "wiki"],
    "match": {
      "all": ["research"],
      "any": ["bootstrap", "source", "web", "evidence", "report"],
    },
    "steps": [
      research_bootstrap_sources_step_json(),
      research_bootstrap_source_expansion_step_json(),
      research_bootstrap_report_step_json(),
      research_bootstrap_quality_repair_step_json(),
    ],
    "metadata": {
      "profile_metadata": research_bootstrap_runtime_policy_json(),
      "worker_role": "research_bootstrap",
    },
  }
}
