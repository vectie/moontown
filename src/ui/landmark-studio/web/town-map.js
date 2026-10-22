import {loadTownTiles, decodeTile} from './town-tiles.js';

// Rendering boundary only. Placement, map registration, path search and actor
// movement are MoonBit. These are camera-matched renders of the original models,
// not rotated thumbnails and not a second terrain/road scene.
const tiles = new Map();
let selected, api, inspector, pins, status, progress, viewer;
let frameActor, baked = false, paused=false, pauseButton, stopButton;
document.documentElement.dataset.landmarkModels='loading';
const bridge = p => p.id.endsWith('bridge');
const screen = (p,f,h=0) => [f.w/2+(32*(p[0]-p[1])-f.cx)*f.z, f.h/2+(16*(p[0]+p[1])-f.cy-h)*f.z];
const render = () => globalThis.__moontownGoldenValleyRender?.('landmark-interaction');

function paint(ctx,p,t,f) {
  const [x,y]=screen([p.x,p.y],f);
  const transform=ctx.getTransform(),pixelRatio=Math.hypot(transform.a,transform.b)||1;
  const target=t.width*f.z*pixelRatio;
  let image=t.image;
  for(const level of t.levels){if(level.width<target)break;image=level;}
  ctx.save();ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
  ctx.drawImage(image,x+t.left*f.z,y-t.top*f.z,t.width*f.z,t.height*f.z);
  ctx.restore();
}

function paintApproaches(ctx,p,f) {
  // Short feathered shoulders, along the registered main-span axis only.
  // They do not move, simplify or replace any source road/navigation segment.
  const at=(u,v)=>screen([p.x+p.east[0]*u+p.south[0]*v,p.y+p.east[1]*u+p.south[1]*v],f);
  ctx.save();
  for(const sign of [-1,1]){
    const inner=sign*168,outer=sign*p.halfWidth;
    const a=at(inner,0),b=at(outer,0),fill=ctx.createLinearGradient(...a,...b);
    fill.addColorStop(0,'rgba(171,185,173,.96)');fill.addColorStop(.5,'rgba(180,190,169,.8)');fill.addColorStop(1,'rgba(180,190,169,0)');
    const half=p.halfDepth-1;
    const corners=[at(inner,-half),at(inner,half),at(outer,7),at(outer,-7)];
    ctx.beginPath();corners.forEach((v,i)=>i?ctx.lineTo(...v):ctx.moveTo(...v));ctx.closePath();ctx.fillStyle=fill;ctx.fill();
  }
  ctx.restore();
}

