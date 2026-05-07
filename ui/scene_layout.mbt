///|
pub enum SceneAreaKind {
  CityHall
  BookHouse
  WorkerYard
  AnomalyCorner
  Gate
} derive(Show, Eq)

///|
pub struct SceneAsset {
  key : String
  path : String
  purpose : String
} derive(Show, Eq)

///|
pub struct SceneArea {
  key : String
  title : String
  kind : SceneAreaKind
  x : Int
  y : Int
  width : Int
  height : Int
  asset_keys : Array[String]
} derive(Show, Eq)

///|
pub struct TownSceneLayout {
  width : Int
  height : Int
  background : SceneAsset
  areas : Array[SceneArea]
  assets : Array[SceneAsset]
} derive(Show, Eq)

///|
pub fn default_town_scene_layout() -> TownSceneLayout {
  let background = {
    key: "town-square",
    path: "backgrounds/town-square.svg?v=solid-tiles",
    purpose: "Main overworld scene behind the mayor hall, book houses, and worker yard.",
  }
  let assets = [
    background,
    {
      key: "city-hall",
      path: "tilemap/buildings/city_hall_base.png",
      purpose: "Generated City Hall base sprite.",
    },
    {
      key: "city-hall-roof",
      path: "tilemap/buildings/city_hall_roof.png",
      purpose: "Generated City Hall roof sprite.",
    },
    {
      key: "book-house-coding",
      path: "tilemap/buildings/book_house_base.png?variant=coding",
      purpose: "Generated MoonBook coding house base sprite.",
    },
    {
      key: "book-house-coding-roof",
      path: "tilemap/buildings/book_house_roof.png?variant=coding",
      purpose: "Generated MoonBook coding house roof sprite.",
    },
    {
      key: "book-house-finance",
      path: "tilemap/buildings/book_house_base.png?variant=finance",
      purpose: "Generated MoonBook finance house base sprite.",
    },
    {
      key: "book-house-finance-roof",
      path: "tilemap/buildings/book_house_roof.png?variant=finance",
      purpose: "Generated MoonBook finance house roof sprite.",
    },
    {
      key: "worker-yard",
      path: "tilemap/buildings/worker_yard_base.png",
      purpose: "Generated Worker Yard base sprite.",
    },
    {
      key: "worker-yard-roof",
      path: "tilemap/buildings/worker_yard_roof.png",
      purpose: "Generated Worker Yard roof sprite.",
    },
    {
      key: "district-town-shell",
      path: "tilemap/districts/town_shell.png",
      purpose: "Generated Wenyu Town Shell observatory district.",
    },
    {
      key: "district-resident-twins",
      path: "tilemap/districts/resident_twins.png",
      purpose: "Generated Wenyu Resident Twins district.",
    },
    {
      key: "district-policy-hall",
      path: "tilemap/districts/policy_hall.png",
      purpose: "Generated Wenyu Policy Hall district.",
    },
    {
      key: "district-contest-express",
      path: "tilemap/districts/contest_express.png",
      purpose: "Generated Wenyu Contest Express district.",
    },
    {
      key: "district-social-square",
      path: "tilemap/districts/social_square.png",
      purpose: "Generated Wenyu Social Square district.",
    },
    {
      key: "district-talent-avenue",
      path: "tilemap/districts/talent_avenue.png",
      purpose: "Generated Wenyu Talent Avenue district.",
    },
    {
      key: "district-vitality-dashboard",
      path: "tilemap/districts/vitality_dashboard.png",
      purpose: "Generated Wenyu Vitality Dashboard district.",
    },
    {
      key: "district-ai-garden",
      path: "tilemap/districts/ai_garden.png",
      purpose: "Generated Wenyu AI Garden district.",
    },
    {
      key: "district-physical-bridge",
      path: "tilemap/districts/physical_bridge.png",
      purpose: "Generated Wenyu Physical Bridge district.",
    },
    {
      key: "mayor-claw",
      path: "tilemap/actors/mayor_walk_1.png",
      purpose: "Generated strategic mayor runtime avatar.",
    },
    {
      key: "keeper-claw",
      path: "tilemap/actors/keeper_walk_1.png",
      purpose: "Generated book-local keeper runtime avatar.",
    },
    {
      key: "worker-claw",
      path: "tilemap/actors/worker_walk_1.png",
      purpose: "Generated execution worker avatar.",
    },
    {
      key: "anomaly-signal",
      path: "effects/anomaly-signal.svg",
      purpose: "Alarm and recovery signal effect for failures or drift.",
    },
    {
      key: "gate-sign",
      path: "props/gate-sign.svg",
      purpose: "Town entrance and identity marker.",
    },
  ]
  let areas = [
    {
      key: "gate",
      title: "Town Gate",
      kind: Gate,
      x: 560,
      y: 604,
      width: 180,
      height: 72,
      asset_keys: ["gate-sign"],
    },
    {
      key: "city-hall",
      title: "City Hall",
      kind: CityHall,
      x: 610,
      y: 100,
      width: 280,
      height: 180,
      asset_keys: ["city-hall", "city-hall-roof", "mayor-claw"],
    },
    {
      key: "book-coding",
      title: "Moonbook / Coding",
      kind: BookHouse,
      x: 116,
      y: 372,
      width: 260,
      height: 180,
      asset_keys: ["book-house-coding", "book-house-coding-roof", "keeper-claw"],
    },
    {
      key: "book-finance",
      title: "Moonbook / Finance",
      kind: BookHouse,
      x: 796,
      y: 366,
      width: 260,
      height: 180,
      asset_keys: [
        "book-house-finance", "book-house-finance-roof", "keeper-claw",
      ],
    },
    {
      key: "worker-yard",
      title: "Worker Yard",
      kind: WorkerYard,
      x: 594,
      y: 468,
      width: 400,
      height: 118,
      asset_keys: ["worker-yard", "worker-yard-roof", "worker-claw"],
    },
    {
      key: "anomaly-corner",
      title: "Anomaly Corner",
      kind: AnomalyCorner,
      x: 820,
      y: 118,
      width: 190,
      height: 140,
      asset_keys: ["anomaly-signal"],
    },
  ]
  { width: 1280, height: 720, background, areas, assets }
}
