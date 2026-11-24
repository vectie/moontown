///|
/// One bounded, camera-relative ground canvas. The public water surface is
/// static underneath a separate ripple pass. Actors and depth-sorted architecture
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
  #|   const m=context.getTransform(), ratio=Math.abs(m.a)||1;
  #|   const enabled=(zoom<0.55 || globalThis.__moontownGoldenValleyCamera?.livingRoom) && (width+384)*(height+384)*ratio*ratio<=16000000 && !new URLSearchParams(location.search).has('road-trial');
  #|   const pad=enabled?192:0;
  #|   key += ':'+[zoom*(globalThis.__townDisplay?.compact?Math.min(1,ratio):1)>.42 && zoom<=1.65 && !!globalThis.__moontownGoldenValleyCanvasLifecycle?.zoomPreview,width,height,ratio,root.dataset.regionGround,root.dataset.landmarkModels,root.dataset.wenyuGentleGroundTrial,location.search].join(':');
  #|   let cache=globalThis.__wenyuGroundCache;
  #|   const dx=cache?(cache.x-x)*zoom:0, dy=cache?(cache.y-y)*zoom:0;
  #|   const k=cache ? zoom/cache.zoom : 1, cw=(width+2*pad)*k,ch=(height+2*pad)*k;
  #|   const ox=(width-cw)/2+dx, oy=(height-ch)/2+dy;
  #|   const recent=(globalThis.__moontownGoldenValleyCamera?.zoomUntil || 0)>(globalThis.performance?.now?.() || 0);
  #|   if(enabled && cache?.valid && cache.world===world && cache.key===key && (Math.abs(k-1)<1e-9 || (recent&&k>.75&&k<1.55)) && ox< -24 && oy< -24 && ox+cw>width+24 && oy+ch>height+24){
  #|     context.drawImage(cache.canvas,0,0,cache.canvas.width,cache.canvas.height,ox,oy,cw,ch);
  #|     globalThis.__wenyuGroundCacheActive=false;root.dataset.groundCache='hit';return true;
  #|   }
  #|   if(!enabled){globalThis.__wenyuGroundCacheActive=false;root.dataset.groundCache='animated-closeup';return false;}
  #|   const canvas=cache?.canvas || document.createElement('canvas');
  #|   const pw=Math.ceil((width+2*pad)*ratio),ph=Math.ceil((height+2*pad)*ratio);
  #|   if(canvas.width!==pw)canvas.width=pw;if(canvas.height!==ph)canvas.height=ph;
  #|   const ctx=canvas.getContext('2d');ctx.setTransform(ratio,0,0,ratio,0,0);ctx.clearRect(0,0,width+2*pad,height+2*pad);
  #|   globalThis.__wenyuGroundCache={canvas,ctx,key,world,x,y,zoom,pad,width,height,valid:false};
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
