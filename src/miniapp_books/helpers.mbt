///|
fn miniapp_book_accept(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  book_id : String,
  run_id : String?,
  message : String,
) -> MiniappBookChange {
  { ok: true, snapshot, message, building_id, book_id, run_id }
}

///|
fn miniapp_book_reject(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  book_id : String,
  run_id : String?,
  message : String,
) -> MiniappBookChange {
  { ok: false, snapshot, message, building_id, book_id, run_id }
}

///|
fn miniapp_book_building_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> @miniapp_contracts.MiniappBuilding? {
  for building in snapshot.buildings {
    if building.id == building_id {
      return Some(building)
    }
  }
  None
}

///|
fn miniapp_book_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  book_id : String,
) -> @miniapp_contracts.MiniappBookSummary? {
  for book in snapshot.books {
    if book.id == book_id {
      return Some(book)
    }
  }
  None
}

///|
fn miniapp_thread_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  thread_id : String,
) -> @miniapp_contracts.MiniappThread? {
  for thread in snapshot.threads {
    if thread.id == thread_id {
      return Some(thread)
    }
  }
  None
}

///|
fn miniapp_run_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  run_id : String,
) -> @miniapp_contracts.MiniappRun? {
  for run in snapshot.runs {
    if run.id == run_id {
      return Some(run)
    }
  }
  None
}

///|
fn miniapp_run_count_for_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> Int {
  let mut count = 0
  for run in snapshot.runs {
    if run.building_id == building_id {
      count += 1
    }
  }
  count
}

///|
fn miniapp_replace_book(
  books : Array[@miniapp_contracts.MiniappBookSummary],
  next : @miniapp_contracts.MiniappBookSummary,
) -> Array[@miniapp_contracts.MiniappBookSummary] {
  books.map(book => if book.id == next.id { next } else { book })
}

///|
fn miniapp_replace_thread(
  threads : Array[@miniapp_contracts.MiniappThread],
  next : @miniapp_contracts.MiniappThread,
) -> Array[@miniapp_contracts.MiniappThread] {
  let replaced = threads.map(thread => {
    if thread.id == next.id {
      next
    } else {
      thread
    }
  })
  for thread in threads {
    if thread.id == next.id {
      return replaced
    }
  }
  replaced + [next]
}

///|
fn miniapp_replace_run(
  runs : Array[@miniapp_contracts.MiniappRun],
  next : @miniapp_contracts.MiniappRun,
) -> Array[@miniapp_contracts.MiniappRun] {
  runs.map(run => if run.id == next.id { next } else { run })
}
