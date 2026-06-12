///|
fn area_for_book(
  layout : TownSceneLayout,
  book : @core.BookRef,
  index : Int,
  total_books : Int,
) -> SceneArea {
  match book.id {
    "coding" =>
      if total_books <= 2 {
        require_area(layout, "book-coding")
      } else {
        dynamic_book_area(book, index)
      }
    "finance" =>
      if total_books <= 2 {
        require_area(layout, "book-finance")
      } else {
        dynamic_book_area(book, index)
      }
    _ => dynamic_book_area(book, index)
  }
}

///|
fn dynamic_book_area(book : @core.BookRef, index : Int) -> SceneArea {
  let width = 210
  let height = 136
  let slot = index % 12
  let (x, y) = dynamic_book_slot_position(slot)
  {
    key: "book-\{book.id}",
    title: book.name,
    kind: BookHouse,
    x,
    y,
    width,
    height,
    asset_keys: dynamic_book_asset_keys(book.id, index),
  }
}

///|
fn dynamic_book_slot_position(slot : Int) -> (Int, Int) {
  match slot {
    0 => (82, 356)
    1 => (214, 260)
    2 => (96, 490)
    3 => (326, 460)
    4 => (432, 342)
    5 => (408, 540)
    6 => (660, 156)
    7 => (842, 404)
    8 => (818, 282)
    9 => (500, 214)
    10 => (706, 248)
    _ => (802, 558)
  }
}

///|
fn dynamic_book_asset_keys(book_id : String, index : Int) -> Array[String] {
  let district = dynamic_district_asset_key(book_id)
  if district != "" {
    [district]
  } else {
    let (building, roof) = if index % 2 == 0 {
      ("book-house-coding", "book-house-coding-roof")
    } else {
      ("book-house-finance", "book-house-finance-roof")
    }
    [building, roof, "keeper-claw"]
  }
}

///|
fn dynamic_district_asset_key(book_id : String) -> String {
  match book_id {
    "wenyu-town-shell" => "district-town-shell"
    "wenyu-resident-twins" => "district-resident-twins"
    "wenyu-policy-hall" => "district-policy-hall"
    "wenyu-contest-express" => "district-contest-express"
    "wenyu-social-square" => "district-social-square"
    "wenyu-talent-avenue" => "district-talent-avenue"
    "wenyu-vitality-dashboard" => "district-vitality-dashboard"
    "wenyu-ai-garden" => "district-ai-garden"
    "wenyu-physical-bridge" => "district-physical-bridge"
    _ => ""
  }
}
