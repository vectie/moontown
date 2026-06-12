///|
async fn render_moonclaw_command(args : Array[String]) -> String {
  match args {
    ["stores", "compact"] =>
      @moonclaw_runtime.compact_registered_moonclaw_job_stores()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_civic_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @civic_runtime.bootstrap_wenyu_civic_workspaces()
    ["status"] => @civic_runtime.render_wenyu_civic_status()
    ["doctor"] => @civic_runtime.write_wenyu_civic_status()
    ["reconcile"] => @civic_runtime.reconcile_wenyu_civic_service_results()
    ["protocols", .. rest] => render_civic_protocols_command(rest.to_owned())
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_civic_protocols_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @civic_runtime.bootstrap_wenyu_building_protocols()
    ["status"] => @civic_runtime.render_wenyu_building_protocol_status()
    ["doctor"] => @civic_runtime.write_wenyu_building_protocol_status()
    ["patterns"] => @civic_runtime.render_civic_communication_patterns()
    ["pattern-install", template_path] =>
      @civic_runtime.install_civic_pattern_scenario_file(template_path)
    ["pattern-manifest", manifest_path] =>
      @civic_runtime.install_civic_pattern_scenario_manifest(manifest_path)
    ["pattern-template", template_path] =>
      @civic_runtime.bootstrap_civic_salon_scenario_file(template_path)
    ["schedules", "tick"] => @civic_runtime.run_due_civic_salons()
    ["schedules", "status"] =>
      @civic_runtime.render_civic_salon_schedule_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_integration_command(args : Array[String]) -> String {
  match args {
    ["final", "install"] => @final_integration.install_wenyu_final_integration()
    ["final", "install", manifest_path] =>
      @final_integration.install_wenyu_final_integration(manifest_path~)
    ["final", "status"] =>
      @final_integration.render_wenyu_final_integration_status()
    ["final", "status", manifest_path] =>
      @final_integration.render_wenyu_final_integration_status(manifest_path~)
    _ => @moontown.load_or_create_demo_dashboard()
  }
}
