///|
/// One bounded, camera-relative ground canvas. Close-up water is animated, so
/// it deliberately uses the original path. Actors and depth-sorted architecture
/// are never baked into this cache. World identity invalidates user edits.
extern "js" fn wenyu_ground_cache_restore(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  key : String,
  width : Int32,
  height : Int32,
  x : Double,
  y : Double,
  zoom : Double,
) -> Bool =
  #| (context, world, key, width, height, x, y, zoom) => {
  #|   const root=document.documentElement;
  #|   const m=context.getTransform(), ratio=Math.hypot(m.a,m.b)||1;
  #|   const enabled=zoom<0.55 && (width+384)*(height+384)*ratio*ratio<=16000000 && !new URLSearchParams(location.search).has('road-trial');
  #|   const pad=enabled?192:0;
  #|   key += ':'+[width,height,ratio,zoom,root.dataset.landmarkModels,root.dataset.wenyuGentleGroundTrial,location.search].join(':');
  #|   let cache=globalThis.__wenyuGroundCache;
  #|   const dx=cache?(cache.x-x)*zoom:0, dy=cache?(cache.y-y)*zoom:0;
  #|   if(enabled && cache?.valid && cache.world===world && cache.key===key && Math.abs(dx)<pad-32 && Math.abs(dy)<pad-32){
  #|     context.drawImage(cache.canvas,0,0,cache.canvas.width,cache.canvas.height,-pad+dx,-pad+dy,width+2*pad,height+2*pad);
  #|     root.dataset.groundCache='hit';return true;
  #|   }
  #|   if(!enabled){globalThis.__wenyuGroundCacheActive=false;root.dataset.groundCache='animated-closeup';return false;}
  #|   const canvas=cache?.canvas || document.createElement('canvas');
  #|   canvas.width=Math.ceil((width+2*pad)*ratio);canvas.height=Math.ceil((height+2*pad)*ratio);
  #|   const ctx=canvas.getContext('2d');ctx.setTransform(ratio,0,0,ratio,0,0);
  #|   globalThis.__wenyuGroundCache={canvas,ctx,key,world,x,y,pad,width,height,valid:false};
  #|   globalThis.__wenyuGroundCacheActive=true;root.dataset.groundCache='rebuild';return false;
  #| }

///|
extern "js" fn wenyu_ground_cache_context(
  fallback : @dom.CanvasRenderingContext2D,
) -> @dom.CanvasRenderingContext2D =
  #| fallback => globalThis.__wenyuGroundCacheActive ? globalThis.__wenyuGroundCache.ctx : fallback

///|
extern "js" fn wenyu_ground_cache_padding() -> Int32 =
  #| () => globalThis.__wenyuGroundCacheActive ? globalThis.__wenyuGroundCache.pad : 0

///|
extern "js" fn wenyu_ground_cache_present(
  context : @dom.CanvasRenderingContext2D,
) -> Unit =
  #| context => {
  #|   if(!globalThis.__wenyuGroundCacheActive)return;
  #|   const c=globalThis.__wenyuGroundCache;c.valid=true;
  #|   context.drawImage(c.canvas,0,0,c.canvas.width,c.canvas.height,-c.pad,-c.pad,c.width+2*c.pad,c.height+2*c.pad);
  #| }
