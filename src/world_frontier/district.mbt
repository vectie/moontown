///|
/// Neighborhoods have a dominant use and supporting buildings. This is visual
/// scenery, never a claim that a shop, school or institution is actually open.
fn city_building_style(
  seed : Int32,
  di : Int32,
  dj : Int32,
  x : Int32,
  y : Int32,
) -> String {
  let choices = match sample(seed, di, dj, 734) % 5 {
    0 =>
      [
        "row", "row", "lowrise", "lowrise", "courtyard", "block", "civic", "campus",
      ]
    1 =>
      ["block", "block", "row", "row", "lowrise", "courtyard", "tower", "civic"]
    2 =>
      [
        "campus", "campus", "block", "lowrise", "row", "tower", "civic", "courtyard",
      ]
    3 =>
      [
        "industrial", "industrial", "row", "row", "block", "lowrise", "campus", "civic",
      ]
    _ =>
      [
        "courtyard", "courtyard", "lowrise", "row", "block", "campus", "civic", "tower",
      ]
  }
  choices[sample(seed, x, y, 736) % choices.length()]
}
