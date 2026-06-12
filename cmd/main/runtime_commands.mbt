///|
async fn render_run_command(args : Array[String]) -> String {
  match args {
    ["--book", book_id, goal] =>
      @moontown.render_goal_run(goal, book_id=Some(book_id))
    [goal] => @moontown.render_goal_run(goal)
    [.. rest] => @moontown.render_goal_run(rest.to_owned().join(" "))
  }
}

///|
async fn render_live_command(args : Array[String]) -> String {
  match args {
    ["status"] => @live_autonomy_runtime.render_live_autonomy_status()
    ["refresh"] => @live_autonomy_runtime.refresh_live_autonomy_spine()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_daemon_command(args : Array[String]) -> String {
  match args {
    [] | ["status"] => @moontown.render_saved_town_status()
    ["tick"] => @moontown.daemon_tick_saved_town()
    ["start"] => @daemon_runtime.daemon_start_saved_town()
    ["restart"] =>
      @daemon_runtime.write_daemon_restart_request(reason="manual request")
    ["restart", reason] => @daemon_runtime.write_daemon_restart_request(reason~)
    ["stop"] => @daemon_runtime.daemon_stop_saved_town()
    ["doctor"] => @daemon_runtime.daemon_doctor_saved_town()
    ["supervise", "--worker"] => @moontown.daemon_supervise_saved_town()
    ["supervise", "--once"] =>
      @moontown.daemon_supervise_saved_town(max_checks=1, sleep_ms=0)
    ["run", "--once"] =>
      @moontown.daemon_run_saved_town(max_ticks=1, sleep_ms=0)
    ["run", "--worker"] =>
      @moontown.daemon_run_saved_town(preserve_supervisor=true)
    ["run"] => @moontown.daemon_run_saved_town()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}
