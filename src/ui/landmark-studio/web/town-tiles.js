// Lossless, full-resolution projections of the original models. Three.js is
// loaded only by the fallback baker or the user-opened independent 3D viewer.
const url = path => new URL(path,import.meta.url);
const fetchJson = async path => {
  const r=await fetch(url(path),{signal:AbortSignal.timeout(5000)});
  if(!r.ok)throw new Error(`Tile asset ${r.status}`);
  return r.json();
};
const signature = places => JSON.stringify(places.map(p=>({id:p.id,east:p.east,south:p.south,elevation:p.elevation})));
export async function loadTownTiles(places) {
  const version=await fetchJson('town-projection-version.json').catch(()=>({sha256:'unversioned'}));
  const registration=signature(places), key=`${version.sha256}:${registration}`;
  const exportMode=new URLSearchParams(location.search).get('bake-tiles')==='1';
  if(!exportMode)try {
    const pack=await fetchJson('town-projections/manifest.json');
    if(pack.version!==version.sha256||pack.registration!==registration)throw new Error('Projection inputs changed');
    if(pack.tiles?.length!==places.length||!places.every(p=>pack.tiles.some(r=>r.id===p.id&&(!p.id.endsWith('bridge')||r.front))))throw new Error('Incomplete projection pack');
    // Decode before accepting the pack; damaged/missing assets must fall back.
    for(const r of pack.tiles){await decodeTile(r);if(r.front)await decodeTile(r.front);}
    document.documentElement.dataset.landmarkTileSource='packaged';
    return pack.tiles;
  } catch {/* Preserve the original renderer when the shipped projection is stale. */}
  let cache=null;
  try {cache=await globalThis.caches?.open('moontown-landmark-projection-v1');} catch {/* Optional storage. */}
  const cacheKey=url(`town-projection-cache?key=${encodeURIComponent(key)}`);
  if(!exportMode&&cache)try {
    const hit=await cache.match(cacheKey);
    if(hit){const records=await hit.json();for(const r of records){await decodeTile(r);if(r.front)await decodeTile(r.front);}document.documentElement.dataset.landmarkTileSource='browser-cache';return records;}
  } catch {/* Rebuild a corrupt cache entry. */}
  document.documentElement.dataset.landmarkTileSource='baking';
  const {bakeTiles}=await import('./town-bake.js');
  const records=await bakeTiles(places);
  if(cache&&version.sha256!=='unversioned')try {
    for(const old of await cache.keys())await cache.delete(old);
    await cache.put(cacheKey,new Response(JSON.stringify(records),{headers:{'Content-Type':'application/json'}}));
  } catch {/* Quota/privacy restrictions cannot prevent viewing the town. */}
  if(exportMode&&['localhost','127.0.0.1','::1'].includes(location.hostname)){
    const output=document.createElement('script');output.type='application/json';output.id='town-projection-export';
    output.textContent=JSON.stringify({schema:'moontown.town-projections.v1',version:version.sha256,registration,tiles:records});document.body.append(output);
  }
  return records;
}
const decoded=new WeakMap();
export async function decodeTile(record) {
  if(decoded.has(record))return decoded.get(record);
  const image=new Image();image.src=record.source.startsWith('data:')?record.source:url(record.source).href;
  await image.decode();
  // Keep the original 2:1 mip chain, full resolution and transparent edges.
  const levels=[image];
  while(Math.max(levels.at(-1).width,levels.at(-1).height)>96){
    const previous=levels.at(-1),next=document.createElement('canvas');
    next.width=Math.max(1,Math.ceil(previous.width/2));next.height=Math.max(1,Math.ceil(previous.height/2));
    const c=next.getContext('2d');c.imageSmoothingEnabled=true;c.imageSmoothingQuality='high';c.drawImage(previous,0,0,next.width,next.height);levels.push(next);
  }
  const value={...record,image,levels};decoded.set(record,value);return value;
}
