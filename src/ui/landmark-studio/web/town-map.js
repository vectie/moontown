import {forCanvas, pushMap, restoreCamera} from './town-camera.js';
import * as surroundings from './town-region.js';
import {loadTownTiles, decodeTile} from './town-tiles.js';
import * as traffic from './town-traffic.js';
import * as districts from './district-ground.js';

// Rendering boundary only. Placement, map registration, path search and actor
// movement are MoonBit. These are camera-matched renders of the original models,
// not rotated thumbnails and not a second terrain/road scene.
const tiles = new Map();
let selected, api, inspector, pins, status, progress, viewer, buildingPicker;
let volumes = [];
const volumesByDepth = new Map();
let reviewingSite=new URLSearchParams(location.search).get('site-review')==='1';
let siteToggle, districtSelection, districtNames;
let frameActor, baked = false, paused=false, pauseButton, stopButton;
document.documentElement.dataset.landmarkModels='loading';
const bridge = p => p.id.endsWith('bridge');
const screen = (p,f,h=0) => [f.w/2+(32*(p[0]-p[1])-f.cx)*f.z, f.h/2+(16*(p[0]+p[1])-f.cy-h)*f.z];
const render = () => globalThis.__moontownGoldenValleyRender?.('landmark-interaction');
// Same 24px, 1.7px rounded outline language as the native town controls.
const icon = name => `<svg class="town-ui-svg" aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="${{
  layers:'M12 2 2 7l10 5 10-5zM2 12l10 5 10-5M2 17l10 5 10-5',
  cube:'M12 2 2 7v10l10 5 10-5V7zM2 7l10 5 10-5M12 12v10',
  indoor:'M4 22V3h16v19M2 22h20M9 22V9h6v13M12 14h.01',
  server:'M3 3h18v7H3zM3 14h18v7H3zM6 6h1M6 17h1M11 6h7M11 17h7',
  fit:'M3 8V3h5M16 3h5v5M21 16v5h-5M8 21H3v-5',
  sliders:'M4 3v6m0 6v6M12 3v12m0 4v2M20 3v2m0 6v10M1 9h6v6H1zM9 15h6v4H9zM17 5h6v6h-6z',
  back:'M15 5l-7 7 7 7M8 12h13',
}[name]}"></path></svg>`;

