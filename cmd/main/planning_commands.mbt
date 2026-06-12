///|
async fn render_cookbook_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] | ["doctor"] => @moontown.bootstrap_moontown_cookbook()
    ["status"] => @moontown.render_moontown_cookbook_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_planbook_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @moontown.bootstrap_moontown_planbook()
    ["status"] => @moontown.render_moontown_planbook_status()
    ["doctor"] => @moontown.write_moontown_planbook_autonomy()
    ["validation"] | ["validate"] =>
      @moontown.write_moontown_planbook_validation_evidence()
    ["autonomy"] => @moontown.render_moontown_planbook_autonomy_status()
    ["repair"] => @moontown.write_moontown_planbook_repair_task()
    ["repair", "--dispatch"] =>
      @moontown.write_moontown_planbook_repair_task(dispatch=true)
    ["repair", "status"] => @moontown.render_moontown_planbook_repair_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_editor_pipeline_command(args : Array[String]) -> String {
  match args {
    [] | ["status"] | ["refresh"] =>
      @editor_runtime.render_editor_pipeline_status()
    ["feature-select"] => @editor_runtime.write_editor_feature_selection_task()
    ["feature-select", "--dispatch"] =>
      @editor_runtime.write_editor_feature_selection_task(dispatch=true)
    ["feature-select", "status"] =>
      @editor_runtime.render_editor_feature_selection_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}

///|
async fn render_course_command(args : Array[String]) -> String {
  match args {
    ["wenyu-game-design", "bootstrap"] =>
      @moontown.bootstrap_wenyu_game_design_course_book()
    ["wenyu-game-design", "status"] =>
      @moontown.render_wenyu_game_design_course_status()
    _ => @moontown.load_or_create_demo_dashboard()
  }
}
