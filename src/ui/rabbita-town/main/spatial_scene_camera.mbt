///|
/// Measured plate floor junctions; never assume a generation prompt guarantees
/// raster geometry. Registration maps both plates to the same 2:1 camera.
priv struct SpatialSceneCamera {
  north_x : Double
  north_y : Double
  east_x : Double
  east_y : Double
  west_x : Double
  west_y : Double
}

///|
fn spatial_scene_camera(underground : Bool) -> SpatialSceneCamera {
  if underground {
    {
      north_x: 0.47,
      north_y: 0.31,
      east_x: 0.94,
      east_y: 0.60,
      west_x: 0.07,
      west_y: 0.64,
    }
  } else {
    {
      north_x: 0.485,
      north_y: 0.329,
      east_x: 0.970,
      east_y: 0.570,
      west_x: 0.040,
      west_y: 0.580,
    }
  }
}

///|
/// Affine registration preserves verticals. The two measured floor axes map
/// to +/-0.5 pixel slope in a 4:3 stage. Authored props already use 2:1.
fn spatial_scene_plate_registration(
  underground : Bool,
) -> (Double, Double, Double, Double, Double) {
  let camera = spatial_scene_camera(underground)
  let ex = camera.east_x - camera.north_x
  let ey = camera.east_y - camera.north_y
  let wx = camera.west_x - camera.north_x
  let wy = camera.west_y - camera.north_y
  let xx = 0.90
  let slope = 2.0 / 3.0
  let east_target_y = ex * xx * slope
  let west_target_y = -wx * xx * slope
  let yy = (west_target_y * ex - east_target_y * wx) / (wy * ex - ey * wx)
  let yx = (east_target_y - ey * yy) / ex
  (
    xx,
    yx,
    yy,
    0.5 - camera.north_x * xx,
    0.30 - camera.north_x * yx - camera.north_y * yy,
  )
}