function paint(ctx,p,t,f) {
  const [x,y]=screen([p.x,p.y],f);
  const transform=ctx.getTransform(),pixelRatio=Math.hypot(transform.a,transform.b)||1;
  if(x+(t.left+t.width)*f.z<0||x+t.left*f.z>f.w||y-t.top*f.z>f.h||y+(t.height-t.top)*f.z<0)return;
  const target=t.width*f.z*pixelRatio;
  let image=t.image;
  for(const level of t.levels){if(level.width<target)break;image=level;}
  ctx.save();ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
  if(reviewingSite && p.component)ctx.globalAlpha*=.36;
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

function focus(p, building=null) {
  districtSelection=null;
  inspector.querySelector('[data-action="wlxk"]').hidden=true;
  selected=p;const c=globalThis.__moontownGoldenValleyCamera;
  document.querySelector('[aria-label="关闭建筑详情"]')?.click();
  const summary=inspector.querySelector('summary');
  summary.querySelector('b').textContent=p.id==='vision'?'视界':'地标';
  summary.title=p.title;summary.setAttribute('aria-label',p.title+' · 地标与三层空间');
  inspector.querySelector('details').open=innerWidth>=700;
  const members=building?[building]:p.buildings.length?p.buildings:[p];
  const xs=members.map(m=>32*(m.x-m.y)), ys=members.map(m=>16*(m.x+m.y));
  if(c){
    delete c.streetTransition;
    c.streetFollow=false;
    c.x=(Math.min(...xs)+Math.max(...xs))/2; c.y=(Math.min(...ys)+Math.max(...ys))/2-25;
    const canvas=document.querySelector('#energy-valley-canvas');
    const groupFit=canvas?Math.min((canvas.clientWidth-48)/(Math.max(...xs)-Math.min(...xs)+90),
      (canvas.clientHeight-100)/(Math.max(...ys)-Math.min(...ys)+115)):1;
    c.z=building?1.8:p.buildings.length?Math.max(.35,Math.min(1.65,groupFit)):.95;
    const tile=!building&&tiles.get(p.id);
    if(tile && !bridge(p) && canvas){
      const usableWidth=canvas.clientWidth*(canvas.clientWidth>700?.72:.9);
      c.z=Math.max(.35,Math.min(2.3,usableWidth/tile.width,(canvas.clientHeight-120)/tile.height));
      c.x+=tile.left+tile.width/2;
      c.y=ys[0]-tile.top+tile.height/2;
    }
    c.gentleTrialFramed=true;
  }
  inspector.querySelector('.landmark-advanced').hidden=false;
  buildingPicker.hidden=!p.buildings.length;
  siteToggle.hidden=!p.buildings.length;
  buildingPicker.value=building?.id||'center';
  inspector.querySelector('select[aria-label="步行终点"]').value=building?.id||p.id;
  inspector.querySelector('h2').textContent=p.title;
  inspector.querySelector('.landmark-note').textContent=p.note;
  inspector.querySelector('[data-action="cross"]').hidden=!bridge(p);
  inspector.querySelector('[data-action="indoor"]').hidden=p.id!=='center';
  inspector.querySelector('[data-action="compute"]').hidden=p.id!=='center';
  inspector.querySelectorAll('[data-place]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.place===p.id)));
  render();
}

function openStudy(kind, district='', landmark=selected, unit='', fromHistory=false) {
  if (kind === 'indoor' || kind === 'compute') {
    const deliver = globalThis.__moonTownSpaceDeliver;
    if (deliver) {
      // The same town route owns the task, selection and return path.
      deliver('open-center');
      if (kind === 'compute') deliver('open-compute');
    } else {
      const route = new URL(location.href);
      route.searchParams.set('layer', kind === 'compute' ? 'compute' : 'indoor');
      route.searchParams.set('building', 'future-center-g3');
      location.assign(route);
    }
    return;
  }
  const tour=kind==='wlxk';
  const studyId=tour?'wlxk':kind==='district'?'district/'+(district||'huiyuan'):'landmark/'+landmark.id;
  if(viewer?.dataset.study===studyId)return;
  if(viewer)viewer.close();
  if(!fromHistory){
    const next=new URL(location.href);next.searchParams.set('study',studyId);
    if(unit)next.searchParams.set('unit',unit);else next.searchParams.delete('unit');
    pushMap(next);
    history.replaceState({...history.state,townViewerFrom:true},'');
  }
  globalThis.__moontownStudioOpen=true;
  const url = tour?'wlxk.html':kind==='district'?'districts.html'+(unit?'?unit='+encodeURIComponent(unit):'')+'#'+encodeURIComponent(district||'huiyuan'):kind==='indoor' ? 'interior.html' : kind==='compute' ? 'datacenter.html' : `index.html#${landmark.id}`;
  const dialog=document.createElement('dialog');viewer=dialog;dialog.className='town-studio-dialog';dialog.dataset.study=studyId;
  const header=document.createElement('header');
  const title=document.createElement('strong');title.textContent=tour?'能源谷漫游':kind==='district'?'住宅与园区':kind==='indoor'?'未来中心 · 室内':kind==='compute'?'数据中心 · 3D':landmark.title+' · 3D';
  const close=document.createElement('button');close.innerHTML=icon('back')+'<span>小镇</span>';close.title='返回小镇';close.setAttribute('aria-label','返回小镇');const leave=()=>{
    if(history.state?.townViewerFrom && document.getElementById('street-overview'))history.back();
    else{const u=new URL(location.href);u.searchParams.delete('study');u.searchParams.delete('unit');history.replaceState(history.state,'',u);dialog.close()}
  };close.onclick=leave;dialog.addEventListener('cancel',event=>{event.preventDefault();leave()});

  header.append(title,close);
  const frame=document.createElement('iframe');frame.title=title.textContent;frame.src=new URL(url,import.meta.url).href;
  viewer.append(header,frame);document.body.append(viewer);dialog.addEventListener('close',()=>{dialog.remove();if(viewer!==dialog)return;viewer=null;globalThis.__moontownStudioOpen=false;inspector?.querySelector(tour && districtSelection==='xingke'?'[data-action="wlxk"]':'[data-action="study"]')?.focus();render();},{once:true});dialog.showModal();close.focus();
}

function walk(a,b) {
  const result=api.walk(a,b);
  frameActor=null;
  paused=false;pauseButton.textContent='暂停';pauseButton.hidden=stopButton.hidden=!result.ok;
  status.hidden=false;
  status.textContent=result.ok?'演示角色行走中':'没有可通行路线，请更换起点或终点。';
  progress.hidden=!result.ok;
  document.documentElement.dataset.landmarkRoute=result.ok?'walking':'disconnected';
  render();
}

function installBuildingPicking() {
  // The town can replace its canvas between frames. Delegate on the stable
  // window and let drags, paint tools and empty ground reach normal controls.
  let start=null;
  addEventListener('pointerdown',e=>{
    start=e.isPrimary && e.button===0 && e.target.id==='energy-valley-canvas'
      ? {id:e.pointerId,x:e.clientX,y:e.clientY}:null;
  },true);
  addEventListener('pointermove',e=>{
    if(start?.id===e.pointerId && Math.hypot(e.clientX-start.x,e.clientY-start.y)>4)start=null;
  },true);
  addEventListener('pointercancel',()=>{start=null},true);
  addEventListener('click',e=>{
    const tap=start;start=null;
    if(!tap||e.target.id!=='energy-valley-canvas'||!e.isTrusted||e.target.dataset.townGesture==='drag')return;
    if(e.target.dataset.townTool && e.target.dataset.townTool!=='inspect')return;
    const camera=globalThis.__moontownGoldenValleyCamera;
    if(camera && globalThis.__townLandmarkPainter.pick(e.clientX,e.clientY,e.target,camera)){
      e.preventDefault();
      e.stopImmediatePropagation();
    }
  },true);
}

function setupUI() {
  inspector=document.createElement('section');inspector.className='town-landmark-inspector';inspector.setAttribute('aria-label','地标与三层空间');
  inspector.innerHTML=`<details name="moontown-hud-disclosure"><summary title="地标与三层空间" aria-label="地标与三层空间">${icon('layers')}<b>地标</b></summary><div class="landmark-body"><nav aria-label="地标选择"></nav><div class="landmark-heading"><div><span class="landmark-design-badge">设计模型</span><h2>未来中心</h2></div><button data-action="fit" title="查看全镇" aria-label="查看全镇">${icon('fit')}</button></div><div class="landmark-actions"><button data-action="study" title="查看完整 3D 模型，自由旋转" aria-label="查看完整 3D 模型">${icon('cube')}<span>3D</span></button><button data-action="indoor" title="室内设计模型" aria-label="室内设计模型">${icon('indoor')}<span>室内</span></button><button data-action="compute" title="数据中心设计模型" aria-label="数据中心设计模型">${icon('server')}<span>地下</span></button></div><progress max="1" value="0" hidden aria-label="步行进度"></progress><p class="landmark-status" role="status" hidden></p><details class="landmark-advanced"><summary title="步行演示与模型说明" aria-label="Advanced · 步行演示与模型说明">${icon('sliders')}<span>高级</span></summary><div class="landmark-journey"><label>从 <select aria-label="步行起点"></select></label><label>到 <select aria-label="步行终点"></select></label><button data-action="walk">演示步行</button><button data-action="cross" hidden>演示过桥</button></div><p class="landmark-note"></p><small>本地步行演示，不执行远程任务。室内与数据中心为设计模型，不代表实际楼层或机器位置。</small></details></div></details>`;
  inspector.querySelector('details').addEventListener('toggle',()=>{
    if(inspector.querySelector('details').open)document.querySelector('[aria-label="关闭建筑详情"]')?.click();
  });
  const tour=document.createElement('button');
  tour.dataset.action='wlxk';tour.textContent='能源谷漫游';tour.hidden=true;
  inspector.querySelector('[data-action="study"]').after(tour);
  const nav=inspector.querySelector('nav');
  for(const p of api.places){
    const b=document.createElement('button');b.dataset.place=p.id;b.textContent=({center:'中心',vision:'视界','east-bridge':'东路桥','arch-bridge':'路桥'})[p.id]||p.title;b.title=p.title;b.setAttribute('aria-label',p.title);b.onclick=()=>{setMapDestination(p.id);focus(p)};nav.append(b);
    for(const select of inspector.querySelectorAll('.landmark-journey select')){
      for(const destination of [p,...p.buildings])select.add(new Option(destination.title,destination.id));
    }
  }
  const directory=document.createElement('button');directory.textContent='住宅与园区';directory.onclick=()=>openStudy('district');nav.after(directory);
  const [from,to]=inspector.querySelectorAll('.landmark-journey select');to.value='vision';
  const campus=api.places.find(p=>p.id==='center');
  siteToggle=document.createElement('button');
  siteToggle.textContent='街坊与楼栋占地';
  siteToggle.title='按街道和影像复核，边界为道路中心线';
  siteToggle.setAttribute('aria-pressed',String(reviewingSite));
  siteToggle.onclick=()=>{reviewingSite=!reviewingSite;siteToggle.setAttribute('aria-pressed',String(reviewingSite));render();};
  inspector.querySelector('.landmark-journey').before(siteToggle);
  buildingPicker=document.createElement('select');
  buildingPicker.setAttribute('aria-label','未来中心楼栋');
  buildingPicker.add(new Option('全园','center'));
  for(const b of campus.buildings)buildingPicker.add(new Option(b.title,b.id));
  buildingPicker.onchange=()=>{const b=campus.buildings.find(b=>b.id===buildingPicker.value);setMapDestination('center',false,b?.id);focus(campus,b)};
  inspector.querySelector('.landmark-heading').after(buildingPicker);
  pauseButton=document.createElement('button');pauseButton.textContent='暂停';pauseButton.hidden=true;
  pauseButton.onclick=()=>{paused=!paused;api.playback(paused?'pause':'resume');pauseButton.textContent=paused?'继续':'暂停';render();};
  stopButton=document.createElement('button');stopButton.textContent='结束步行';stopButton.hidden=true;
  stopButton.onclick=()=>{api.playback('stop');frameActor=null;pauseButton.hidden=stopButton.hidden=true;progress.hidden=true;status.textContent='本地导航演示已结束';document.documentElement.dataset.landmarkRoute='stopped';render();};
  inspector.querySelector('.landmark-journey').append(pauseButton,stopButton);
  for(const b of inspector.querySelectorAll('[data-action]'))b.onclick=()=>{
    const a=b.dataset.action;
    if(a==='wlxk')openStudy('wlxk');
    else if(a==='study'&&districtSelection)openStudy('district',districtSelection);
    else if(['study','indoor','compute'].includes(a))openStudy(a);
    if(a==='walk')walk(from.value,to.value);
    if(a==='cross')walk(selected.id,selected.id);
    if(a==='fit'){
      inspector.querySelector('details').open=false;
      const button=document.getElementById('street-overview');
      const camera=globalThis.__moontownGoldenValleyCamera;
      if(button?.getAttribute('aria-pressed')==='false'){if(camera)camera.streetRefit=true;button.click()}
      else if(camera){
        if(button){setMapDestination('',false,'',true);camera.streetRefit=true;}
        else camera.gentleTrialFramed=false;
        render();
      }
    }
  };
  status=inspector.querySelector('.landmark-status');progress=inspector.querySelector('progress');
  selected=api.places[0];inspector.querySelector('.landmark-note').textContent=selected.note;
  inspector.querySelector('[data-place="center"]').setAttribute('aria-pressed','true');
  pins=document.createElement('div');pins.className='town-landmark-pins';
  for(const p of api.places){const b=document.createElement('button');b.textContent=p.title;b.dataset.place=p.id;b.onclick=()=>{setMapDestination(p.id);focus(p)};pins.append(b);}
  document.body.append(inspector,pins);
  if(innerWidth<700)inspector.querySelector('details').open=false;
  const townRoot=document.getElementById('app');
  if(townRoot)new MutationObserver(()=>{
    const map=document.getElementById('energy-valley-canvas');
    inspector.hidden=pins.hidden=!map||map.offsetParent===null;
    if(document.querySelector('.knowledge-library-inspector'))inspector.querySelector('details').open=false;
  }).observe(townRoot,{childList:true,subtree:true});
}

async function install() {
  if(baked||!globalThis.__townLandmarks)return;
  baked=true;api=globalThis.__townLandmarks;
  try {
    volumes=api.places.flatMap(p=>p.buildings.length?p.buildings:[p]).sort((a,b)=>a.x+a.y-b.x-b.y);
    const records=await loadTownTiles(volumes);
    for(const p of volumes){
      const record=records.find(r=>r.id===p.id);
      const tile=await decodeTile(record), front=record.front?await decodeTile(record.front):null;
      const depth=Math.floor(p.x+p.y);
      tiles.set(p.id,{...tile,front,depth});
      if(!volumesByDepth.has(depth))volumesByDepth.set(depth,[]);
      volumesByDepth.get(depth).push(p);
      // Yield between expensive studies; no continuous WebGL renderer on map.
      await new Promise(resolve=>requestAnimationFrame(resolve));
    }
    setupUI();
    installBuildingPicking();
    globalThis.__townLandmarkPainter.ready=true;
    traffic.loadTraffic().then(render).catch(e=>console.warn('Street activity unavailable:',e));
    districts.loadDistricts().then(()=>{
      surroundings.registerTown(api.places.find(p=>p.id==='vision'));
      directoryReady=true;
      applyMapRoute();
      dispatchEvent(new Event('town-districts-ready'));
      render();
    }).catch(error=>console.warn('District geometry unavailable:',error));
    document.documentElement.dataset.landmarkModels='ready';
    const requested=new URLSearchParams(location.search).get('landmarks');
    const place=api.places.find(p=>p.id===requested || p.buildings.some(b=>b.id===requested));
    if(place&&!history.state?.townCamera)focus(place,place.buildings.find(b=>b.id===requested));
    render();
  } catch(error) {
    console.error('Landmark projection unavailable',error);
    document.documentElement.dataset.landmarkModels='error';
    const notice=document.createElement('p');notice.className='town-landmark-error';notice.textContent='3D 地标未载入；原地图保留。刷新可重试。';document.body.append(notice);
  }
}

const regionRequest=new URLSearchParams(location.search);
let shoreReview=regionRequest.get('shore-review')==='1', shoreGeometry, shoreRequest;
function loadShoreGeometry(){
  return shoreRequest??=fetch(new URL('./town-road-review.json',import.meta.url))
    .then(response=>{if(!response.ok)throw new Error('Road geometry unavailable');return response.json()})
    .then(data=>{shoreGeometry=data;return data})
    .catch(error=>{shoreRequest=null;throw error});
}
function reviewRoads(way){
  if(!shoreReview && !way)return;
  loadShoreGeometry().then(data=>{
    const focus=way && data.focus[way], camera=globalThis.__moontownGoldenValleyCamera;
    if(focus && camera && new URLSearchParams(location.search).get('road')===way && !history.state?.townCamera){
      delete camera.streetTransition;camera.streetFollow=false;camera.gentleTrialFramed=true;
      camera.x=32*(focus[0]-focus[1]);camera.y=16*(focus[0]+focus[1]);camera.z=1.05;
      if(inspector)inspector.querySelector('details').open=false;
    }
    document.documentElement.dataset.shoreReview=shoreReview?'on':'off';
    render();
  }).catch(()=>{
    const status=document.getElementById('street-walk-status');
    if(status)status.textContent='路网复核未载入，请重试';
    shoreReview=false;
    const url=new URL(location.href);url.searchParams.delete('shore-review');history.replaceState(history.state,'',url);
    document.getElementById('street-shore-review')?.setAttribute('aria-pressed','false');
    document.documentElement.dataset.shoreReview='error';
  });
}
document.addEventListener('click',event=>{
  const control=event.target.closest?.('#street-shore-review');
  if(!control)return;
  shoreReview=!shoreReview;
  control.setAttribute('aria-pressed',String(shoreReview));
  const url=new URL(location.href);
  if(shoreReview)url.searchParams.set('shore-review','1');else url.searchParams.delete('shore-review');
  history.replaceState(history.state,'',url);
  if(shoreReview)reviewRoads();else {document.documentElement.dataset.shoreReview='off';render()}
});
function drawRoadReview(ctx,f){
  const visible=(x,y)=>x>=-8 && x<=f.w+8 && y>=-8 && y<=f.h+8;
  ctx.save();ctx.lineCap='round';ctx.lineWidth=Math.max(2,4*f.z);ctx.strokeStyle='#c64f3d';
  ctx.beginPath();
  for(const [ax,ay,bx,by] of shoreGeometry.contacts){
    const [x,y]=screen([ax,ay],f),[u,v]=screen([bx,by],f);
    if(Math.max(x,u)<-8 || Math.max(y,v)<-8 || Math.min(x,u)>f.w+8 || Math.min(y,v)>f.h+8)continue;
    ctx.moveTo(x,y);ctx.lineTo(u,v);
  }
  ctx.stroke();ctx.lineWidth=2;ctx.strokeStyle='#673e72';
  for(const [gx,gy,lost] of shoreGeometry.crossings){
    const [x,y]=screen([gx,gy],f);if(!visible(x,y))continue;
    ctx.beginPath();
    if(lost){ctx.moveTo(x-4,y-4);ctx.lineTo(x+4,y+4);ctx.moveTo(x+4,y-4);ctx.lineTo(x-4,y+4)}
    else ctx.arc(x,y,4,0,Math.PI*2);
    ctx.stroke();
  }
  ctx.restore();
}
let directoryReady=false, directoryPicker, routeGeneration=0;
const regionalLandmarks={center:'未来中心',vision:'未来视界','east-bridge':'未来科学城东路桥','arch-bridge':'未来科学城路桥'};
function focusInTown(id, component){
  const place=api?.places.find(p=>p.id===id);
  if(place&&inspector){focus(place,place.buildings.find(b=>b.id===component));return true}
  const host=projectList?.find(p=>p.id===id)?.host;
  if(!districts.focusDistrict(host||id) && !surroundings.locate(id,document.getElementById('energy-valley-canvas'),globalThis.__moontownGoldenValleyCamera))return false;
  render();
  districtSelection=id;
  inspector.querySelector('[data-action="wlxk"]').hidden=id!=='xingke';
  const summary=inspector.querySelector('summary');
  summary.querySelector('b').textContent=id==='xingke'?'星科':'园区';
  summary.title='住宅与园区';summary.setAttribute('aria-label','住宅与园区');
  inspector.querySelector('details').open=innerWidth>=700;
  inspector.querySelector('h2').textContent='住宅与园区';
  for(const el of inspector.querySelectorAll('[data-action="indoor"],[data-action="compute"],.landmark-advanced'))el.hidden=true;
  buildingPicker.hidden=siteToggle.hidden=true;
  inspector.querySelectorAll('[data-place]').forEach(b=>b.setAttribute('aria-pressed','false'));
  districtNames??=fetch(new URL('district-studies.json',import.meta.url)).then(r=>r.json())
    .then(db=>new Map(db.catalog.projects.map(s=>[s.id,s.name]))).catch(()=>{districtNames=null;return new Map()});
  districtNames.then(names=>{
    if(districtSelection!==id||!names.has(id))return;
    const title=names.get(id);inspector.querySelector('h2').textContent=title;
    summary.title=title;summary.setAttribute('aria-label',title+' · 地标');
  });
  return true;
}
let projectList;
async function projects(){
  projectList=await surroundings.directory();
  return projectList;
}
function setMapDestination(id, picker=false, component='', refit=false){
  const u=new URL(location.href);
  const button=document.getElementById('street-overview');
  if(button)u.searchParams.set('view',button.getAttribute('aria-pressed')==='true'?'overview':'living-room');
  for(const k of ['projects','district','road','landmarks','study','unit'])u.searchParams.delete(k);
  if(id)u.searchParams.set('district',id);else if(picker)u.searchParams.set('projects','1');
  if(component)u.searchParams.set('landmarks',component);
  pushMap(u,refit);
}
async function showProjects(){
  const list=await projects();
  if(!directoryPicker){
    directoryPicker=document.createElement('select');
    directoryPicker.setAttribute('aria-label','定位项目');directoryPicker.className='street-button town-project-picker';
    directoryPicker.add(new Option('选择项目',''));
    for(const [id,name] of Object.entries(regionalLandmarks))directoryPicker.add(new Option(name,id));
    for(const p of list)if(!regionalLandmarks[p.id])directoryPicker.add(new Option(p.name,p.id));
    directoryPicker.onchange=()=>{if(directoryPicker.value)visitDistrict(directoryPicker.value).catch(projectError)};
  }
  const mount=document.querySelector('.street-walk-hud');
  if(mount){mount.append(directoryPicker);directoryPicker.hidden=false;directoryPicker.focus()}
}
async function visitDistrict(key){
  viewer?.close();const n=++routeGeneration;
  await projects();if(n!==routeGeneration)return;
  setMapDestination(key);
  if(directoryPicker)directoryPicker.hidden=true;
  focusInTown(key);
}
function applyMapRoute(){
  const n=++routeGeneration;if(!directoryReady)return;
  const q=new URLSearchParams(location.search);
  const study=q.get('study');
  if(!study)viewer?.close();
  else if(study==='wlxk')openStudy('wlxk','',selected,'',true);
  else if(study.startsWith('district/'))openStudy('district',study.slice(9),selected,q.get('unit')||'',true);
  else if(study.startsWith('landmark/')){const p=api.places.find(p=>p.id===study.slice(9));if(p)openStudy('study','',p,'',true)}
  if(directoryPicker)directoryPicker.hidden=true;
  if(!q.has('district')&&inspector)inspector.querySelector('details').open=false;
  if(q.has('district')||q.has('projects')){
    projects().then(()=>{if(n!==routeGeneration)return;
      if(q.has('district'))focusInTown(q.get('district'),q.get('landmarks'));else showProjects();
      restoreCamera();
    }).catch(projectError);
  }else if(!restoreCamera())reviewRoads(q.get('road'));
}
function projectError(){const status=document.getElementById('street-walk-status');if(status)status.textContent='项目暂未载入，请重试'}
addEventListener('town-map-route',applyMapRoute);
document.addEventListener('click',event=>{
  if(!event.target.closest?.('#street-project-distribution')||event.button!==0||event.ctrlKey||event.metaKey||event.shiftKey||event.altKey)return;
  event.preventDefault();
  if(!directoryReady)return;
  if(directoryPicker?.isConnected && !directoryPicker.hidden){directoryPicker.hidden=true;setMapDestination('');return}
  setMapDestination('',true);showProjects().catch(projectError);
});
globalThis.__townLandmarkPainter={ready:false,
  districtReserved:districts.reserved, districtReady:districts.ready,
  warmGround:surroundings.warmGround,
  drawSurroundings(ctx,cx,cy,z,w,h){surroundings.ground(ctx,{cx,cy,z,w,h})},
  openXingkeTour(){openStudy('wlxk')},
  visitDistrict(key){visitDistrict(key).catch(projectError);return true},
  expandTrafficBand(bounds, first, last, f) {
    for(let d=first;d<=last;d++) {
      for(const p of volumesByDepth.get(d)||[]) {
        const tile=tiles.get(p.id), y=screen([p.x,p.y],f)[1];
        bounds.top=Math.min(bounds.top,y-(tile.top+128)*f.z);
        bounds.bottom=Math.max(bounds.bottom,y+(tile.height-tile.top+128)*f.z);
      }
      districts.expandTrafficBand(bounds,d,f);
    }
  },
  trafficStats:traffic.stats,
  trafficLayers:traffic.layers,
  canWalkDistrict(key){return api?.route('center','district:'+key)?.ok===true},
  walkDistrict(key){if(!this.canWalkDistrict(key))return false;viewer?.close();setMapDestination(key);walk('center','district:'+key);inspector.querySelector('details').open=true;return true},
  draw(ctx,depth,cx,cy,z,w,h,seconds,reduced,hour){
    if(!this.ready)return;
    const f={cx,cy,z,w,h};
    if(depth===0 && shoreReview && shoreGeometry)drawRoadReview(ctx,f);
    if(depth===0 && reviewingSite){
      const campus=api.places.find(p=>p.id==='center');
      const colors={'excluded-west':'#817969',west:'#659187','middle-west':'#477b9b','middle-east':'#477b9b',east:'#8f6d9a'};
      const polygon=(ring,color,opacity)=>{
        ctx.beginPath();for(const [i,point] of ring.entries()){const [x,y]=screen(point,f);if(i)ctx.lineTo(x,y);else ctx.moveTo(x,y);}
        ctx.closePath();ctx.fillStyle=color;ctx.globalAlpha=opacity;ctx.fill();ctx.globalAlpha=.95;ctx.strokeStyle=color;ctx.stroke();
      };
      ctx.save();ctx.lineWidth=Math.max(1,f.z);
      for(const block of campus.blocks)polygon(block.ring,colors[block.id],.18);
      for(const b of campus.buildings)polygon(b.footprint,'#163f42',.24);
      ctx.restore();
    }
    if(depth===0){if(!traffic.layers.recording())traffic.prepare(f,seconds,reduced,hour);districts.setHour(hour);traffic.draw(ctx,-1,f);surroundings.drawBuildings(ctx,f)}
    traffic.draw(ctx,depth,f);districts.drawDepth(ctx,depth,f);
    const row=volumesByDepth.get(depth);
    if(row)for(const p of row){if(bridge(p))paintApproaches(ctx,p,f);paint(ctx,p,tiles.get(p.id),f);}
    if(depth===431)this.projectPins(f);
  },
  wheelArtBlocked(){return reviewingSite||!!shoreReview||!!frameActor?.position},
  projectPins(f){
    if(!pins||!api)return;const {w,h,z}=f;
      const rect=document.getElementById('energy-valley-canvas')?.getBoundingClientRect();
      if(!rect)return;
      for(const b of pins.children){const p=api.places.find(p=>p.id===b.dataset.place);const [x,y]=screen([p.x,p.y],f);b.style.left=`${rect.left+x}px`;b.style.top=`${rect.top+forCanvas(document.getElementById('energy-valley-canvas')).screenY(x,y)+18}px`;b.hidden=x<0||x>w||y<0||y>h||z<.13;}
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
    districts.drawNearer(ctx,position,f);
    // Redraw nearer architecture; on a bridge only the near rail/rib pass may
    // occlude the walker. The deck can never paint over the actor's feet.
    for(const p of volumes){const t=tiles.get(p.id);if(selectedBridge?.id===p.id){paint(ctx,p,t.front,f);}else if(p.x+p.y>position[0]+position[1]){paint(ctx,p,t,f);}}
    ctx.restore();
    progress.value=done;
    const label=done>=1?'演示已到达':paused?'演示已暂停':'演示角色行走中';
    if(status.textContent!==label)status.textContent=label;
    document.documentElement.dataset.landmarkRoute=done>=1?'arrived':paused?'paused':'walking';
  },
  pick(clientX,clientY,canvas,camera){
    if(!this.ready)return false;
    const rect=canvas.getBoundingClientRect();
    const v=forCanvas(canvas); clientY=rect.top+v.localY(clientX-rect.left,clientY-rect.top);
    const frame={w:v.w,h:v.h,cx:camera.x,cy:camera.y,z:camera.z};
    // Test the frontmost roof/facade at the actual tap, excluding transparent
    // margins and the translucent shadow. Road taps still reach the walker.
    for(let i=volumes.length-1;i>=0;i--){
      const p=volumes[i];if(!p.component)continue;
      const t=tiles.get(p.id),[x,y]=screen([p.x,p.y],frame);
      const u=((clientX-rect.left-x)/frame.z-t.left)/t.width;
      const v=((clientY-rect.top-y)/frame.z+t.top)/t.height;
      if(u<0||v<0||u>=1||v>=1)continue;
      const level=t.levels.at(-1);
      if(!t.hit){
        const mask=document.createElement('canvas');
        mask.width=level.width;mask.height=level.height;
        const ctx=mask.getContext('2d');
        ctx.drawImage(level,0,0);
        t.hit=ctx.getImageData(0,0,mask.width,mask.height).data;
      }
      if(t.hit[(Math.floor(v*level.height)*level.width+Math.floor(u*level.width))*4+3]<190)continue;
      setMapDestination('center',false,p.id);focus(api.places.find(item=>item.id==='center'),p);
      return true;
    }
    const district=districts.hit(clientX-rect.left,clientY-rect.top,frame)||surroundings.hit(clientX-rect.left,clientY-rect.top,frame);
    if(district){openStudy('district',district);return true}
    return false;
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
