///|
pub(all) struct GridPosition {
  column : Int
  row : Int
} derive(Debug, Eq, Hash)

///|
pub fn grid_position(column : Int, row : Int) -> GridPosition {
  { column, row }
}

///|
pub(all) struct WorldPoint {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub fn world_point(x : Double, y : Double, z? : Double = 0.0) -> WorldPoint {
  { x, y, z }
}

///|
pub(all) struct WorldBounds {
  minimum : WorldPoint
  maximum : WorldPoint
} derive(Debug, Eq)

///|
pub fn world_bounds(minimum : WorldPoint, maximum : WorldPoint) -> WorldBounds {
  { minimum, maximum }
}

///|
pub fn WorldBounds::is_well_formed(self : WorldBounds) -> Bool {
  self.minimum.x < self.maximum.x &&
  self.minimum.y < self.maximum.y &&
  self.minimum.z <= self.maximum.z
}

///|
pub fn WorldBounds::contains(self : WorldBounds, point : WorldPoint) -> Bool {
  point.x >= self.minimum.x &&
  point.x <= self.maximum.x &&
  point.y >= self.minimum.y &&
  point.y <= self.maximum.y &&
  point.z >= self.minimum.z &&
  point.z <= self.maximum.z
}

///|
fn[T] freeze(values : ArrayView[T]) -> ReadOnlyArray[T] {
  ReadOnlyArray::from_array(values)
}
