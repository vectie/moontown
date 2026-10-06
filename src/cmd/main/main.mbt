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
    ["status"] => @runtime_status.render_saved_town_status()
    ["runtime"] | ["runtime", "status"] =>
      @runtime_status.render_saved_town_status()
    ["live", .. rest] => render_live_command(rest.to_owned())
    ["daemon", .. rest] => render_daemon_command(rest.to_owned())
    ["cookbook", .. rest] => render_cookbook_command(rest.to_owned())
    ["planbook", .. rest] => render_planbook_command(rest.to_owned())
    ["editor-pipeline", .. rest] =>
      render_editor_pipeline_command(rest.to_owned())
    ["course", .. rest] => render_course_command(rest.to_owned())
    ["books", .. rest] => render_books_command(rest.to_owned())
    ["native-work", "list"] => @native_work.render_status()
    ["native-work", "show", id] => {
      let state = @native_work.load()
      match state.work.iter().find_first(work => work.id == id) {
        Some(work) => @native_work.status(work).to_json().stringify(indent=2)
        None => "Native work not found: " + id
      }
    }
    ["native-work", "sync", id] => {
      let work = @native_work.sync(id, @env.now(), force=true)
      @build_pipeline_runtime.apply_wenyu_native_work_result(work)
      @native_work.summary(work)
    }
    ["native-work", "refresh", id] => {
      let state = @native_work.load()
      @native_work.summary(@native_work.refresh(id, state.revision, @env.now()))
    }
    ["native-work", "cancel", id] => {
      let state = @native_work.load()
      @native_work.summary(@native_work.cancel(id, state.revision, @env.now()))
    }
    ["native-work", "supersede", id] => {
      let state = @native_work.load()
      @native_work.summary(@native_work.supersede(id, state.revision))
    }
    ["knowledge", .. rest] => render_knowledge_command(rest.to_owned())
    ["moonclaw", .. rest] => render_moonclaw_command(rest.to_owned())
    ["civic", .. rest] => render_civic_command(rest.to_owned())
    ["commission", "evaluate", input_path, output_path] =>
      @commission_runtime.evaluate_file(input_path, output_path)
    ["emergence", "evaluate", input_path, output_path] =>
      @emergence_runtime.evaluate_file(input_path, output_path)
    ["miniapp", .. rest] => render_miniapp_command(rest.to_owned())
    ["integration", .. rest] => render_integration_command(rest.to_owned())
    _ => @moontown.load_or_create_saved_dashboard()
  }
}
