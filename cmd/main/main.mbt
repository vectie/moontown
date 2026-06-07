///|
async fn main {
  let args = @env.args()
  println(render_cli_command(args[1:].to_owned()))
}

///|
async fn render_cli_command(args : Array[String]) -> String {
  match args {
    ["run", .. rest] => render_run_command(rest.to_owned())
    ["supervise"] => @moontown.supervise_saved_town()
    ["status"] => @moontown.render_saved_town_status()
    ["runtime"] | ["runtime", "status"] => @moontown.render_saved_town_status()
    ["live", .. rest] => render_live_command(rest.to_owned())
    ["daemon", .. rest] => render_daemon_command(rest.to_owned())
    ["cookbook", .. rest] => render_cookbook_command(rest.to_owned())
    ["planbook", .. rest] => render_planbook_command(rest.to_owned())
    ["editor-pipeline", .. rest] =>
      render_editor_pipeline_command(rest.to_owned())
    ["course", .. rest] => render_course_command(rest.to_owned())
    ["books", .. rest] => render_books_command(rest.to_owned())
    ["moonclaw", .. rest] => render_moonclaw_command(rest.to_owned())
    ["civic", .. rest] => render_civic_command(rest.to_owned())
    ["integration", .. rest] => render_integration_command(rest.to_owned())
    _ => @moontown.load_or_create_demo_dashboard()
  }
}
