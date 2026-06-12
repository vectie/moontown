///|
pub fn demo_state_from_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @core.TownState {
  @town_runtime.demo_state_from_catalog(catalog)
}

///|
pub fn[Provider : @core.BookProvider] demo_state_with_provider(
  provider : Provider,
) -> @core.TownState {
  @town_runtime.demo_state_with_provider(provider)
}

///|
pub fn demo_mayor() -> @roles.Mayor {
  @town_runtime.demo_mayor()
}

///|
pub fn demo_state() -> @core.TownState {
  @town_runtime.demo_state()
}

///|
pub fn demo_dashboard() -> String {
  @town_runtime.demo_dashboard()
}

///|
pub async fn load_or_create_demo_state(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  @town_runtime.load_or_create_demo_state(path~, book_catalog_path~)
}

///|
pub async fn load_or_create_modeled_demo_state(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  @town_runtime.load_or_create_modeled_demo_state(path~, book_catalog_path~)
}

///|
pub async fn[Provider : @core.BookProvider] load_or_create_demo_state_with_provider(
  provider : Provider,
  path? : String = @storage.default_snapshot_path(),
) -> @core.TownState {
  @town_runtime.load_or_create_demo_state_with_provider(provider, path~)
}

///|
pub async fn load_or_create_demo_dashboard(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  @town_runtime.load_or_create_demo_dashboard(path~, book_catalog_path~)
}

///|
pub fn render_state_dashboard(state : @core.TownState) -> String {
  @town_runtime.render_state_dashboard(state)
}

///|
pub async fn run_goal(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 3,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  @town_runtime.run_goal(
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
}

///|
pub async fn render_goal_run(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 3,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  @town_runtime.render_goal_run(
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
}

///|
pub async fn supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  @town_runtime.supervise_saved_town(snapshot_path~, book_catalog_path~)
}

///|
pub async fn daemon_tick_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  respect_runtime_lock? : Bool = true,
) -> String {
  @town_runtime.daemon_tick_saved_town(
    snapshot_path~,
    book_catalog_path~,
    respect_runtime_lock~,
  )
}

///|
pub async fn daemon_supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  command? : String = "",
  max_checks? : Int = 0,
  sleep_ms? : Int = 30000,
  stale_after_ms? : UInt64 = 120000,
) -> String {
  @town_runtime.daemon_supervise_saved_town(
    snapshot_path~,
    command~,
    max_checks~,
    sleep_ms~,
    stale_after_ms~,
  )
}

///|
pub async fn daemon_run_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  max_ticks? : Int = 0,
  sleep_ms? : Int = 1800000,
  preserve_supervisor? : Bool = false,
  inline_under_supervisor? : Bool = false,
) -> String {
  @town_runtime.daemon_run_saved_town(
    snapshot_path~,
    book_catalog_path~,
    max_ticks~,
    sleep_ms~,
    preserve_supervisor~,
    inline_under_supervisor~,
  )
}
