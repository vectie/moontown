///|
async fn build_live_state_from_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  let mayor = demo_mayor()
  register_demo_books(state, @moonbook.catalog_to_book_refs(catalog))
  register_demo_workers(state)
  for entry in catalog {
    let batch = @moonbook.produce_task_batch(entry, goal_for_book(entry)) catch {
      error => {
        let task = fixture_book_tasks(entry)[0]
        let failed_task = to_town_task(
          entry,
          task,
          @core.TaskExecutionStatus::Failed,
        )
        state.enqueue_task(failed_task)
        state.register_execution(
          failed_execution_record(
            entry,
            task,
            "MoonBook task planning failed for \{entry.id}: \{error}",
          ),
        )
        continue
      }
    }
    let limit = desired_task_count(entry)
    let mut emitted = 0
    for raw_task in batch.tasks {
      if emitted >= limit {
        break
      }
      let task = town_scoped_book_task(entry, raw_task)
      if @core.live_external_execution_count(state) >=
        @core.max_live_external_executions() {
        let queued_execution = queued_goal_execution_record(
          entry,
          task,
          supervision_tick(state),
          "Mayor queued \{task.id} during catalog bootstrap because live external execution count reached \{@core.max_live_external_executions()}; the supervision loop will launch it when capacity is available.",
        )
        state.enqueue_task(
          to_town_task(entry, task, @core.TaskExecutionStatus::PacketReady),
        )
        state.register_execution(queued_execution)
        emitted += 1
        continue
      }
      let execution = live_execution_record_for_book_task(mayor, entry, task) catch {
        error =>
          failed_execution_record(
            entry,
            task,
            "Runtime handoff failed for \{entry.id} / \{task.id}: \{error}",
          )
      }
      let town_task = to_town_task(entry, task, execution.status)
      state.enqueue_task(town_task)
      state.register_execution(execution)
      emitted += 1
    }
  }
  append_routes_and_events(state)
  state
}

///|
pub fn demo_state_from_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  register_demo_books(state, @moonbook.catalog_to_book_refs(catalog))
  register_demo_workers(state)
  seed_catalog_tasks(state, catalog)
  append_routes_and_events(state)
  state
}

///|
pub fn[Provider : @core.BookProvider] demo_state_with_provider(
  provider : Provider,
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  register_demo_books(state, provider.books())
  register_demo_workers(state)
  seed_provider_overview_tasks(state)
  append_routes_and_events(state)
  state
}

///|
pub fn demo_mayor() -> @roles.Mayor {
  @roles.Mayor::new()
}

///|
pub fn demo_state() -> @core.TownState {
  demo_state_from_catalog(@moonbook.default_catalog())
}

///|
pub fn demo_dashboard() -> String {
  render_state_dashboard(demo_state())
}

///|
pub async fn load_or_create_demo_state(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  match @storage.load_snapshot_file(path) {
    Some(snapshot) if !snapshot_requires_refresh(snapshot) => snapshot.town
    _ => {
      let town = build_live_state_from_catalog(catalog)
      @storage.save_snapshot_file(path, @storage.snapshot_of(town))
      town
    }
  }
}

///|
pub async fn load_or_create_modeled_demo_state(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let snapshot = @storage.load_or_create_snapshot(path, () => {
    demo_state_from_catalog(catalog)
  })
  snapshot.town
}

///|
pub async fn[Provider : @core.BookProvider] load_or_create_demo_state_with_provider(
  provider : Provider,
  path? : String = @storage.default_snapshot_path(),
) -> @core.TownState {
  let snapshot = @storage.load_or_create_snapshot(path, () => {
    demo_state_with_provider(provider)
  })
  snapshot.town
}

///|
pub async fn load_or_create_demo_dashboard(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let state = load_or_create_demo_state(path~, book_catalog_path~)
  render_state_dashboard(state)
}
