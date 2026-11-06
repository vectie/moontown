///|
test "exterior renderer uses generated road frame even far beyond core calibration" {
  let frame = frontier_city_frame()
  let mut count = 0
  for (x, y) in [(-3, -2), (9, 6), (300, -200)] {
    let chunk = @frontier.city(20261028, x, y, frame, frontier_core, [], [])
    for lot in chunk.lots {
      count += 1
      let b = frontier_lot_bearing(lot)
      let building = frontier_lot_building(lot)
      assert_eq(b.east.x, lot.east.x)
      assert_eq(b.north.y, lot.north.y)
      let span = town_bearing_span(b, building.width, building.depth)
      let mesh = town_bearing_mesh(building, bearing=b, variant=lot.variant)
      for i in 0..<(mesh.points.length() / 3) {
        assert_true(mesh.points[i * 3].abs() <= lot.size.to_double() / 2 + 0.1)
        assert_true(
          mesh.points[i * 3 + 1].abs() <= lot.size.to_double() / 2 + 0.1,
        )
      }
      let center_x = lot.x.to_double() + lot.size.to_double() / 2
      let center_y = lot.y.to_double() + lot.size.to_double() / 2
      let dx = lot.entrance.x - center_x
      let dy = lot.entrance.y - center_y
      let det = b.east.x * b.north.y - b.north.x * b.east.y
      let u = (b.north.y * dx - b.north.x * dy) / det / span
      let v = (b.east.x * dy - b.east.y * dx) / det / span
      // Navigation quantizes positions to 0.001 ground units, not directions.
      assert_true((u.abs().max(v.abs()) - 0.5).abs() * span < 0.002)
    }
  }
  assert_true(count > 0)
}

///|
test "exterior model preserves the selected design variant" {
  let chunk = @frontier.city(
    20261028,
    -3,
    -2,
    frontier_city_frame(),
    frontier_core,
    [],
    [],
  )
  assert_true(!chunk.lots.is_empty())
  let lot = chunk.lots[0]
  let b = frontier_lot_building(lot)
  let frame = frontier_lot_bearing(lot)
  let first = town_bearing_mesh(b, bearing=frame, variant=0)
  let second = town_bearing_mesh(b, bearing=frame, variant=1)
  let third = town_bearing_mesh(b, bearing=frame, variant=2)
  assert_true(first.points != second.points)
  assert_true(second.points != third.points)
}

///|
extern "js" fn frontage_paint_test_install() -> @dom.CanvasRenderingContext2D =
  #| ()=>{
  #| const fixture={document:globalThis.document,cache:globalThis.__townBearingPaintCache,created:0,draws:0};
  #| globalThis.__frontagePaintTest=fixture;delete globalThis.__townBearingPaintCache;
  #| globalThis.document={createElement(){fixture.created++;return {getContext(){return {scale(){},translate(){},beginPath(){},moveTo(){},lineTo(){},closePath(){},fill(){},stroke(){}};}};}};
  #| return {drawImage(...args){fixture.draws++;fixture.last=args.slice(1);}};
  #| }

///|
extern "js" fn frontage_paint_test_reused() -> Bool =
  #| ()=>{const f=globalThis.__frontagePaintTest;return f.created===1&&f.draws===2&&f.last.every(Number.isFinite)&&f.last[2]>0&&f.last[3]>0;}

///|
extern "js" fn frontage_paint_test_finish() -> Bool =
  #| ()=>{
  #| const f=globalThis.__frontagePaintTest,c=globalThis.__townBearingPaintCache;
  #| const valid=c.entries.size<=512&&c.bytes<=96*1024*1024&&c.bytes>0&&f.draws===602;
  #| globalThis.document=f.document;globalThis.__townBearingPaintCache=f.cache;delete globalThis.__frontagePaintTest;return valid;
  #| }

///|
test "oriented painting reuses projections and bounds the exterior bitmap cache" {
  let c = frontage_paint_test_install()
  let points = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0]
  town_bearing_paint_mesh(c, points, ["#fff"], 100, 100, 1)
  town_bearing_paint_mesh(c, points, ["#fff"], 150, 120, 2)
  let reused = frontage_paint_test_reused()
  for _ in 0..<600 {
    town_bearing_paint_mesh(c, points.copy(), ["#fff"], 100, 100, 1)
  }
  let bounded = frontage_paint_test_finish()
  assert_true(reused)
  assert_true(bounded)
}
