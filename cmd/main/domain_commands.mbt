///|
async fn render_moonclaw_command(args : Array[String]) -> String {
  match args {
    ["stores", "compact"] => @moontown.compact_registered_moonclaw_job_stores()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_civic_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @moontown.bootstrap_wenyu_civic_workspaces()
    ["status"] => @moontown.render_wenyu_civic_status()
    ["doctor"] => @moontown.write_wenyu_civic_status()
    ["reconcile"] => @moontown.reconcile_wenyu_civic_service_results()
    ["protocols", .. rest] => render_civic_protocols_command(rest.to_owned())
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_civic_protocols_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @moontown.bootstrap_wenyu_building_protocols()
    ["status"] => @moontown.render_wenyu_building_protocol_status()
    ["doctor"] => @moontown.write_wenyu_building_protocol_status()
    ["patterns"] => @moontown.render_civic_communication_patterns()
    ["pattern-install", template_path] =>
      @moontown.install_civic_pattern_scenario_file(template_path)
    ["pattern-manifest", manifest_path] =>
      @moontown.install_civic_pattern_scenario_manifest(manifest_path)
    ["pattern-template", template_path] =>
      @moontown.bootstrap_civic_salon_scenario_file(template_path)
    ["schedules", "tick"] => @moontown.run_due_civic_salons()
    ["schedules", "status"] => @moontown.render_civic_salon_schedule_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_integration_command(args : Array[String]) -> String {
  match args {
    ["final", "install"] => @moontown.install_wenyu_final_integration()
    ["final", "install", manifest_path] =>
      @moontown.install_wenyu_final_integration(manifest_path~)
    ["final", "status"] => @moontown.render_wenyu_final_integration_status()
    ["final", "status", manifest_path] =>
      @moontown.render_wenyu_final_integration_status(manifest_path~)
    _ => @moontown.load_or_create_demo_dashboard()
  }
}
