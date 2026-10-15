///|
/// The desktop owner can run explicit user schedules without starting the
/// broader town simulation. The installed service opts in through its launch
/// configuration and uses the same persisted reservations as the town daemon.
async fn run_desktop_code_schedule_clock() -> Unit {
  let mut previous = ""
  for ;; {
    let now = (@env.now() / 1000UL).reinterpret_as_int64()
    let status = @code_schedules.run_due_code_schedules(
      now,
      @moonbook.default_catalog_path(),
    ) catch {
      error => "Schedule clock retrying: \{error}"
    }
    if status != previous {
      println(status)
      previous = status
    }
    let heartbeat : Json = {
      "schema": "moontown.desktop-schedule-runner.v1",
      "last_tick_at": now,
      "interval_seconds": 5,
      "status": status,
    }
    @support.write_text_file(
      state_root() + "/code-schedules/runner.json",
      heartbeat.stringify(),
    ) catch {
      error => println("Schedule heartbeat: \{error}")
    }
    @async.sleep(5000)
  }
}
