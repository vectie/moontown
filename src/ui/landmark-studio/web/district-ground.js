// These footprints have already passed the MoonBit road, water and registration checks.
import {decodeStudyRing,facadePlan,elevation,solarRows} from './district-facades.js';
const rows=new Map(),cells=new Map(),projects=new Map();
const knownUnits=new Set();
export const hasUnit=id=>knownUnits.has(id);
let initialized=false, night=false;
export function setHour(hour){night=hour<7||hour>=18}
const poly=(c,r,color)=>{c.beginPath();r.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.fillStyle=color;c.fill()};
const inside=(r,x,y)=>{let b=false;for(let i=0,j=r.length-1;i<r.length;j=i++){const [a,c]=r[i],[d,e]=r[j];if((c>y)!=(e>y)&&x<(d-a)*(y-c)/(e-c)+a)b=!b}return b};
const d2=(p,a,b)=>{const dx=b[0]-a[0],dy=b[1]-a[1],t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1)));return (a[0]+t*dx-p[0])**2+(a[1]+t*dy-p[1])**2};
export const ready=()=>initialized;
export const hasProject=key=>projects.has(key);
export async function loadDistricts(){
 const res=await fetch(new URL('district-ground.json',import.meta.url));if(!res.ok)throw Error('district geometry '+res.status);
 const data=await res.json();for(const [key,kind,h,ring,source] of data){const z=ring.reduce((s,p)=>s+p[0]+p[1],0)/ring.length,xs=ring.map(p=>p[0]),ys=ring.map(p=>p[1]);const u={key,kind,h,ring,z,source,textures:[]};
 if(source?.id)knownUnits.add(source.id);
 const row=Math.floor(z);if(!rows.has(row))rows.set(row,[]);rows.get(row).push(u);
 if(!projects.has(key))projects.set(key,[]);projects.get(key).push(u);
 for(let x=Math.floor(Math.min(...xs));x<=Math.floor(Math.max(...xs));x++)for(let y=Math.floor(Math.min(...ys));y<=Math.floor(Math.max(...ys));y++){const i=x*256+y;if(!cells.has(i))cells.set(i,[]);cells.get(i).push(u)}
 }for(const list of rows.values())list.sort((a,b)=>a.z-b.z);initialized=true
}
export function reserved(x,y,pad){
 for(let i=Math.floor(x-pad);i<=Math.floor(x+pad);i++)for(let j=Math.floor(y-pad);j<=Math.floor(y+pad);j++){const batch=cells.get(i*256+j);if(!batch)continue;for(const {ring} of batch)if(inside(ring,x,y)||pad>0&&ring.some((a,k)=>d2([x,y],a,ring[(k+1)%ring.length])<=pad*pad))return true}
 return false
}
function projected(u,f){return u.ring.map(([x,y])=>[f.w/2+(32*(x-y)-f.cx)*f.z,f.h/2+(16*(x+y)-f.cy)*f.z])}
function planFor(u) {
 if(u.plan)return u.plan;
 const source=u.source;
 const metric=source?decodeStudyRing(source.ring).map(([x,y])=>[x*source.scale[0],y*source.scale[1]]):
   u.ring.map(([x,y])=>[x*15,y*15]);
 return u.plan=facadePlan(u.key,u.kind,u.h,metric,source?.id);
}
// Bound native canvas backing stores on low-memory boards, across all districts.
const compactTiles=new Map();
let compactBytes=0;
function keepCompactTile(tile, variants, phase) {
 const bytes=tile.width*tile.height*4;
 compactTiles.set(tile,{variants,phase,bytes});compactBytes+=bytes;
 while(compactBytes>12*1024*1024){
   const [old,record]=compactTiles.entries().next().value;
   record.variants[record.phase]=null;compactBytes-=record.bytes;compactTiles.delete(old);
   old.width=old.height=0;
 }
}
function surface(u,plan,edge) {
 const variants=u.textures[edge.index]??=[];
 const phase=night?1:0;
 if(variants[phase]){
   const tile=variants[phase],record=compactTiles.get(tile);
   if(record){compactTiles.delete(tile);compactTiles.set(tile,record)}
   return tile;
 }
 const compact=!!globalThis.__townDisplay?.compact;
 const scale=compact?1.5:3;
 const tile=document.createElement('canvas');
 tile.width=Math.max(1,Math.min(320,Math.ceil(edge.len*scale)));
 tile.height=Math.max(1,Math.min(200,Math.ceil(u.h*scale)));
 const ctx=tile.getContext('2d',{alpha:false});
 ctx.fillStyle=plan.colors.wall;ctx.fillRect(0,0,tile.width,tile.height);
 ctx.setTransform(tile.width/edge.len,0,0,-tile.height/u.h,0,tile.height);
 elevation(plan,edge,(x,y,w,h,role)=>{ctx.fillStyle=night&&role==='lamp'?'#ffe0a6':plan.colors[role];ctx.fillRect(x,y,w,h)});
 variants[phase]=tile;
 if(compact)keepCompactTile(tile,variants,phase);
 return tile;
}
// Use the same longest edge, central clearance and roof plant dimensions as the
// orbit model. Store barycentric weights so the block works in both map cameras.
function roofPlant(plan){
 const e=plan.edges,ps=e.map(v=>[v.x,v.z]),n=ps.length;
 const p=ps.reduce((a,v)=>[a[0]+v[0]/n,a[1]+v[1]/n],[0,0]);
 if(!inside(ps,...p)||plan.family==='robotics'||plan.family==='xingke')return null;
 const clearance=Math.sqrt(Math.min(...ps.map((v,i)=>d2(p,v,ps[(i+1)%n]))));
 if(clearance<2.7)return null;
 const axis=e.reduce((a,b)=>a.len>b.len?a:b),w=Math.min(clearance*1.4,plan.form==='homes'?7:11),d=Math.min(clearance*.85,5);
 const a=ps[0],b=ps[1],ux=b[0]-a[0],uy=b[1]-a[1];let j=2,det=0;
 while(j<n){det=ux*(ps[j][1]-a[1])-uy*(ps[j][0]-a[0]);if(Math.abs(det)>.1)break;j++}
 if(j===n)return null;
 const vx=ps[j][0]-a[0],vy=ps[j][1]-a[1];
 const weights=[[-1,-1],[1,-1],[1,1],[-1,1]].map(([dx,dy])=>{
   const x=p[0]+axis.tx*dx*w/2-axis.tz*dy*d/2-a[0],y=p[1]+axis.tz*dx*w/2+axis.tx*dy*d/2-a[1];
   return [(x*vy-y*vx)/det,(ux*y-uy*x)/det]
 });
 return {j,weights,height:plan.form==='homes'?1.65:1.18};
}
function draw(c,u,f){
 const r=projected(u,f), h=u.h*.68*f.z;
 const court=u.source?.court?.length?projected({ring:u.source.court},f):[];
 drawVolume(c,u,r,h,f,court);
}
// Facades, roof furniture and shadows move together. Cache their transparent
// image per building, so cars and pedestrians can keep their original depth.
const volumes = new Map();
let volumePixels = 0;
function discardVolume(unit) {
 const tile=volumes.get(unit).tile;
 volumePixels-=tile.width*tile.height;
 tile.width=tile.height=0;
 volumes.delete(unit);
}
export function drawVolume(c,u,r,h,f,court=[]){
 if(r.every(p=>p[0]<-8)||r.every(p=>p[0]>f.w+8)||r.every(p=>p[1]<-8)||r.every(p=>p[1]>f.h+h+2))return;
 const owner=globalThis.__moontownGoldenValleyCanvasLifecycle;
 if(globalThis.__townDisplay?.compact && owner && f.z>.35 && !owner.zoomPreview &&
    !globalThis.__moontownGoldenValleyCamera?.streetTransition && !globalThis.__townBakeZoomArt){
   const ratio=owner.pixelRatio || 1, [x,y]=r[0];
   let sprite=volumes.get(u);
   // A higher-resolution facade already contains the exact roof, walls and
   // shadow for this bearing. Anchor and downsample it when zooming out.
   if(sprite && (sprite.zoom<f.z-1e-8 || sprite.night!==night || sprite.ratio!==ratio)){
     discardVolume(u);sprite=null;
   }
   if(!sprite){
     const xs=r.map(p=>p[0]),ys=r.map(p=>p[1]);
     const left=Math.floor(Math.min(...xs)*ratio)-2,top=Math.floor((Math.min(...ys)-h-4*f.z)*ratio)-2;
     const width=Math.ceil((Math.max(...xs)+h*.36)*ratio)+2-left;
     const height=Math.ceil((Math.max(...ys)+h*.16)*ratio)+2-top;
     if(width*height<=350000 && width>0 && height>0){
       while(volumes.size && volumePixels+width*height>3000000)discardVolume(volumes.keys().next().value);
       const tile=document.createElement('canvas');tile.width=width;tile.height=height;
       const g=tile.getContext('2d');g.setTransform(ratio,0,0,ratio,-left,-top);
       paintVolume(g,u,r,h,f,court);
       sprite={tile,zoom:f.z,night,ratio,dx:left/ratio-x,dy:top/ratio-y};
       volumePixels+=width*height;
     }
   }
   if(sprite){
     volumes.delete(u);volumes.set(u,sprite);
     const {tile,dx,dy}=sprite, scale=f.z/sprite.zoom;
     c.drawImage(tile,x+dx*scale,y+dy*scale,tile.width*scale/ratio,tile.height*scale/ratio);return;
   }
 }
 paintVolume(c,u,r,h,f,court);
}
function paintVolume(c,u,r,h,f,court){
 const t=r.map(([x,y])=>[x,y-h]),plan=u.plan||planFor(u);
 const shadow=r.map(([x,y])=>[x+h*.36,y+h*.16]);
 c.save();c.globalAlpha=.20;c.beginPath();
 for(const face of [shadow,...r.map((p,i)=>[p,r[(i+1)%r.length],shadow[(i+1)%r.length],shadow[i]])]){
   const area=face.reduce((v,p,i)=>{const q=face[(i+1)%face.length];return v+p[0]*q[1]-p[1]*q[0]},0);
   (area<0?face.slice().reverse():face).forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath()
 }
 c.fillStyle='#44633c';c.fill();c.restore();
 const winding=Math.sign(r.reduce((a,p,i)=>{const q=r[(i+1)%r.length];return a+p[0]*q[1]-p[1]*q[0]},0));
 const edges=plan.edges.filter(e=>{const j=(e.index+1)%r.length;return (r[j][0]-r[e.index][0])*winding<-.02})
   .sort((a,b)=>r[a.index][1]+r[(a.index+1)%r.length][1]-r[b.index][1]-r[(b.index+1)%r.length][1]);
 for(const edge of edges){
   const i=edge.index,j=(i+1)%r.length,a=r[i],b=r[j],face=[a,b,t[j],t[i]];
   const dx=b[0]-a[0],dy=b[1]-a[1];
   const density=globalThis.__townDisplay?.compact ? globalThis.__moontownGoldenValleyCanvasLifecycle?.pixelRatio||1 : 1;
   if(f.z>.35&&Math.abs(dx)*density>3&&h*density>3&&edge.len>0){
     const texture=surface(u,plan,edge);
     c.save();c.transform(dx/texture.width,dy/texture.width,0,h/texture.height,a[0],a[1]-h);
     c.drawImage(texture,0,0);c.restore();
   }else poly(c,face,plan.colors.wall);
   const shade=Math.max(.02,.12+.10*edge.nx-.07*edge.nz);
   poly(c,face,'rgba(41,61,68,'+shade+')');
 }
 if(court.length){
   const top=court.map(([x,y])=>[x,y-h]);
   c.beginPath();
   for(const loop of [t,top]){loop.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath()}
   c.fillStyle=plan.colors.roof;c.fill('evenodd');
   c.save();c.beginPath();top.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.clip();
   poly(c,court,'#959e84');
   for(let i=0;i<court.length;i++){const j=(i+1)%court.length;if((top[j][0]-top[i][0])*winding>0)poly(c,[court[i],court[j],top[j],top[i]],plan.colors.base)}
   c.restore();
 } else poly(c,t,plan.colors.roof);
 if(plan.family==='xingke' && f.z>.15){
   for(const row of solarRows(plan,t))poly(c,row,'#475e66');
 }
 if(f.z>.35&&!court.length){
   if(u.plant===undefined)u.plant=roofPlant(plan);
   if(u.plant){const {weights,j,height}=u.plant,a=t[0],b=t[1],v=t[j];
     const lower=weights.map(([i,k])=>[a[0]+(b[0]-a[0])*i+(v[0]-a[0])*k,a[1]+(b[1]-a[1])*i+(v[1]-a[1])*k]);
     const upper=lower.map(([x,y])=>[x,y-height*h/u.h]);
     for(let i=0;i<4;i++)poly(c,[lower[i],lower[(i+1)%4],upper[(i+1)%4],upper[i]],plan.colors.base);
     poly(c,upper,plan.colors.trim);
   }
 }
 if(f.z>.35){
   c.save();c.beginPath();t.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();
   c.clip();c.strokeStyle=plan.colors.trim;c.lineWidth=1.5*f.z;c.stroke();c.restore();
 }
}
export function expandTrafficBand(bounds,depth,f) {
 for(const unit of rows.get(depth)||[]) {
   const height=unit.h*.68*f.z;
   for(const [,y] of projected(unit,f)) {
     bounds.top=Math.min(bounds.top,y-2*height-4);
     bounds.bottom=Math.max(bounds.bottom,y+height*.2+4);
   }
 }
}
export function drawDepth(ctx,depth,f){for(const u of rows.get(depth)||[])draw(ctx,u,f)}
export function drawNearer(ctx,position,f){for(let d=Math.floor(position[0]+position[1]);d<432;d++)for(const u of rows.get(d)||[])if(u.z>position[0]+position[1])draw(ctx,u,f)}
export function hit(x,y,f){for(const d of [...rows.keys()].sort((a,b)=>b-a)){const list=rows.get(d);for(let i=list.length-1;i>=0;i--){const u=list[i],r=projected(u,f),t=r.map(([a,b])=>[a,b-u.h*.68*f.z]);if(inside(t,x,y)||r.some((a,j)=>inside([a,r[(j+1)%r.length],t[(j+1)%r.length],t[j]],x,y)))return u.key}}return null}
export function focusDistrict(key){const units=projects.get(key),c=globalThis.__moontownGoldenValleyCamera,canvas=document.getElementById('energy-valley-canvas');if(!units||!c||!canvas)return false;
 delete c.streetTransition;
 const pts=units.flatMap(u=>u.ring.map(([x,y])=>[32*(x-y),16*(x+y)])),xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]),l=Math.min(...xs),r=Math.max(...xs),t=Math.min(...ys),b=Math.max(...ys);
 c.streetFollow=false;c.x=(l+r)/2;c.y=(t+b)/2-12;c.z=Math.min(2,Math.max(.2,Math.min((canvas.clientWidth-60)/(r-l+50),(canvas.clientHeight-110)/(b-t+60))));c.gentleTrialFramed=true;globalThis.__moontownGoldenValleyRender?.('district-focus');return true}
