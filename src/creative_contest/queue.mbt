///|
/// Recent execution cost plus the worker's one-second scheduling interval.
/// This estimates time, never reserves compute or exposes other participants.
fn queue_service_ms(state : State) -> UInt64 {
  let durations = state.generations.filter_map(job => {
    if job.state == "completed" &&
      job.started_ms > 0UL &&
      job.finished_ms > job.started_ms &&
      job.finished_ms - job.started_ms <= 300000UL {
      Some(job.finished_ms - job.started_ms)
    } else {
      None
    }
  })
  if durations.is_empty() {
    return 10000UL
  }
  let recent = durations[(durations.length() - 10).max(0):].to_array()
  recent.sort()
  let median = recent[recent.length() / 2]
  (if median < 1000UL { 1000UL } else { median }) + 1000UL
}

///|
fn queue_remaining(
  execution : UInt64,
  now : UInt64,
  started : UInt64,
) -> UInt64 {
  if now <= started {
    execution
  } else if now - started >= execution {
    0UL
  } else {
    execution - (now - started)
  }
}

///|
fn generation_queue(
  job : Generation,
  state : State,
  config : Config,
  now : UInt64,
) -> Json {
  if !["queued", "running", "needs_reconcile"].contains(job.state) {
    return Json::null()
  }
  let service = queue_service_ms(state)
  let execution = service - 1000UL
  let running = state.generations.filter(item => item.state == "running")
  let mut queued_before = 0
  for item in state.generations {
    if item.id == job.id {
      break
    }
    if item.state == "queued" {
      queued_before += 1
    }
  }
  let ahead = if job.state == "queued" {
    queued_before + running.length()
  } else {
    0
  }
  let uncertain = state.generations.any(item => item.state == "needs_reconcile")
  let closed = job.state == "queued" && now >= config.brief.deadline_ms
  let delayed = running.any(item => {
    now > item.started_ms && now - item.started_ms > execution + 5000UL
  })
  let blocked = uncertain || closed
  let waiting = running.fold(init=0UL, (sum, item) => {
      sum + queue_remaining(execution, now, item.started_ms)
    }) +
    queued_before.to_uint64() * service +
    1000UL
  let remaining = if job.state == "running" {
    queue_remaining(execution, now, job.started_ms)
  } else {
    waiting + execution
  }
  {
    "ahead": ahead,
    "position": if job.state == "queued" {
      ahead + 1
    } else {
      0
    },
    "status": if blocked {
      "blocked"
    } else if delayed {
      "delayed"
    } else {
      job.state
    },
    "reason": if uncertain {
      "reconcile"
    } else if closed {
      "closed"
    } else {
      ""
    },
    "estimated_start_ms": if !blocked && !delayed && job.state == "queued" {
      Json::string((now + waiting).to_string())
    } else {
      Json::null()
    },
    "estimated_ready_ms": if !blocked && !delayed {
      Json::string((now + remaining).to_string())
    } else {
      Json::null()
    },
    "sample_count": state.generations
    .filter(item => {
      item.state == "completed" &&
      item.started_ms > 0UL &&
      item.finished_ms > item.started_ms &&
      item.finished_ms - item.started_ms <= 300000UL
    })
    .length()
    .min(10),
  }
}
