///|
async fn main {
  let args = @env.args()
  match args[1:] {
    ["run", goal] => println(@moontown.render_goal_run(goal))
    ["run", "--book", book_id, goal] =>
      println(@moontown.render_goal_run(goal, book_id=Some(book_id)))
    ["supervise"] => println(@moontown.supervise_saved_town())
    ["status"] => println(@moontown.render_saved_town_status())
    ["daemon", "tick"] => println(@moontown.daemon_tick_saved_town())
    ["daemon", "start"] => println(@moontown.daemon_start_saved_town())
    ["daemon", "stop"] => println(@moontown.daemon_stop_saved_town())
    ["daemon", "doctor"] => println(@moontown.daemon_doctor_saved_town())
    ["daemon", "supervise", "--worker"] =>
      println(@moontown.daemon_supervise_saved_town())
    ["daemon", "supervise", "--once"] =>
      println(@moontown.daemon_supervise_saved_town(max_checks=1, sleep_ms=0))
    ["daemon", "run", "--once"] =>
      println(@moontown.daemon_run_saved_town(max_ticks=1, sleep_ms=0))
    ["daemon", "run", "--worker"] =>
      println(@moontown.daemon_run_saved_town(preserve_supervisor=true))
    ["daemon", "run"] => println(@moontown.daemon_run_saved_town())
    ["cookbook", "bootstrap"] =>
      println(@moontown.bootstrap_moontown_cookbook())
    ["cookbook", "doctor"] => println(@moontown.bootstrap_moontown_cookbook())
    ["cookbook", "status"] =>
      println(@moontown.render_moontown_cookbook_status())
    ["planbook", "bootstrap"] =>
      println(@moontown.bootstrap_moontown_planbook())
    ["planbook", "status"] =>
      println(@moontown.render_moontown_planbook_status())
    ["course", "wenyu-game-design", "bootstrap"] =>
      println(@moontown.bootstrap_wenyu_game_design_course_book())
    ["course", "wenyu-game-design", "status"] =>
      println(@moontown.render_wenyu_game_design_course_status())
    ["books", "quality"] => println(@moontown.render_book_quality())
    ["books", "bootstrap"] =>
      println(@moontown.bootstrap_registered_book_workspaces())
    ["books", "doctor"] => println(@moontown.write_book_quality_audit())
    ["books", "ai-review-packets"] =>
      println(@moontown.write_book_quality_review_packets())
    ["civic", "bootstrap"] =>
      println(@moontown.bootstrap_wenyu_civic_workspaces())
    ["civic", "status"] => println(@moontown.render_wenyu_civic_status())
    ["civic", "doctor"] => println(@moontown.write_wenyu_civic_status())
    ["civic", "protocols", "bootstrap"] =>
      println(@moontown.bootstrap_wenyu_building_protocols())
    ["civic", "protocols", "status"] =>
      println(@moontown.render_wenyu_building_protocol_status())
    ["civic", "protocols", "doctor"] =>
      println(@moontown.write_wenyu_building_protocol_status())
    ["civic", "protocols", "patterns"] =>
      println(@moontown.render_civic_communication_patterns())
    ["civic", "protocols", "pattern-install", template_path] =>
      println(@moontown.install_civic_pattern_scenario_file(template_path))
    ["civic", "protocols", "pattern-manifest", manifest_path] =>
      println(@moontown.install_civic_pattern_scenario_manifest(manifest_path))
    ["civic", "protocols", "pattern-template", template_path] =>
      println(@moontown.bootstrap_civic_salon_scenario_file(template_path))
    ["civic", "protocols", "schedules", "tick"] =>
      println(@moontown.run_due_civic_salons())
    ["civic", "protocols", "schedules", "status"] =>
      println(@moontown.render_civic_salon_schedule_status())
    ["integration", "final", "install"] =>
      println(@moontown.install_wenyu_final_integration())
    ["integration", "final", "install", manifest_path] =>
      println(@moontown.install_wenyu_final_integration(manifest_path~))
    ["integration", "final", "status"] =>
      println(@moontown.render_wenyu_final_integration_status())
    ["integration", "final", "status", manifest_path] =>
      println(@moontown.render_wenyu_final_integration_status(manifest_path~))
    ["run", .. rest] =>
      println(@moontown.render_goal_run(rest.to_owned().join(" ")))
    _ => println(@moontown.load_or_create_demo_dashboard())
  }
}
