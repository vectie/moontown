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
    ["run", .. rest] =>
      println(@moontown.render_goal_run(rest.to_array().join(" ")))
    _ => println(@moontown.load_or_create_demo_dashboard())
  }
}
