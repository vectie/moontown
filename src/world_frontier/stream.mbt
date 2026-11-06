///|
/// Only the current 3 by 3 neighborhood is retained. Pan and walking use
/// independent windows, so looking away cannot evict a visitor's navigation.
pub struct Window {
  seed : Int32
  organic : Bool
  chunks : Map[String, Chunk]
  mut center : (Int32, Int32)?
}

///|
pub fn Window::new(seed : Int32, organic~ : Bool = false) -> Window {
  { seed, organic, chunks: Map([]), center: None, }
}

///|
pub fn Window::around(self : Window, p : Point) -> Array[Chunk] {
  let cx = coordinate(p.x)
  let cy = coordinate(p.y)
  if self.center != Some((cx, cy)) {
    let next : Map[String, Chunk] = Map([])
    for y in (cy - 1)..<=(cy + 1) {
      for x in (cx - 1)..<=(cx + 1) {
        if x.abs() > coordinate_limit || y.abs() > coordinate_limit {
          continue
        }
        let key = "\{x}:\{y}"
        let chunk = match self.chunks.get(key) {
          Some(c) => c
          None => generate(self.seed, x, y, organic=self.organic)
        }
        next[key] = chunk
      }
    }
    self.chunks.clear()
    for k, v in next {
      self.chunks[k] = v
    }
    self.center = Some((cx, cy))
  }
  self.chunks.values().collect()
}

///|
pub fn Window::count(self : Window) -> Int32 {
  self.chunks.length()
}
