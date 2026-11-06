///|
test "water shading preserves land and distinguishes banks from the center" {
  let water = Array::make(25, false)
  for y in 1..<4 {
    for x in 1..<4 {
      water[y * 5 + x] = true
    }
  }
  let original = water.copy()
  let d = town_water_distances(water, 5, 5)
  assert_eq(water, original)
  assert_eq(d[12], 2.0)
  assert_eq(d[6], 1.0)
  assert_eq(d[0], 0.0)
  for i, wet in water {
    assert_eq(d[i] > 0, wet)
  }
  assert_eq(town_water_distances([true], 1, 1), [32.0])
  assert_eq(town_water_distances([], 0, 0), [])
  assert_eq(town_water_distances([true], 2, 2), [])
}

///|
test "sunny materials retain contrast and breeze is bounded and can be stopped" {
  assert_eq(town_daylight_color("grass"), "#abd85e")
  assert_true(town_daylight_color("shallow") != town_daylight_color("water"))
  assert_true(town_daylight_color("deep") != town_daylight_color("water"))
  for i in 0..<200 {
    let time = i.to_double() * 0.37
    assert_eq(town_breeze(time, 0.4, true), 0.0)
    assert_true(town_breeze(time, 0.4, false).abs() <= 0.42)
  }
}

///|
extern "js" fn sunny_water_test_install() -> Unit =
  #| ()=>{
  #| globalThis.__sunnyWaterTestOld={document:globalThis.document,Path2D:globalThis.Path2D,water:globalThis.__townSunnyWater,labels:globalThis.__wenyuReferenceLabels,camera:globalThis.__moontownGoldenValleyCamera};
  #| globalThis.Path2D=class{constructor(){this.runs=[];}rect(...r){this.runs.push(r);}};
  #| globalThis.document={createElement(){const canvas={};canvas.getContext=()=>({createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4)};},putImageData(data){canvas.pixels=data.data;}});return canvas;}};
  #| globalThis.__wenyuReferenceLabels={rows:['fixture']};delete globalThis.__townSunnyWater;
  #| }

///|
extern "js" fn sunny_water_test_check() -> Bool =
  #| ()=>{
  #| const a=globalThis.__townSunnyWater;if(a.canvas.width!==1024||a.canvas.height!==576)return false;
  #| // Even a three-cell-wide channel needs a blue center, not an all-shallows fill.
  #| const center=(10*1024+10)*4;if(a.canvas.pixels[center]>=110||a.canvas.pixels[center+2]<=180)return false;
  #| if(a.mask.runs.length!==3)return false;
  #| for(let y=0;y<576;y++)for(let x=0;x<1024;x++){
  #| const wet=x>=4&&x<16&&y>=4&&y<16;if((a.canvas.pixels[(y*1024+x)*4+3]>0)!==wet)return false;}
  #| return a.mask.runs.every(([x,y,w,h])=>x===1&&y>=1&&y<=3&&w===3&&h===1);
  #| }

///|
extern "js" fn sunny_water_test_remove() -> Unit =
  #| ()=>{const s=globalThis.__sunnyWaterTestOld;globalThis.document=s.document;globalThis.Path2D=s.Path2D;globalThis.__townSunnyWater=s.water;globalThis.__wenyuReferenceLabels=s.labels;globalThis.__moontownGoldenValleyCamera=s.camera;delete globalThis.__sunnyWaterTestOld;}

///|
test "water texture stays bounded and never colors land pixels" {
  sunny_water_test_install()
  assert_false(town_water_texture_ready())
  let wet = Array::make(256 * 144, false)
  for y in 1..<4 {
    for x in 1..<4 {
      wet[y * 256 + x] = true
    }
  }
  town_water_texture_prepare(town_water_distances(wet, 256, 144))
  let valid = sunny_water_test_check()
  let ready = town_water_texture_ready()
  sunny_water_test_remove()
  assert_true(valid)
  assert_true(ready)
}

///|
extern "js" fn sunny_water_motion_context() -> @dom.CanvasRenderingContext2D =
  #| ()=>{
  #| globalThis.__moontownGoldenValleyCamera={livingRoom:true,x:0,y:0,z:1};
  #| globalThis.__townSunnyWater={mask:new Path2D(),ripples:[[4.5,4.5,0,1]]};
  #| return {points:[],save(){},restore(){},transform(){},clip(){},beginPath(){},moveTo(...p){this.points.push(p);},quadraticCurveTo(...p){this.points.push(p);},stroke(){},drawImage(){throw new Error('Animation must not repaint cached ground');}};
  #| }

///|
extern "js" fn sunny_water_motion_take(
  c : @dom.CanvasRenderingContext2D,
) -> String =
  #| c=>{const result=JSON.stringify(c.points);c.points=[];return result;}

///|
test "water animates independently of ground cache and avoids roads" {
  sunny_water_test_install()
  let c = sunny_water_motion_context()
  let roads = Array::make(257 * 145, 0)
  town_water_ripples_draw(c, 800, 600, 0.0, false, roads)
  let first = sunny_water_motion_take(c)
  town_water_ripples_draw(c, 800, 600, 2.0, false, roads)
  let later = sunny_water_motion_take(c)
  town_water_ripples_draw(c, 800, 600, 0.0, true, roads)
  let still = sunny_water_motion_take(c)
  town_water_ripples_draw(c, 800, 600, 2.0, true, roads)
  let still_later = sunny_water_motion_take(c)
  // Prefix sum for fully occupied road cells, including bridge approaches.
  for y in 0..<=144 {
    for x in 0..<=256 {
      roads[y * 257 + x] = x * y
    }
  }
  town_water_ripples_draw(c, 800, 600, 0.0, false, roads)
  let blocked = sunny_water_motion_take(c)
  town_water_ripples_draw(c, 800, 600, 0.0, false, [])
  let unavailable = sunny_water_motion_take(c)
  sunny_water_test_remove()
  assert_true(first != "[]" && first != later)
  assert_eq(still, still_later)
  assert_eq(blocked, "[]")
  assert_eq(unavailable, "[]")
}
