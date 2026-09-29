///|
extern "js" fn calibration_test_context() -> @dom.CanvasRenderingContext2D =
  #| () => new Proxy({ matrix: [] }, {
  #|   get(target, key) {
  #|     if (key === 'transform') return (...matrix) => { target.matrix = matrix; };
  #|     if (key in target) return target[key];
  #|     return () => {};
  #|   },
  #|   set(target, key, value) { target[key] = value; return true; },
  #| })

///|
extern "js" fn calibration_test_matrix(
  context : @dom.CanvasRenderingContext2D,
  index : Int,
) -> Double =
  #| (context, index) => context.matrix[index] ?? NaN

///|
extern "js" fn calibration_test_zoom(zoom : Double) -> Unit =
  #| zoom => { globalThis.__moontownGoldenValleyCamera.z = zoom; }

///|
extern "js" fn calibration_test_gentle_asset(install : Bool) -> Unit =
  #| install => {
  #|   if (install) globalThis.__wenyuGentleGroundOverlay = { state: 'ready', image: {} };
  #|   else delete globalThis.__wenyuGentleGroundOverlay;
  #| }

///|
test "gentle trial uses the terrain camera without a second calibration" {
  canvas_frame_test_install_harness(true)
  calibration_test_gentle_asset(true)
  for zoom in [0.1, 0.7, 1.8] {
    golden_focus_building_camera(113.0, 81.0)
    calibration_test_zoom(zoom)
    let context = calibration_test_context()
    wenyu_gentle_ground_overlay(
      context,
      golden_valley_camera_x(),
      golden_valley_camera_y(),
      zoom,
      1200,
      800,
    )
    for point in [(0.0, 0.0), (128.0, 72.0), (256.0, 144.0)] {
      let (x, y) = point
      let road_x = calibration_test_matrix(context, 0) * x +
        calibration_test_matrix(context, 2) * y +
        calibration_test_matrix(context, 4)
      let road_y = calibration_test_matrix(context, 1) * x +
        calibration_test_matrix(context, 3) * y +
        calibration_test_matrix(context, 5)
      assert_true((road_x - golden_screen_x(x, y, 1200)).abs() < 0.00000001)
      assert_true((road_y - golden_screen_y(x, y, 800)).abs() < 0.00000001)
    }
  }
  calibration_test_gentle_asset(false)
  canvas_frame_test_remove_harness()
}

///|
test "actual road surface transform matches terrain projection across camera zoom and pan" {
  canvas_frame_test_install_harness(true)
  canvas_frame_test_install_intersection_preview()
  for zoom in [0.1, 0.7, 1.8] {
    golden_focus_building_camera(133.0, 71.0)
    calibration_test_zoom(zoom)
    let context = calibration_test_context()
    golden_draw_intersection_road_preview_graph(
      context,
      golden_valley_camera_x(),
      golden_valley_camera_y(),
      zoom,
      1200,
      800,
      1.5,
      1.15,
      0.8,
      false,
    )
    for point in [(0.0, 0.0), (128.0, 72.0), (255.0, 143.0)] {
      let (x, y) = point
      let road_x = calibration_test_matrix(context, 0) * x +
        calibration_test_matrix(context, 2) * y +
        calibration_test_matrix(context, 4)
      let road_y = calibration_test_matrix(context, 1) * x +
        calibration_test_matrix(context, 3) * y +
        calibration_test_matrix(context, 5)
      assert_true((road_x - golden_screen_x(x, y, 1200)).abs() < 0.00000001)
      assert_true((road_y - golden_screen_y(x, y, 800)).abs() < 0.00000001)
    }
  }
  canvas_frame_test_remove_harness()
}
