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
    ["run", .. rest] =>
      println(@moontown.render_goal_run(rest.to_array().join(" ")))
    _ => println(@moontown.load_or_create_demo_dashboard())
  }
}
