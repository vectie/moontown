///|
priv struct ViewportResidentWaypoint {
  grid_x : Int
  grid_y : Int
}

///|
fn resident_waypoint(grid_x : Int, grid_y : Int) -> ViewportResidentWaypoint {
  { grid_x: grid_x, grid_y: grid_y }
}

///|
fn viewport_resident_waypoint(index : Int) -> ViewportResidentWaypoint {
  match index % 64 {
    0 => resident_waypoint(34, 32)
    1 => resident_waypoint(38, 36)
    2 => resident_waypoint(44, 40)
    3 => resident_waypoint(50, 44)
    4 => resident_waypoint(56, 48)
    5 => resident_waypoint(62, 52)
    6 => resident_waypoint(28, 54)
    7 => resident_waypoint(36, 60)
    8 => resident_waypoint(72, 24)
    9 => resident_waypoint(80, 28)
    10 => resident_waypoint(88, 32)
    11 => resident_waypoint(96, 36)
    12 => resident_waypoint(104, 40)
    13 => resident_waypoint(112, 44)
    14 => resident_waypoint(120, 48)
    15 => resident_waypoint(128, 52)
    16 => resident_waypoint(82, 60)
    17 => resident_waypoint(90, 66)
    18 => resident_waypoint(100, 70)
    19 => resident_waypoint(110, 74)
    20 => resident_waypoint(120, 78)
    21 => resident_waypoint(132, 82)
    22 => resident_waypoint(142, 86)
    23 => resident_waypoint(152, 90)
    24 => resident_waypoint(162, 62)
    25 => resident_waypoint(172, 66)
    26 => resident_waypoint(182, 70)
    27 => resident_waypoint(192, 74)
    28 => resident_waypoint(202, 78)
    29 => resident_waypoint(212, 82)
    30 => resident_waypoint(222, 86)
    31 => resident_waypoint(232, 90)
    32 => resident_waypoint(126, 102)
    33 => resident_waypoint(136, 106)
    34 => resident_waypoint(146, 110)
    35 => resident_waypoint(156, 114)
    36 => resident_waypoint(166, 118)
    37 => resident_waypoint(176, 122)
    38 => resident_waypoint(186, 126)
    39 => resident_waypoint(196, 130)
    40 => resident_waypoint(54, 82)
    41 => resident_waypoint(62, 88)
    42 => resident_waypoint(70, 94)
    43 => resident_waypoint(78, 100)
    44 => resident_waypoint(86, 106)
    45 => resident_waypoint(94, 112)
    46 => resident_waypoint(102, 118)
    47 => resident_waypoint(110, 124)
    48 => resident_waypoint(22, 30)
    49 => resident_waypoint(18, 46)
    50 => resident_waypoint(26, 62)
    51 => resident_waypoint(42, 72)
    52 => resident_waypoint(58, 72)
    53 => resident_waypoint(74, 78)
    54 => resident_waypoint(150, 36)
    55 => resident_waypoint(160, 44)
    56 => resident_waypoint(176, 50)
    57 => resident_waypoint(194, 56)
    58 => resident_waypoint(210, 58)
    59 => resident_waypoint(226, 64)
    60 => resident_waypoint(116, 58)
    61 => resident_waypoint(134, 64)
    62 => resident_waypoint(150, 72)
    _ => resident_waypoint(168, 80)
  }
}

///|
fn viewport_resident_grid_x(index : Int) -> Int {
  viewport_resident_waypoint(index).grid_x
}

///|
fn viewport_resident_grid_y(index : Int) -> Int {
  viewport_resident_waypoint(index).grid_y
}

///|
fn viewport_resident_avatar(index : Int) -> @rabbita.Html {
  let grid_x = viewport_resident_grid_x(index)
  let grid_y = viewport_resident_grid_y(index)
  let delay = index * 173 % 2400
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y) + 9}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 31}px",
    "z-index: \{100 + grid_x + grid_y}",
    "--wander-x1: \{worker_wander_x1(index + 2)}px",
    "--wander-y1: \{worker_wander_y1(index + 2)}px",
    "--wander-x2: \{worker_wander_x2(index + 4)}px",
    "--wander-y2: \{worker_wander_y2(index + 4)}px",
    "--wander-x3: \{worker_wander_x3(index + 6)}px",
    "--wander-y3: \{worker_wander_y3(index + 6)}px",
    "--wander-duration: \{6200 + index % 8 * 360}ms",
    "--wander-delay: -\{delay}ms",
    "--worker-image: url('\{worker_roster_asset(index)}')",
  ]
  div(
    class="worker-avatar viewport-resident worker-running worker-sprite-roster",
    style~,
    [
      span(class="worker-sprite", no_children()),
      span(class="worker-badge", ""),
      span(class="worker-label", "Resident \{index + 1}"),
      span(class="worker-meta", "walking building district"),
    ],
  )
}

///|
fn render_viewport_residents() -> Array[@rabbita.Html] {
  let residents : Array[@rabbita.Html] = []
  for i in 0..<64 {
    residents.push(viewport_resident_avatar(i))
  }
  residents
}
