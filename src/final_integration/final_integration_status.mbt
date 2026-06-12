///|
fn final_integration_status_json(
  manifest : FinalIntegrationManifest,
  goals : Array[@core.StandingGoal],
  current_tick : Int,
  civic_workspace_summary : String,
  protocol_summary : String,
  install_summaries : Array[String],
) -> Json {
  @json.parse(
    [
      "{",
      "  \"id\": \{@support.json_string(manifest.id)},",
      "  \"title\": \{@support.json_string(manifest.title)},",
      "  \"current_tick\": \{current_tick},",
      "  \"domain_watch_count\": \{manifest.domain_watches.length()},",
      "  \"domain_watch_coverage\": \{@support.json_string(final_integration_watch_coverage(manifest, goals))},",
      "  \"standing_goal_count\": \{goals.length()},",
      "  \"civic_pattern_manifest_count\": \{manifest.civic_pattern_manifests.length()},",
      "  \"civic_scenario_count\": \{manifest.civic_scenarios.length()},",
      "  \"civic_workspace_summary\": \{@support.json_string(civic_workspace_summary)},",
      "  \"protocol_summary\": \{@support.json_string(protocol_summary)},",
      "  \"install_summaries\": \{@support.json_string_array(install_summaries)}",
      "}",
    ].join("\n"),
  ) catch {
    _ => Json::object({})
  }
}
