///|
fn sample_dashboard_model() -> @ui.DashboardModel {
  let state = scene_render_test_state()
  scene_render_register_book(state)
  scene_render_register_harness_worker(state)
  scene_render_enqueue_task(
    state,
    id="task-town-layer",
    title="Implement town orchestration layer",
    prompt="Route coding work to the right claw worker.",
    required_role=Some(Harness),
  )
  scene_render_dashboard(state)
}

///|
test "scene render model keeps background and node geometry" {
  let scene = @ui.build_scene_render(sample_dashboard_model())
  assert_eq(scene.width, 1280)
  assert_eq(scene.height, 720)
  assert_eq(scene.background_path, "backgrounds/town-square.svg?v=solid-tiles")
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
  assert_true(html.contains("left:610px;top:100px;width:280px;height:180px;"))
  assert_true(html.contains("tilemap/buildings/city_hall_base.png"))
  assert_true(html.contains("node-book-house"))
}

///|
test "dashboard text render keeps map and section output" {
  let text = @ui.render_dashboard(sample_dashboard_model())
  assert_true(text.contains("Dashboard / Moontown / Moonrise"))
  assert_true(text.contains("## Town Map"))
  assert_true(
    text.contains(
      "- scene: 1280x720 / backgrounds/town-square.svg?v=solid-tiles",
    ),
  )
  assert_true(text.contains("frame: 610,100 280x180 / kind=CityHall"))
  assert_true(text.contains("assets: tilemap/buildings/city_hall_base.png"))
  assert_true(text.contains("## Books"))
  assert_true(text.contains("- coding: /workspace/coding"))
  assert_true(text.contains("## Workers"))
  assert_true(text.contains("- claw-harness: Idle"))
  assert_true(text.contains("## Tasks"))
  assert_true(text.contains("- task-town-layer:"))
  assert_true(text.contains("stage=Planning"))
  assert_true(text.contains("## Pipeline"))
  assert_true(
    text.contains("- coding / Planning / task-town-layer / not-started"),
  )
  assert_true(text.contains("## Executions"))
}

///|
test "dashboard book house activity summarizes counts and highest priority stage" {
  let state = scene_render_test_state()
  scene_render_register_book(state)
  scene_render_register_harness_worker(state)
  scene_render_enqueue_task(
    state,
    id="task-bootstrap",
    title="Bootstrap sources",
    prompt="Bootstrap source population.",
  )
  scene_render_enqueue_task(
    state,
    id="task-research",
    title="Research pipeline",
    prompt="Research and analyze the result.",
    domain=Research,
  )
  scene_render_register_execution(
    state,
    task_id="task-research",
    packet_id="packet-research",
    status=Running,
    summary="running synthesis",
    output_contract="report",
  )
  let text = @ui.render_dashboard(scene_render_dashboard(state))
  assert_true(text.contains("workers: 1"))
  assert_true(text.contains("tasks: 2"))
  assert_true(text.contains("executions: 1"))
  assert_true(text.contains("active stage: Bootstrap"))
}

///|
test "dashboard stage rules classify watch tasks but preserve bootstrap priority" {
  let state = scene_render_test_state()
  scene_render_register_book(state)
  scene_render_enqueue_task(
    state,
    id="standing-watch-opc",
    title="Standing watch OPC",
    prompt="Check watcher sources.",
    domain=Research,
  )
  scene_render_enqueue_task(
    state,
    id="task-bootstrap",
    title="Bootstrap sources",
    prompt="Bootstrap source population.",
  )
  let text = @ui.render_dashboard(scene_render_dashboard(state))
  assert_true(
    text.contains("- coding / Watch / standing-watch-opc / not-started"),
  )
  assert_true(text.contains("active stage: Bootstrap"))
}

///|
test "dashboard city hall summarizes execution lifecycle buckets" {
  let state = scene_render_test_state()
  scene_render_register_execution(
    state,
    task_id="task-packet",
    packet_id="packet-ready",
    status=PacketReady,
    summary="packet ready",
    output_contract="packet",
  )
  scene_render_register_execution(
    state,
    task_id="task-imported",
    packet_id="packet-imported",
    status=ProposalImported,
    summary="proposal imported",
    output_contract="proposal",
  )
  scene_render_register_execution(
    state,
    task_id="task-running",
    packet_id="packet-running",
    status=Running,
    summary="running work",
    output_contract="run",
  )
  scene_render_register_execution(
    state,
    task_id="task-review",
    packet_id="packet-review",
    status=ReviewQueued,
    summary="review queued",
    output_contract="review",
  )
  scene_render_register_execution(
    state,
    task_id="task-complete",
    packet_id="packet-complete",
    status=Completed,
    summary="done",
    output_contract="done",
  )
  let text = @ui.render_dashboard(scene_render_dashboard(state))
  assert_true(text.contains("packets: 1 ready"))
  assert_true(text.contains("imports: 1 imported"))
  assert_true(text.contains("runs: 2 active lifecycle records"))
}

///|
test "dashboard map hides mayor books without shifting visible book slots" {
  let state = scene_render_test_state()
  scene_render_register_book(
    state,
    id="mayor",
    name="Mayor",
    purpose="Town-level reasoning.",
    workspace_root="/workspace/mayor",
  )
  scene_render_register_book(
    state,
    id="research-opc",
    name="Research / OPC",
    purpose="Research one-person company updates.",
    workspace_root="/workspace/research-opc",
  )
  let scene = @ui.build_scene_render(scene_render_dashboard(state))
  assert_true(!scene.nodes.any(fn(node) { node.key == "book-mayor" }))
  assert_true(
    scene.nodes.any(fn(node) {
      node.key == "book-research-opc" && node.x == 82 && node.y == 356
    }),
  )
}

///|
test "scene render supports dynamic research books" {
  let state = scene_render_test_state()
  scene_render_register_book(
    state,
    id="research-moontown",
    name="Moonbook / Research / Moontown",
    purpose="Research lane for Moontown.",
    workspace_root="/workspace/research-moontown",
  )
  scene_render_register_book(
    state,
    id="research-moonbook",
    name="Moonbook / Research / MoonBook",
    purpose="Research lane for MoonBook.",
    workspace_root="/workspace/research-moonbook",
  )
  scene_render_register_book(
    state,
    id="research-moonclaw",
    name="Moonbook / Research / MoonClaw",
    purpose="Research lane for MoonClaw.",
    workspace_root="/workspace/research-moonclaw",
  )
  let html = @ui.render_scene_html(
    @ui.build_scene_render(scene_render_dashboard(state)),
  )
  assert_true(html.contains("data-node=\"book-research-moontown\""))
  assert_true(html.contains("data-node=\"book-research-moonbook\""))
  assert_true(html.contains("data-node=\"book-research-moonclaw\""))
}
