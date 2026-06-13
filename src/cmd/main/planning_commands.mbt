///|
async fn render_cookbook_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] | ["doctor"] =>
      @cookbook_runtime.bootstrap_moontown_cookbook()
    ["status"] => @cookbook_runtime.render_moontown_cookbook_status()
    _ => @moontown.load_or_create_saved_dashboard()
  }
}

///|
async fn render_planbook_command(args : Array[String]) -> String {
  match args {
    ["bootstrap"] => @planbook_runtime.bootstrap_moontown_planbook()
    ["status"] => @planbook_runtime.render_moontown_planbook_status()
    ["doctor"] => @planbook_runtime.write_moontown_planbook_autonomy()
    ["validation"] | ["validate"] =>
      @planbook_runtime.write_moontown_planbook_validation_evidence()
    ["autonomy"] => @planbook_runtime.render_moontown_planbook_autonomy_status()
    ["repair"] => @planbook_runtime.write_moontown_planbook_repair_task()
    ["repair", "--dispatch"] =>
      @planbook_runtime.write_moontown_planbook_repair_task(dispatch=true)
    ["repair", "status"] =>
      @planbook_runtime.render_moontown_planbook_repair_status()
    _ => @moontown.load_or_create_saved_dashboard()
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
    _ => @moontown.load_or_create_saved_dashboard()
  }
}

///|
async fn render_course_command(args : Array[String]) -> String {
  match args {
    ["wenyu-game-design", "bootstrap"] =>
      @course_book_runtime.bootstrap_wenyu_game_design_course_book()
    ["wenyu-game-design", "status"] =>
      @course_book_runtime.render_wenyu_game_design_course_status()
    _ => @moontown.load_or_create_saved_dashboard()
  }
}
