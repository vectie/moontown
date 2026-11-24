///|
/// A snapshot replacement supplies new immutable arrays. District loading can
/// change reservation masks once for an existing array.
extern "js" fn wenyu_visible_installations(
  items : Array[@energy_valley_contract.Installation],
  ready : Bool,
  filter : () -> Array[@energy_valley_contract.Installation],
) -> Array[@energy_valley_contract.Installation] =
  #| (items,ready,filter)=>{
  #|   const cache=globalThis.__wenyuVisibleInstallations ??= new WeakMap();
  #|   let row=cache.get(items);
  #|   if(!row || row.ready!==ready){ row={ready,items:filter()};cache.set(items,row); }
  #|   return row.items;
  #| }

///|
/// Cache the fixed installations at their original position in the painter's
/// depth order. Cars, walkers, architecture and water are separate passes.
extern "js" fn wenyu_street_row(
  ctx : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  depth : Int32,
  w : Int32,
  h : Int32,
  night : Bool,
  paint : (@dom.CanvasRenderingContext2D) -> Unit,
) -> Unit =
  #| (ctx,world,depth,w,h,night,paint)=>{
  #|   const c=globalThis.__moontownGoldenValleyCamera, owner=globalThis.__moontownGoldenValleyCanvasLifecycle;
  #|   if(!owner || !c?.livingRoom || !globalThis.__townDisplay?.compact || c.z*(owner.pixelRatio||1)>.50 || (c.zoomUntil||0)>performance.now()){
  #|     if(owner) owner.streetRows=null;
  #|     paint(ctx); return;
  #|   }
  #|   const ds=document.documentElement.dataset, ratio=owner.canvas.width/w;
  #|   const key=[w,h,c.x,c.y,c.z,ratio,night,ds.landmarkModels,ds.regionGround,ds.wenyuGentleGroundTrial].join('/');
  #|   let cache=owner.streetRows;
  #|   if(cache?.world!==world || cache.key!==key){
  #|     if(cache)for(const row of cache.rows.values())if(row)row.tile.width=0;
  #|     cache=owner.streetRows={world,key,rows:new Map(),pixels:0};
  #|   }
  #|   let row=cache.rows.get(depth);
  #|   if(row===undefined){
  #|     // Project the endpoints of this diagonal in the registered 256 x 144 grid.
  #|     // The padding includes crown, projected shadow, boardwalks and night glow.
  #|     const z=c.z, mid=h/2+(16*depth-c.y)*z;
  #|     const left=Math.max(0,Math.floor((w/2+(32*(2*Math.max(0,depth-145)-depth)-c.x)*z-96*z-8)*ratio));
  #|     const right=Math.min(owner.canvas.width,Math.ceil((w/2+(32*(2*Math.min(257,depth+1)-depth)-c.x)*z+96*z+8)*ratio));
  #|     const top=Math.max(0,Math.floor((mid-148*z-10)*ratio)), bottom=Math.min(owner.canvas.height,Math.ceil((mid+64*z+10)*ratio));
  #|     if(left>=right || top>=bottom){cache.rows.set(depth,null);return;}
  #|     const pixels=(right-left)*(bottom-top);
  #|     if(cache.pixels+pixels>8000000){paint(ctx);return;}
  #|     const tile=document.createElement('canvas');tile.width=right-left;tile.height=bottom-top;
  #|     const g=tile.getContext('2d');g.setTransform(ratio,0,0,ratio,-left,-top);
  #|     paint(g);
  #|     row={tile,left,top};cache.rows.set(depth,row);cache.pixels+=pixels;
  #|   }
  #|   if(row)ctx.drawImage(row.tile,row.left/ratio,row.top/ratio,row.tile.width/ratio,row.tile.height/ratio);
  #| }

///|
extern "js" fn wenyu_vehicle_frame(
  c : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  w : Int32,
  h : Int32,
  hour : Double,
) -> Bool =
  #| (ctx,world,w,h,hour)=>!!globalThis.__townLandmarkPainter?.trafficLayers?.replay(ctx,world,w,h,hour)

///|
extern "js" fn wenyu_vehicle_begin(
  c : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  w : Int32,
  h : Int32,
  sec : Double,
  reduced : Bool,
  hour : Double,
) -> Unit =
  #| (ctx,world,w,h,sec,reduced,hour)=>globalThis.__townLandmarkPainter?.trafficLayers?.begin(ctx,world,w,h,sec,reduced,hour)

///|
extern "js" fn wenyu_vehicle_depth(
  c : @dom.CanvasRenderingContext2D,
  depth : Int32,
) -> @dom.CanvasRenderingContext2D =
  #| (ctx,depth)=>globalThis.__townLandmarkPainter?.trafficLayers?.depth(ctx,depth) || ctx

///|
extern "js" fn wenyu_vehicle_finish(c : @dom.CanvasRenderingContext2D) -> Unit =
  #| ctx=>globalThis.__townLandmarkPainter?.trafficLayers?.finish(ctx)
