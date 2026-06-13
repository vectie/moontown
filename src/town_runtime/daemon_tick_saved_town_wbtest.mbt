///|
test "daemon tick phase log line has stable searchable shape" {
  assert_eq(
    @daemon_runtime.daemon_tick_log_line("standing-goals", 42),
    "tick phase=standing-goals sequence=42",
  )
}

///|
test "daemon tick paths keep runtime files beside snapshot" {
  let paths = @daemon_runtime.daemon_tick_paths(
    "/tmp/moontown-daemon-tick-paths/town.json",
  )
  assert_eq(paths.daemon_path, "/tmp/moontown-daemon-tick-paths/daemon.json")
  assert_eq(paths.log_path, "/tmp/moontown-daemon-tick-paths/daemon.log")
  assert_eq(
    paths.goal_path,
    "/tmp/moontown-daemon-tick-paths/standing-goals.json",
  )
}

///|
test "daemon planbook duplicate repair message is stable" {
  assert_eq(
    @planbook_runtime.planbook_daemon_repair_duplicate_message(),
    "PlanBook repair already active; daemon did not create a duplicate repair task.",
  )
}

///|
async test "daemon tick context prepares isolated first tick" {
  let snapshot_path = "/tmp/moontown-daemon-tick-context/town.json"
  let catalog_path = "/tmp/moontown-daemon-tick-context/books.json"
  let context = prepare_daemon_tick_context(snapshot_path, catalog_path)
  assert_eq(
    context.paths.daemon_path,
    "/tmp/moontown-daemon-tick-context/daemon.json",
  )
  assert_eq(
    context.paths.goal_path,
    "/tmp/moontown-daemon-tick-context/standing-goals.json",
  )
  assert_eq(context.next_tick_sequence, context.daemon.tick_sequence + 1)
}

///|
async test "daemon context phase logger uses context sequence" {
  let snapshot_path = "/tmp/moontown-daemon-context-phase-log/town.json"
  let catalog_path = "/tmp/moontown-daemon-context-phase-log/books.json"
  let context = prepare_daemon_tick_context(snapshot_path, catalog_path)
  append_daemon_context_phase_log(context, "custom-phase")
  assert_true(
    @support.read_text_or_empty(context.paths.log_path).contains(
      @daemon_runtime.daemon_tick_log_line(
        "custom-phase",
        context.next_tick_sequence,
      ),
    ),
  )
}
