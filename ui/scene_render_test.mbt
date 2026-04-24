///|
fn sample_dashboard_model() -> @ui.DashboardModel {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  state.register_book(
    @core.BookRef::new(
      id="coding",
      name="Moonbook / Coding",
      purpose="Harness engineering for source work.",
      workspace_root="/workspace/coding",
      memory_scope=@core.MemoryScope::BookPrivate,
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Hound",
      book_id="coding",
      role=@core.WorkerRole::Harness,
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-town-layer",
      book_id="coding",
      title="Implement town orchestration layer",
      prompt="Route coding work to the right claw worker.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Harness),
    ),
  )
  @ui.build_dashboard(state, @health.inspect_town(state))
}

///|
test "scene render model keeps background and node geometry" {
  let scene = @ui.build_scene_render(sample_dashboard_model())
  assert_eq(scene.width, 1280)
  assert_eq(scene.height, 720)
  assert_eq(scene.background_path, "backgrounds/town-square.svg")
  assert_true(scene.nodes.any(fn(node) { node.key == "city-hall" }))
  assert_true(
    scene.nodes.any(fn(node) { node.class_name == "node-book-house" }),
  )
}

///|
test "scene html includes positioned nodes and assets" {
  let html = @ui.render_scene_html(
    @ui.build_scene_render(sample_dashboard_model()),
  )
  assert_true(html.contains("class=\"moontown-scene\""))
  assert_true(html.contains("scene-background"))
  assert_true(html.contains("data-node=\"city-hall\""))
  assert_true(html.contains("left:500px;top:80px;width:280px;height:180px;"))
  assert_true(html.contains("buildings/city-hall.svg"))
  assert_true(html.contains("node-book-house"))
}

///|
test "scene render supports dynamic research books" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  for
    book in [
      @core.BookRef::new(
        id="research-moontown",
        name="Moonbook / Research / Moontown",
        purpose="Research lane for Moontown.",
        workspace_root="/workspace/research-moontown",
      ),
      @core.BookRef::new(
        id="research-moonbook",
        name="Moonbook / Research / MoonBook",
        purpose="Research lane for MoonBook.",
        workspace_root="/workspace/research-moonbook",
      ),
      @core.BookRef::new(
        id="research-moonclaw",
        name="Moonbook / Research / MoonClaw",
        purpose="Research lane for MoonClaw.",
        workspace_root="/workspace/research-moonclaw",
      ),
    ] {
    state.register_book(book)
  }
  let html = @ui.render_scene_html(
    @ui.build_scene_render(
      @ui.build_dashboard(state, @health.inspect_town(state)),
    ),
  )
  assert_true(html.contains("data-node=\"book-research-moontown\""))
  assert_true(html.contains("data-node=\"book-research-moonbook\""))
  assert_true(html.contains("data-node=\"book-research-moonclaw\""))
}