function focus(p) {
  selected=p;const c=globalThis.__moontownGoldenValleyCamera;
  if(c){c.x=32*(p.x-p.y);c.y=16*(p.x+p.y)-35;c.z=.95;c.gentleTrialFramed=true;}
  inspector.querySelector('h2').textContent=p.title;
  inspector.querySelector('.landmark-note').textContent=p.note;
  inspector.querySelector('[data-action="cross"]').hidden=!bridge(p);
  inspector.querySelector('[data-action="indoor"]').hidden=p.id!=='center';
  inspector.querySelector('[data-action="compute"]').hidden=p.id!=='center';
  inspector.querySelector('[data-action="study"]').textContent='打开原始 3D · 自由旋转';
  inspector.querySelectorAll('[data-place]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.place===p.id)));
  render();
}

function openStudy(kind) {
  globalThis.__moontownStudioOpen=true;
  const url = kind==='indoor' ? 'interior.html' : kind==='compute' ? 'datacenter.html' : `index.html#${selected.id}`;
  viewer=document.createElement('dialog');viewer.className='town-studio-dialog';
  const header=document.createElement('header');
  const title=document.createElement('strong');title.textContent=kind==='indoor'?'未来中心 → G3 室内设计研究':kind==='compute'?'未来中心 → 地下算力设计研究':selected.title+' · 原始 3D';
  const close=document.createElement('button');close.textContent='返回小镇 ×';close.onclick=()=>viewer.close();
  header.append(title,close);
  const frame=document.createElement('iframe');frame.title=title.textContent;frame.src=new URL(url,import.meta.url).href;
  frame.addEventListener('load',()=>{
    // Context label only; the standalone studies and geometry remain unchanged.
    try{const badge=frame.contentDocument?.querySelector('.stage');if(badge)badge.textContent='小镇空间门户 · 设计研究';}catch{/* External reference navigation has no parent access. */}
  });
  viewer.append(header,frame);document.body.append(viewer);viewer.addEventListener('close',()=>{viewer.remove();viewer=null;globalThis.__moontownStudioOpen=false;inspector.querySelector('[data-action="study"]').focus();render();},{once:true});viewer.showModal();close.focus();
}

function walk(a,b) {
  const result=api.walk(a,b);
  paused=false;pauseButton.textContent='暂停';pauseButton.hidden=stopButton.hidden=!result.ok;
  status.textContent=result.ok?'本地导航代理行走中 · 沿共享 OSM 节点':'路线不可达：未生成跨水直线';
  progress.hidden=!result.ok;
  document.documentElement.dataset.landmarkRoute=result.ok?'walking':'disconnected';
  render();
}

function setupUI() {
  inspector=document.createElement('section');inspector.className='town-landmark-inspector';inspector.setAttribute('aria-label','地标与三层空间');
  inspector.innerHTML=`<details open><summary>地标 · 三层空间 <span>3D → MAP</span></summary><div class="landmark-body"><nav aria-label="地标选择"></nav><h2>未来中心</h2><p class="landmark-note"></p><div class="landmark-actions"><button data-action="study">打开原始 3D · 自由旋转</button><button data-action="indoor">进入室内 · G3</button><button data-action="compute">进入地下 · 数据中心</button><button data-action="cross" hidden>代理过桥</button></div><div class="landmark-journey"><label>从 <select aria-label="步行起点"></select></label><label>到 <select aria-label="步行终点"></select></label><button data-action="walk">代理步行</button></div><progress max="1" value="0" hidden aria-label="步行进度"></progress><p class="landmark-status" role="status">本地导航演示 · 不代表远程 Agent 任务执行</p><small>室内 / 算力为设计门户，不声称真实楼层或机器位置。</small><button data-action="fit">查看全镇</button></div></details>`;
  const nav=inspector.querySelector('nav');
  for(const p of api.places){
    const b=document.createElement('button');b.dataset.place=p.id;b.textContent=p.title;b.onclick=()=>focus(p);nav.append(b);
    for(const select of inspector.querySelectorAll('select')){const o=document.createElement('option');o.value=p.id;o.textContent=p.title;select.append(o);}
  }
  const [from,to]=inspector.querySelectorAll('select');to.value='vision';
  pauseButton=document.createElement('button');pauseButton.textContent='暂停';pauseButton.hidden=true;
  pauseButton.onclick=()=>{paused=!paused;api.playback(paused?'pause':'resume');pauseButton.textContent=paused?'继续':'暂停';render();};
  stopButton=document.createElement('button');stopButton.textContent='结束步行';stopButton.hidden=true;
  stopButton.onclick=()=>{api.playback('stop');pauseButton.hidden=stopButton.hidden=true;progress.hidden=true;status.textContent='本地导航演示已结束';document.documentElement.dataset.landmarkRoute='stopped';render();};
  inspector.querySelector('.landmark-journey').append(pauseButton,stopButton);
  for(const b of inspector.querySelectorAll('[data-action]'))b.onclick=()=>{
    const a=b.dataset.action;
    if(['study','indoor','compute'].includes(a))openStudy(a);
    if(a==='walk')walk(from.value,to.value);
    if(a==='cross')walk(selected.id,selected.id);
    if(a==='fit'){const c=globalThis.__moontownGoldenValleyCamera;if(c)c.gentleTrialFramed=false;render();}
  };
  status=inspector.querySelector('.landmark-status');progress=inspector.querySelector('progress');
  selected=api.places[0];inspector.querySelector('.landmark-note').textContent=selected.note;
  inspector.querySelector('[data-place="center"]').setAttribute('aria-pressed','true');
  pins=document.createElement('div');pins.className='town-landmark-pins';
  for(const p of api.places){const b=document.createElement('button');b.textContent=p.title;b.dataset.place=p.id;b.onclick=()=>focus(p);pins.append(b);}
  document.body.append(inspector,pins);
  if(innerWidth<700)inspector.querySelector('details').open=false;
  const townRoot=document.getElementById('app');
  if(townRoot)new MutationObserver(()=>{
    const map=document.getElementById('energy-valley-canvas');
    inspector.hidden=pins.hidden=!map||map.offsetParent===null;
  }).observe(townRoot,{childList:true,subtree:true});
}

async function install() {
  if(baked||!globalThis.__townLandmarks)return;
  baked=true;api=globalThis.__townLandmarks;
  try {
    const records=await loadTownTiles(api.places);
    for(const p of api.places){
      const record=records.find(r=>r.id===p.id);
      const tile=await decodeTile(record), front=record.front?await decodeTile(record.front):null;
      tiles.set(p.id,{...tile,front,depth:Math.floor(p.x+p.y)});
      // Yield between expensive studies; no continuous WebGL renderer on map.
      await new Promise(resolve=>requestAnimationFrame(resolve));
    }
    setupUI();
    globalThis.__townLandmarkPainter.ready=true;
    document.documentElement.dataset.landmarkModels='ready';render();
  } catch(error) {
    console.error('Landmark projection unavailable',error);
    document.documentElement.dataset.landmarkModels='error';
    const notice=document.createElement('p');notice.className='town-landmark-error';notice.textContent='3D 地标未载入；原地图保留。刷新可重试。';document.body.append(notice);
  }
}

globalThis.__townLandmarkPainter={ready:false,
  draw(ctx,depth,cx,cy,z,w,h){
    if(!this.ready)return;
    const f={cx,cy,z,w,h};
    for(const p of api.places){const t=tiles.get(p.id);if(t.depth===depth){if(bridge(p))paintApproaches(ctx,p,f);paint(ctx,p,t,f);}}
    if(depth===431){
      const rect=document.getElementById('energy-valley-canvas')?.getBoundingClientRect();
      if(!rect)return;
      for(const b of pins.children){const p=api.places.find(p=>p.id===b.dataset.place);const [x,y]=screen([p.x,p.y],f);b.style.left=`${rect.left+x}px`;b.style.top=`${rect.top+y+18}px`;b.hidden=x<0||x>w||y<0||y>h||z<.13;}
    }
  },
  drawRoute(ctx,path,position,done,cx,cy,z,w,h,drawAgent){
    if(!this.ready)return;
    const f={cx,cy,z,w,h};frameActor={position,progress:done};
    const selectedBridge=api.places.find(p=>bridge(p)&&insideBridge(position,p));
    // Bridge deck is the registered road plane; model piers extend below it.
    const elevation=0;
    ctx.save();ctx.beginPath();for(let i=0;i<path.length;i++){const a=screen(path[i],f);i?ctx.lineTo(...a):ctx.moveTo(...a);}ctx.strokeStyle='#4d8174';ctx.lineWidth=2;ctx.setLineDash([4,5]);ctx.stroke();ctx.setLineDash([]);
    const [x,y]=screen(position,f,elevation);
    drawAgent(x,y);
    // Redraw nearer architecture; on a bridge only the near rail/rib pass may
    // occlude the walker. The deck can never paint over the actor's feet.
    for(const p of api.places){const t=tiles.get(p.id);if(selectedBridge?.id===p.id){paint(ctx,p,t.front,f);}else if(p.x+p.y>position[0]+position[1]){paint(ctx,p,t,f);}}
    ctx.restore();
    progress.value=done;
    const label=done>=1?'已到达 · 可打开对应空间门户':paused?'已暂停 · 路线位置保留':'本地导航代理行走中 · 沿共享 OSM 节点';
    if(status.textContent!==label)status.textContent=label;
    document.documentElement.dataset.landmarkRoute=done>=1?'arrived':paused?'paused':'walking';
  },
  inspect(){return {ready:this.ready,places:api?.places,actor:frameActor,tiles:[...tiles].map(([id,t])=>({id,width:t.width,height:t.height,depth:t.depth}))};}
};
function insideBridge(pos,p){
  const dx=pos[0]-p.x,dy=pos[1]-p.y,[a,b]=p.east,[c,d]=p.south,det=a*d-b*c;
  const u=(dx*d-dy*c)/det,v=(dy*a-dx*b)/det;
  return Math.abs(u)<p.halfWidth && Math.abs(v)<p.halfDepth;
}
addEventListener('town-landmarks-ready',install);
addEventListener('load',install,{once:true});install();
