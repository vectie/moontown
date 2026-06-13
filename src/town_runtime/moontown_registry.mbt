///|
fn register_town_books(
  state : @core.TownState,
  books : Array[@core.BookRef],
) -> Unit {
  for book in books {
    register_book_if_missing(state, book)
  }
}

///|
fn register_town_workers(state : @core.TownState) -> Unit {
  for worker in @roles.town_workers_for_books(state.books) {
    register_worker_if_missing(state, worker)
  }
}

///|
fn register_book_if_missing(
  state : @core.TownState,
  book : @core.BookRef,
) -> Unit {
  for existing in state.books {
    if existing.id == book.id {
      return
    }
  }
  state.register_book(book)
}

///|
fn register_worker_if_missing(
  state : @core.TownState,
  worker : @core.WorkerRef,
) -> Unit {
  for existing in state.workers {
    if existing.id == worker.id {
      return
    }
  }
  state.register_worker(worker)
}
