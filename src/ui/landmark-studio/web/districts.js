import {compactGraphics, resizeScene, shadowSize} from './scene-resolution.js';
// Rendering boundary: the compiler supplies local axes, checked ground rings and heights.
import {streetLife,runStreet} from './scene-life.js';
import {decodeStudyRing, facadePlan, elevation, buildingBands, solarRows} from './district-facades.js';
import {frontage} from './street-motion.js';
import {viewerIcon} from './viewer-ui.js';
import * as T from 'three';
import {OrbitControls} from './vendor/OrbitControls.js';
const $=id=>document.getElementById(id), options=$('place'), canvas=$('scene');
let streets=[],life,clock,sky,sun,night=false,paused=false;
let db,site,renderer,scene,cam,ctrl,world,extent=150,frame=false;
const sourceNames={xingkeHandover:'二期 1 号厂房 · 交付实景',xingkeOpening:'园区投运 · 楼栋规模',xingkePhase1:'一期 · 用地四至',xingkePhase2:'二期 · 用地四至',visionPlan:'A21 · 验收总平',siteImagery:'Esri · 参考影像',z29Layout:'0029 · 总平图',z55Layout:'0055 · 总平图',southLayout:'0002、0003 · 联合总平图',stars:'集团 · 星寰项目进展',hyPlan:'寰宇未来 · 总平图',gy77:'0077 宗 · 总平图',gy78:'0078 宗 · 总平图',xyPlan:'星耀未来 · 总平图',hyDecision:'北京市 · 交通影响意见',gyDecision:'北京市 · 规划许可',xyDecision:'北京市 · 规划文件',southPlan:'北京市 · 供地审核附图（第 10 页）',southDecision:'北京市 · 工程公告',west2:'北京市 · 项目与配套',west55:'北京市 · 方案设计',property:'集团 · 产城空间',municipal:'北京市 · 未来科学城',housing:'集团合作住宅',group:'集团产业项目',starplan:'星科 · 公开总平图',robotref:'机器人园 · 公开鸟瞰图',biosites:'北京市 · 入驻楼号',relocation:'安置房项目资料',beisi:'北四村规划许可',innovation:'安置房核准批复',newbuild:'规划设计公告',cloud:'云谷楼宇资料',delivery:'慧园交付资料'};
const material=new Map(),mat=c=>{if(!material.has(c))material.set(c,new T.MeshStandardMaterial({color:c,roughness:.83,metalness:.04}));return material.get(c)};
Object.assign(sourceNames,{
 yiDrawings:'开发商 · 楼号位置与层数',yiArchitect:'设计方 · 逸园立面实景',
 xingkeHandover:'二期 1 号厂房 · 竣工实景',huiSale:'慧园 · 住宅层数',
 yanSale:'砚园 · 配售公告',blueArchitect:'设计方 · 1 号楼四向立面',crArchitect:'设计方 · 楼群与幕墙'
});
function schedule(){if(!frame&&world&&!canvas.hidden){frame=true;requestAnimationFrame(()=>{frame=false;if(!canvas.hidden)renderer.render(scene,cam)})}}
function boot(){
 if(renderer)return;renderer=new T.WebGLRenderer({canvas,antialias:!compactGraphics,alpha:false});renderer.toneMapping=T.ACESFilmicToneMapping;renderer.toneMappingExposure=.98;renderer.shadowMap.enabled=true;renderer.shadowMap.type=T.PCFSoftShadowMap;renderer.shadowMap.autoUpdate=false;
 scene=new T.Scene();scene.background=new T.Color(0xe6ece8);cam=new T.PerspectiveCamera(35,1,.4,6000);ctrl=new OrbitControls(cam,canvas);ctrl.maxPolarAngle=Math.PI*.485;ctrl.addEventListener('change',()=>{$('viewport').dataset.camera=cam.position.toArray().map(v=>v.toFixed(2)).join(',');schedule()});sky=new T.HemisphereLight(0xf6fbff,0x9aa89b,1.55);scene.add(sky);
 sun=new T.DirectionalLight(0xfff3db,2.0);sun.position.set(-350,650,220);sun.castShadow=true;sun.shadow.mapSize.set(shadowSize(2048),shadowSize(2048));Object.assign(sun.shadow.camera,{left:-650,right:650,top:650,bottom:-650,near:1,far:2000});sun.shadow.camera.updateProjectionMatrix();sun.shadow.normalBias=.15;sun.shadow.bias=-.00022;scene.add(sun);
 new ResizeObserver(resize).observe($('viewport'));resize()
}
function resize(){if(!renderer)return;const r=$('viewport').getBoundingClientRect();resizeScene(renderer,r.width,r.height,2);cam.aspect=r.width/Math.max(1,r.height);cam.updateProjectionMatrix();schedule()}
function reset(top=false){if(!ctrl||!world)return;ctrl.target.set(0,0,0);const r=extent*Math.max(1,1/Math.max(.25,cam.aspect));cam.position.set(...(top?[0,r*2.1,.01]:[r*.94,r*1.02,r*1.2]));cam.far=Math.max(1800,r*8);cam.updateProjectionMatrix();ctrl.maxDistance=r*6;ctrl.minDistance=Math.max(5,r*.05);ctrl.update();$('plan').setAttribute('aria-pressed',top);$('orbit').setAttribute('aria-pressed',!top);schedule()}
function mesh(ring,h,bottom,color,roof,court=[]){
 // Authoring x is east, y is south; no rotation of a building relative to its parcel.
 const sh=new T.Shape();ring.forEach(([x,z],i)=>i?sh.lineTo(x,-z):sh.moveTo(x,-z));sh.closePath();
 if(court.length){const hole=new T.Path();court.forEach(([x,z],i)=>i?hole.lineTo(x,-z):hole.moveTo(x,-z));hole.closePath();sh.holes.push(hole)}
 const g=h?new T.ExtrudeGeometry(sh,{depth:h,bevelEnabled:false}):new T.ShapeGeometry(sh);g.rotateX(-Math.PI/2);const m=new T.Mesh(g,roof?[mat(roof),mat(color)]:mat(color));m.position.y=bottom;m.castShadow=!!h;m.receiveShadow=true;world.add(m)
}
const shrink=(ring,k)=>{const c=ring.reduce((a,p)=>[a[0]+p[0]/ring.length,a[1]+p[1]/ring.length],[0,0]);return ring.map(p=>[c[0]+(p[0]-c[0])*k,c[1]+(p[1]-c[1])*k])};
const skinMaterials = {
  relief: new T.MeshStandardMaterial({color:0xffffff,roughness:.81}),
  glass: new T.MeshStandardMaterial({color:0xffffff,roughness:.31,metalness:.16,side:T.DoubleSide}),
  lit: new T.MeshStandardMaterial({color:0xffffff,roughness:.34,metalness:.12,side:T.DoubleSide,emissive:0xffbd76,emissiveIntensity:0})
};
function facadeBatch() {
  const batches={relief:[],glass:[],lit:[]}, helper=new T.Object3D();
  function face(plan, edge) {
    const yaw=-Math.atan2(edge.tz,edge.tx);
    elevation(plan,edge,(u,y,w,h,role,depth)=>{
      const group=role==='lamp'?'lit':(role==='glass'||role==='sky'||role==='reveal')?'glass':'relief';
      const distance=group==='relief'?depth/2:depth;
      helper.position.set(edge.x+edge.tx*(u+w/2)+edge.nx*distance,y+h/2,edge.z+edge.tz*(u+w/2)+edge.nz*distance);
      helper.rotation.set(0,yaw,0);
      helper.scale.set(w,h,group==='relief'?depth:1);
      helper.updateMatrix();
      batches[group].push([helper.matrix.clone(),plan.colors[role]]);
    });
  }
  function finish() {
    const color=new T.Color();
    for(const [key,instances] of Object.entries(batches)){
      if(!instances.length)continue;
      const geometry=key==='relief'?new T.BoxGeometry(1,1,1):new T.PlaneGeometry(1,1);
      const mesh=new T.InstancedMesh(geometry,skinMaterials[key],instances.length);
      instances.forEach(([matrix,tint],i)=>{mesh.setMatrixAt(i,matrix);mesh.setColorAt(i,color.set(tint))});
      mesh.castShadow=key==='relief';mesh.receiveShadow=true;
      world.add(mesh);
    }
  }
  return {face,finish};
}
function model(blocks){
 boot();clock?.dispose();clock=null;if(world){scene.remove(world);world.traverse(o=>{o.geometry?.dispose();if(o.isInstancedMesh)o.dispose()})}world=new T.Group();scene.add(world);
 const first=blocks[0].base,to=(b,p)=>[p[0]*b[2]+(b[0]-first[0])*85130,p[1]*b[3]+(first[1]-b[1])*111045], all=blocks.flatMap(b=>b.ring.map(p=>to(b.base,p)));
 const xs=all.map(p=>p[0]),zs=all.map(p=>p[1]),cx=(Math.min(...xs)+Math.max(...xs))/2,cz=(Math.min(...zs)+Math.max(...zs))/2;
 const pos=(b,p)=>{const v=to(b,p);return [v[0]-cx,v[1]-cz]};extent=Math.max(80,Math.max(...xs)-Math.min(...xs),Math.max(...zs)-Math.min(...zs));
 const floor=new T.Mesh(new T.CircleGeometry(extent*2,80),mat(0xcdd9cd));floor.rotation.x=-Math.PI/2;floor.position.y=-.6;floor.receiveShadow=true;world.add(floor);
 // Small roughness and colour differences read as a family of buildings, not anonymous boxes.
 const fixtures=new Map(),helper=new T.Object3D();
 function box(x,y,z,w,h,d,angle,color){if(!fixtures.has(color))fixtures.set(color,[]);helper.position.set(x,y,z);helper.scale.set(w,h,d);helper.rotation.set(0,-angle,0);helper.updateMatrix();fixtures.get(color).push(helper.matrix.clone())}
 const facades=facadeBatch();
 const inside=(p,r)=>{let yes=false;for(let i=0,j=r.length-1;i<r.length;j=i++){const a=r[i],b=r[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])yes=!yes}return yes};
 for(const b of blocks){const ring=b.ring.map(p=>pos(b.base,p)),roofs=[];mesh(ring,.42,-.1,b.units.length?0xbacaa9:0xc4cba9);
 for(const [form,height,points,id] of b.units){
   const whole=points.map(p=>pos(b.base,p));
   for(const band of buildingBands(id,whole,height)){
   const r=band.shape(whole),h=band.height,plan=facadePlan(site.id,form,h,r,id);
   roofs.push(r);
   const court=b.courts?.[id]?decodeStudyRing(b.courts[id]).map(p=>pos(b.base,p)):[];
   mesh(r,h,0,plan.colors.wall,plan.colors.roof,court);
   for(const edge of plan.edges)facades.face(plan,edge);
   if(plan.family==='xingke'){
     for(const [a,b,c,d] of solarRows(plan,r)){
       box((a[0]+c[0])/2,h+.16,(a[1]+c[1])/2,Math.hypot(b[0]-a[0],b[1]-a[1]),.28,
         Math.hypot(d[0]-a[0],d[1]-a[1]),Math.atan2(b[1]-a[1],b[0]-a[0]),0x475e66);
     }
     continue;
   }
   // Keep roof equipment entirely inside the outline, including stepped plans.
   const center=r.reduce((a,p)=>[a[0]+p[0]/r.length,a[1]+p[1]/r.length],[0,0]);
   if(court.length||!inside(center,r))continue;
   const clearanceAt=(x,z)=>Math.min(...plan.edges.map(e=>{
     const u=Math.max(0,Math.min(e.len,(x-e.x)*e.tx+(z-e.z)*e.tz));
     return Math.hypot(x-e.x-u*e.tx,z-e.z-u*e.tz);
   }));
   const clearance=clearanceAt(...center);
   if(clearance<2.7)continue;
   const axis=plan.edges.reduce((a,b)=>a.len>b.len?a:b), yaw=Math.atan2(axis.tz,axis.tx);
   if(plan.family==='robotics'){
     // Retain the original roof array; fit each full panel inside the outline.
     const spacing=Math.min(4,axis.len/13);
     for(let i=-2;i<=2;i++){
       const x=center[0]+i*spacing*axis.tx,z=center[1]+i*spacing*axis.tz;
       if(clearanceAt(x,z)>2.12&&inside([x,z],r))box(x,h+.17,z,2.1,.32,3.65,yaw,0x435f6d);
     }
     continue;
   }
   const w=Math.min(clearance*1.40,form==='homes'?7:11),d=Math.min(clearance*.85,5);
   const tall=form==='homes'?1.65:1.18;
   box(center[0],h+tall/2,center[1],w,tall,d,yaw,plan.colors.base);
   box(center[0],h+.09+tall,center[1],w+.18,.18,d+.18,yaw,plan.colors.trim);
 }
 }
 // Landscape hints sit inside the enclosure and outside building footprints.
 if(b.units.length){const p=shrink(ring,.89);for(let j=0;j<p.length;j++){const a=p[j],b=p[(j+1)%p.length],n=Math.floor(Math.hypot(b[0]-a[0],b[1]-a[1])/18);for(let k=0;k<n;k++){
 const t=(k+.5)/n,x=a[0]+(b[0]-a[0])*t,z=a[1]+(b[1]-a[1])*t;if(!inside([x,z],ring)||roofs.some(r=>inside([x,z],shrink(r,1.22))))continue;
 box(x,1.05,z,.43,1.8,.43,0,0x84745a);const g=new T.IcosahedronGeometry(2.0+(k%3)*.16,0),tree=new T.Mesh(g,mat([0x71906a,0x829e71,0x688768][k%3]));tree.position.set(x,3.05,z);tree.scale.set(1,1.18,1);tree.castShadow=true;world.add(tree)
 }}}
 }
 for(const [color,instances] of fixtures){const m=new T.InstancedMesh(new T.BoxGeometry(1,1,1),mat(color),instances.length);instances.forEach((x,i)=>m.setMatrixAt(i,x));m.receiveShadow=true;world.add(m)}
 facades.finish();
 const mapped=streets.filter(v=>v.k===site.id).map(v=>({...v,p:v.p.map(([x,z])=>[x-cx,z-cz])}));
 const roads=mapped.length?mapped:frontage(blocks.map(b=>b.ring.map(p=>pos(b.base,p))));
 const crossing=roads.find(r=>r.p.length>=2 && (r.closed||Math.hypot(r.p.at(-1)[0]-r.p[0][0],r.p.at(-1)[1]-r.p[0][1])>60));
 if(crossing)crossing.signal=true;
 life=streetLife(roads,{surface:true});world.add(life.root);clock=runStreet(life,canvas,schedule);clock.pause(paused);
 $('viewport').dataset.traffic=String(life.count);$('viewport').dataset.streets=mapped.length?'osm':'study';
 lighting();resize();reset();
 const requested=new URLSearchParams(location.search).get('unit');
 if(requested){for(const b of blocks){const u=b.units.find(row=>row[3]===requested);if(!u)continue;
   const ps=u[2].map(p=>pos(b.base,p)),xs=ps.map(p=>p[0]),zs=ps.map(p=>p[1]),x=(Math.min(...xs)+Math.max(...xs))/2,z=(Math.min(...zs)+Math.max(...zs))/2;
   const d=Math.max(45,u[1],Math.max(...xs)-Math.min(...xs),Math.max(...zs)-Math.min(...zs))*1.75;
   ctrl.target.set(x,u[1]*.33,z);cam.position.set(x+d,u[1]*.55+d,z+d);ctrl.update();schedule();break}}

}
function lighting(){
 if(!world)return;scene.background.setHex(night?0x405767:0xe6ece8);sky.color.setHex(night?0xb2cedf:0xf6fbff);sky.intensity=night?.68:1.55;
 sun.color.setHex(night?0xb6c8de:0xfff3db);sun.intensity=night?.69:2;
 skinMaterials.lit.emissiveIntensity=night?.86:0;
 life?.night(night);renderer.shadowMap.needsUpdate=true;schedule();
}
function action(id,icon,label,pressed){const b=$(id);b.replaceChildren(viewerIcon(icon));b.title=label;b.setAttribute('aria-label',label);b.setAttribute('aria-pressed',String(pressed))}
function jump(id){
 if(parent===window){location.hash=encodeURIComponent(id);return}
 history.replaceState(history.state,'','#'+encodeURIComponent(id));show()
}
function show(){
 clock?.dispose();clock=null;life=null;const id=decodeURIComponent(location.hash.slice(1));site=db.catalog.projects.find(p=>p.id===id)||db.catalog.projects[0];options.value=site.id;const blocks=db.blocks.filter(b=>b.key===site.id&&b.units.length);
 $('title').textContent=site.name;document.title=site.name+' · MoonTown';$('note').textContent=site.note;$('gap').textContent=site.gap||'';$('gap').hidden=!site.gap;
 const sources=$('sources');sources.replaceChildren();for(const [i,key] of site.refs.entries()){const a=document.createElement('a');a.href=db.catalog.sources[key];a.target='_blank';a.rel='noopener noreferrer';a.textContent=sourceNames[key]||(key.startsWith('p')&&/^p\d+$/.test(key)?'科创平台 · 项目资料':i===0?'集团官网 · 项目资料':'项目依据 '+(i+1));sources.append(a)}
 const credit=$('credit');credit.replaceChildren();if(blocks.length){credit.append('楼高、立面、灯光与车流为示意；方案项目的临街道路按地块外缘示意。');if(blocks[0].base[0]){for(const [t,url] of [['© OpenStreetMap contributors','https://www.openstreetmap.org/copyright'],['Esri · World Imagery','https://www.arcgis.com/home/item.html?id=10df2279f9684e4a9f6a7f08febac2a9'],...(site.id==='tugou'?[['Overture · Qian Shi 等（CC BY 4.0）','https://docs.overturemaps.org/attribution/']]:[])]){const a=document.createElement('a');a.textContent=t;a.href=url;a.target='_blank';a.rel='noopener noreferrer';credit.append(' · ',a)}}}
 const host=$('host');host.hidden=!(site.reuse||site.host);host.href=site.reuse||'#'+(site.host||'');host.textContent=site.reuse?'打开完整 3D':site.id==='bio'?'查看未来公元':'查看所在园区';
 document.querySelectorAll('[data-extra-host]').forEach(el=>el.remove());for(const id of (site.hosts||[]).filter(k=>k!==site.host)){const link=document.createElement('a');link.className='viewer-link';link.dataset.extraHost=id;link.href='#'+id;link.textContent='查看'+db.catalog.projects.find(p=>p.id===id).name;host.after(link)}
 const town=parent!==window?parent.__townLandmarkPainter:null;const locate=$('locate');
 let tour=$('xingke-tour');
 if(!tour){
   tour=document.createElement('a');tour.id='xingke-tour';tour.className='viewer-link';
   tour.textContent='能源谷漫游';tour.href='wlxk.html';locate.before(tour);
   if(town?.openXingkeTour)tour.onclick=e=>{e.preventDefault();town.openXingkeTour()};
 }
 tour.hidden=site.id!=='xingke';
 locate.hidden=!town&&!location.pathname.includes('/landmark-studio/');locate.href='../?view=overview&district='+encodeURIComponent(site.id);
 locate.onclick=town?e=>{e.preventDefault();town.visitDistrict(site.id)}:null;
 let walk=$('street-walk');if(!walk){walk=document.createElement('button');walk.id='street-walk';walk.textContent='从未来中心走到街边';locate.after(walk)}walk.hidden=!town?.canWalkDistrict(site.id);walk.onclick=()=>town?.walkDistrict(site.id);
 $('state').textContent=site.reuse?'已有建筑模型':site.host?'入驻空间':blocks.length?(blocks[0].base[0]?'影像研究':'方案研究')+' · '+blocks.reduce((n,b)=>n+b.units.length,0)+' 座':'待核验';
 $('tools').hidden=canvas.hidden=!blocks.length;$('empty').hidden=!!blocks.length;$('empty').textContent=site.reuse?'使用已有建筑模型':site.host?'沿用所在建筑':site.gap||'尚无可核验楼位';
 if(blocks.length)try{model(blocks)}catch(error){$('empty').hidden=false;$('empty').textContent='此设备无法显示 3D，可在资料中查看项目。';console.error(error)}
}
function sceneActions(){action('dusk','moon','夜景',night);action('motion',paused?'play':'pause',paused?'继续车流':'暂停车流',paused)}
$('dusk').onclick=()=>{night=!night;lighting();sceneActions()};$('motion').onclick=()=>{paused=!paused;clock?.pause(paused);sceneActions()};sceneActions();
options.onchange=()=>jump(options.value);$('orbit').onclick=()=>reset();$('plan').onclick=()=>reset(true);
canvas.onkeydown=e=>{if(!ctrl)return;if(e.key==='Home'){e.preventDefault();reset();return}if(e.key.startsWith('Arrow')){e.preventDefault();const off=cam.position.clone().sub(ctrl.target),s=new T.Spherical().setFromVector3(off);s.theta+=(e.key==='ArrowLeft'?-.12:e.key==='ArrowRight'?.12:0);s.phi=Math.max(.003,Math.min(Math.PI*.48,s.phi+(e.key==='ArrowUp'?-.1:e.key==='ArrowDown'?.1:0)));cam.position.copy(ctrl.target).add(off.setFromSpherical(s));ctrl.update()}};
try{[db,streets]=await Promise.all(['district-studies.json','district-streets.json'].map(async f=>{const r=await fetch(new URL(f,import.meta.url));if(!r.ok)throw Error(f);return r.json()}));
 if(db.encoding!=='xy-i16le-decimetre-v1')throw Error('Unsupported district geometry');
 for(const b of db.blocks){b.ring=decodeStudyRing(b.ring);for(const u of b.units)u[2]=decodeStudyRing(u[2])}
 for(const type of ['住宅','产业园','产业空间']){const g=document.createElement('optgroup');g.label=type;db.catalog.projects.filter(p=>p.type===type).forEach(p=>g.append(new Option(p.name,p.id)));options.append(g)}show();addEventListener('hashchange',show)
}catch(e){$('state').textContent='项目资料载入失败，请刷新重试。';console.error(e)}
