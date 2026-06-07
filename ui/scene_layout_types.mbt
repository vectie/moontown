///|
pub enum SceneAreaKind {
  CityHall
  BookHouse
  WorkerYard
  AnomalyCorner
  Gate
} derive(Debug, Eq)

///|
pub impl Show for SceneAreaKind with fn output(
  self : SceneAreaKind,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      CityHall => "CityHall"
      BookHouse => "BookHouse"
      WorkerYard => "WorkerYard"
      AnomalyCorner => "AnomalyCorner"
      Gate => "Gate"
    },
  )
}

///|
pub struct SceneAsset {
  key : String
  path : String
  purpose : String
} derive(Debug, Eq)

///|
pub impl Show for SceneAsset with fn output(self : SceneAsset, logger : &Logger) -> Unit {
  logger.write_string(
    "SceneAsset(key=\{self.key}, path=\{self.path}, purpose=\{self.purpose})",
  )
}

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
} derive(Debug, Eq)

///|
pub impl Show for SceneArea with fn output(self : SceneArea, logger : &Logger) -> Unit {
  logger.write_string(
    "SceneArea(key=\{self.key}, title=\{self.title}, kind=\{self.kind.to_string()}, x=\{self.x}, y=\{self.y}, width=\{self.width}, height=\{self.height}, assets=\{self.asset_keys.length()})",
  )
}

///|
pub struct TownSceneLayout {
  width : Int
  height : Int
  background : SceneAsset
  areas : Array[SceneArea]
  assets : Array[SceneAsset]
} derive(Debug, Eq)

///|
pub impl Show for TownSceneLayout with fn output(
  self : TownSceneLayout,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "TownSceneLayout(width=\{self.width}, height=\{self.height}, background=\{self.background.key}, areas=\{self.areas.length()}, assets=\{self.assets.length()})",
  )
}
