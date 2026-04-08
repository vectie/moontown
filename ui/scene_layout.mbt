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
    path: "ui/assets/backgrounds/town-square.webp",
    purpose: "Main overworld scene behind the mayor hall, book houses, and worker yard.",
  }
  let assets = [
    background,
    {
      key: "city-hall",
      path: "ui/assets/buildings/city-hall.webp",
      purpose: "Mayor building and strategic control center.",
    },
    {
      key: "book-house-coding",
      path: "ui/assets/buildings/book-house-coding.webp",
      purpose: "Coding moonbook building exterior and keeper station.",
    },
    {
      key: "book-house-finance",
      path: "ui/assets/buildings/book-house-finance.webp",
      purpose: "Finance moonbook building exterior and private keeper station.",
    },
    {
      key: "worker-yard",
      path: "ui/assets/props/worker-yard.webp",
      purpose: "Shared staging ground where worker claws wait for assignments.",
    },
    {
      key: "mayor-claw",
      path: "ui/assets/actors/mayor-claw.webp",
      purpose: "Strategic mayor runtime avatar.",
    },
    {
      key: "keeper-claw",
      path: "ui/assets/actors/keeper-claw.webp",
      purpose: "Book-local keeper runtime avatar.",
    },
    {
      key: "worker-claw",
      path: "ui/assets/actors/worker-claw.webp",
      purpose: "General execution claw avatar.",
    },
    {
      key: "anomaly-signal",
      path: "ui/assets/effects/anomaly-signal.webp",
      purpose: "Alarm and recovery signal effect for failures or drift.",
    },
    {
      key: "gate-sign",
      path: "ui/assets/props/gate-sign.webp",
      purpose: "Town entrance and identity marker.",
    },
  ]
  let areas = [
    {
      key: "gate",
      title: "Town Gate",
      kind: Gate,
      x: 560,
      y: 620,
      width: 180,
      height: 72,
      asset_keys: ["gate-sign"],
    },
    {
      key: "city-hall",
      title: "City Hall",
      kind: CityHall,
      x: 500,
      y: 80,
      width: 280,
      height: 180,
      asset_keys: ["city-hall", "mayor-claw"],
    },
    {
      key: "book-coding",
      title: "Moonbook / Coding",
      kind: BookHouse,
      x: 140,
      y: 260,
      width: 260,
      height: 180,
      asset_keys: ["book-house-coding", "keeper-claw"],
    },
    {
      key: "book-finance",
      title: "Moonbook / Finance",
      kind: BookHouse,
      x: 880,
      y: 260,
      width: 260,
      height: 180,
      asset_keys: ["book-house-finance", "keeper-claw"],
    },
    {
      key: "worker-yard",
      title: "Worker Yard",
      kind: WorkerYard,
      x: 390,
      y: 360,
      width: 500,
      height: 220,
      asset_keys: ["worker-yard", "worker-claw"],
    },
    {
      key: "anomaly-corner",
      title: "Anomaly Corner",
      kind: AnomalyCorner,
      x: 1010,
      y: 60,
      width: 190,
      height: 140,
      asset_keys: ["anomaly-signal"],
    },
  ]
  { width: 1280, height: 720, background, areas, assets }
}
