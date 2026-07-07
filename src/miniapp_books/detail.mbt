///|
pub fn miniapp_project_building_book_detail(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building_id : String,
  support_book_ids? : Array[String] = [],
) -> MiniappBuildingBookDetail? {
  match miniapp_book_building_by_id(snapshot, building_id) {
    None => None
    Some(building) =>
      if !@miniapp_projection.miniapp_can_view_building(viewer, building) {
        None
      } else {
        match miniapp_book_by_id(snapshot, building.primary_book_id) {
          None => None
          Some(book) => {
            let can_accept = @miniapp_projection.miniapp_can_edit_building(
                viewer, building,
              ) ||
              @miniapp_projection.miniapp_viewer_can_publish(viewer)
            let binding = miniapp_building_book_binding(
              building,
              support_book_ids~,
            )
            Some({
              building_id: building.id,
              title: building.title,
              summary: miniapp_safe_book_summary(building, book),
              primary_book: miniapp_safe_book_projection(building, book),
              support_books: miniapp_support_books(snapshot, support_book_ids),
              ledgers: if can_accept {
                Some(binding.ledgers)
              } else {
                None
              },
              can_query: true,
              can_accept_memory: can_accept,
              recent_run_count: miniapp_run_count_for_building(
                snapshot,
                building.id,
              ),
            })
          }
        }
      }
  }
}

///|
fn miniapp_safe_book_projection(
  building : @miniapp_contracts.MiniappBuilding,
  book : @miniapp_contracts.MiniappBookSummary,
) -> @miniapp_contracts.MiniappBookSummary {
  if building.visibility == @miniapp_contracts.Published {
    {
      ..book,
      summary: miniapp_safe_book_summary(building, book),
      visibility: @miniapp_contracts.Published,
    }
  } else {
    book
  }
}

///|
fn miniapp_safe_book_summary(
  building : @miniapp_contracts.MiniappBuilding,
  book : @miniapp_contracts.MiniappBookSummary,
) -> String {
  if building.visibility == @miniapp_contracts.Published {
    building.summary
  } else {
    book.summary
  }
}

///|
fn miniapp_support_books(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  support_book_ids : Array[String],
) -> Array[@miniapp_contracts.MiniappBookSummary] {
  let books : Array[@miniapp_contracts.MiniappBookSummary] = []
  for book in snapshot.books {
    if support_book_ids.contains(book.id) {
      books.push(book)
    }
  }
  books
}
