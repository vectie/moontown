import * as THREE from 'three';
import {OrbitControls} from './vendor/OrbitControls.js';
import {RoomEnvironment} from './vendor/RoomEnvironment.js';
import {createMaterials,buildStudy} from './scene-adapter.js';

const $=id=>document.getElementById(id), viewport=$('viewport');
const reduced=matchMedia('(prefers-reduced-motion: reduce)');
let renderer,scene,camera,controls,model,materials,zones,selected=null,highlight;
let sun,hemi,raf=0,dirty=0,warm=false,mode='overview',lastAspect=0;
const labelNodes=new Map();
const center=z=>new THREE.Vector3(((z.bounds[0]+z.bounds[2])/2-840)*.06,0,((z.bounds[1]+z.bounds[3])/2-710)*.06);
const extent=z=>[(z.bounds[2]-z.bounds[0])*.06,(z.bounds[3]-z.bounds[1])*.06];

function invalidate(){dirty=18;if(!raf)raf=requestAnimationFrame(render);}
function render(){
  raf=0;if(document.hidden)return;
  controls.update();renderer.render(scene,camera);
  const w=viewport.clientWidth,h=viewport.clientHeight;
  for(const zone of zones){
    const point=center(zone);point.y=.3;point.project(camera);
    const node=labelNodes.get(zone.id),x=(point.x*.5+.5)*w,y=(-point.y*.5+.5)*h;
    node.hidden=!$('labels').checked||$('ceiling').checked||point.z>1||point.z< -1||x<15||x>w-15||y<125||y>h-75;
    node.style.left=x+'px';node.style.top=y+'px';
  }
  viewport.dataset.camera=camera.position.toArray().map(v=>v.toFixed(2)).join(',');
  viewport.dataset.drawCalls=renderer.info.render.calls;
  viewport.dataset.view=mode;
  if(--dirty>0)raf=requestAnimationFrame(render);
}
function resize(){
  const w=viewport.clientWidth,h=viewport.clientHeight,aspect=w/h;
  renderer.setSize(w,h,false);
  if(camera.isPerspectiveCamera){
    camera.aspect=aspect;
    if(lastAspect){const f=Math.max(1,1.45/aspect)/Math.max(1,1.45/lastAspect);camera.position.sub(controls.target).multiplyScalar(f).add(controls.target);}
  }else{const s=32*Math.max(1,1.5/aspect);camera.left=-s*aspect;camera.right=s*aspect;camera.top=s;camera.bottom=-s;}
  lastAspect=aspect;camera.updateProjectionMatrix();invalidate();
}
function bind(target){
  controls=new OrbitControls(camera,$('scene'));controls.target.copy(target);
  controls.enableDamping=!reduced.matches;controls.dampingFactor=.16;controls.minDistance=2;
  controls.maxDistance=600;controls.minPolarAngle=.02;controls.maxPolarAngle=Math.PI-.02;
  controls.maxZoom=10;controls.minZoom=.4;controls.addEventListener('change',invalidate);
}
function setView(name,zone=null){
  mode=name;controls?.dispose();
  const aspect=viewport.clientWidth/viewport.clientHeight,fit=Math.max(1,1.45/aspect);
  camera=name==='plan'?new THREE.OrthographicCamera(-65,65,35,-35,.1,1000):new THREE.PerspectiveCamera(40,aspect,.08,1000);
  const target=zone?center(zone):new THREE.Vector3(0,0,0);
  let offset;
  if(zone){const [w,d]=extent(zone),span=Math.max(w,d,7);offset=new THREE.Vector3(span*.6,span*.9,span*1.1).multiplyScalar(fit);}
  else if(name==='plan')offset=new THREE.Vector3(0,125,.01);
  else offset=new THREE.Vector3(name==='reverse'?-25:25,76,name==='reverse'?-83:83).multiplyScalar(fit);
  camera.position.copy(target).add(offset);bind(target);lastAspect=0;resize();controls.update();
  document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.view===name)));
  $('status').textContent=zone?`${zone.id} · ${zone.name} · 拖拽继续环视`:'拖拽旋转 · 滚轮缩放 · 点击房间选区';
  invalidate();
}
function selectZone(id,focus=false){
  selected=zones.find(z=>z.id===id);if(!selected)return;
  viewport.dataset.selected=id;
  $('room-id').textContent=id==='atrium'?'VOID / 非办公楼面':`SPACE / ${id}`;
  $('room-title').textContent=selected.name;$('room-area').textContent=selected.area;
  $('evidence').textContent=selected.evidence;$('proposal').textContent=selected.proposal;
  $('focus-room').disabled=false;
  document.querySelectorAll('#zones button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.zone===id)));
  labelNodes.forEach((node,key)=>node.classList.toggle('selected',key===id));
  if(highlight){scene.remove(highlight);highlight.geometry.dispose();highlight.material.dispose();}
  const [w,d]=extent(selected),c=center(selected);
  const points=[[-w/2,-d/2],[w/2,-d/2],[w/2,d/2],[-w/2,d/2],[-w/2,-d/2]].map(([x,z])=>new THREE.Vector3(x+c.x,.08,z+c.z));
  highlight=new THREE.Line(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineBasicMaterial({color:'#416f51',depthTest:false}));highlight.renderOrder=8;scene.add(highlight);
  if(focus){$('ceiling').checked=false;setLayers();setView('room',selected);}
  invalidate();
}
function setLayers(){
  if($('ceiling').checked)$('cutaway').checked=false;
  model.layers.get('walls').scale.y=$('cutaway').checked?.36:1;
  model.layers.get('furniture').visible=$('furniture').checked;
  model.layers.get('ceiling').visible=$('ceiling').checked;
  viewport.dataset.cutaway=String($('cutaway').checked);invalidate();
}
function setLighting(){
  scene.background.set(warm?'#ded5c3':'#e1e7dc');
  sun.color.set(warm?'#ffd2a0':'#ffefd4');sun.intensity=warm?2.4:2.7;
  sun.position.set(warm?-25:-42,warm?32:68,30);hemi.intensity=warm?1.15:1.3;
  materials.lamp.emissiveIntensity=warm?2:.35;
  $('light').setAttribute('aria-pressed',String(warm));viewport.dataset.light=warm?'warm':'day';invalidate();
}
async function start(){
  await import('./models.js');const data=globalThis.wenyuInteriorStudy;
  if(!data?.study||!data?.zones)throw new Error('Interior data missing — rebuild the MoonBit module.');
  zones=data.zones;
  renderer=new THREE.WebGLRenderer({canvas:$('scene'),antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));
  renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;renderer.outputColorSpace=THREE.SRGBColorSpace;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=.88;
  scene=new THREE.Scene();scene.background=new THREE.Color('#e1e7dc');materials=createMaterials();
  const pmrem=new THREE.PMREMGenerator(renderer),room=new RoomEnvironment(),env=pmrem.fromScene(room,.04);
  scene.environment=env.texture;scene.environmentIntensity=.28;pmrem.dispose();room.dispose();
  hemi=new THREE.HemisphereLight('#e3eff5','#b2a791',1.3);scene.add(hemi);
  sun=new THREE.DirectionalLight('#ffefd4',2.7);sun.castShadow=true;sun.shadow.mapSize.set(4096,4096);
  Object.assign(sun.shadow.camera,{left:-66,right:66,top:60,bottom:-60,near:1,far:170});sun.shadow.normalBias=.025;sun.shadow.bias=-.00006;sun.shadow.radius=3;scene.add(sun);
  const fill=new THREE.DirectionalLight('#d9e8f1',.5);fill.position.set(50,35,-20);scene.add(fill);
  const floor=new THREE.Mesh(new THREE.PlaneGeometry(1000,1000),new THREE.MeshStandardMaterial({color:'#d4dbcd',roughness:1}));floor.rotation.x=-Math.PI/2;floor.position.y=-4.3;floor.receiveShadow=true;scene.add(floor);
  model=buildStudy(data.study,materials);scene.add(model.root);
  viewport.dataset.parts=data.study.parts.length;
  for(const zone of zones){
    const button=document.createElement('button');button.dataset.zone=zone.id;button.setAttribute('aria-pressed','false');
    const id=document.createElement('strong'),name=document.createElement('span');id.textContent=zone.id.startsWith('core')?(zone.id==='core-west'?'西':'东'):zone.id==='atrium'?'空':zone.id==='social'?'共享':zone.id;
    name.textContent=zone.name;button.append(id,name);button.addEventListener('click',()=>selectZone(zone.id));button.addEventListener('dblclick',()=>selectZone(zone.id,true));$('zones').append(button);
    const label=document.createElement('button');label.className='room-label';label.textContent=zone.id==='atrium'?'中央挑空':zone.id==='social'?'水吧':zone.id.startsWith('core')?(zone.id==='core-west'?'西侧核心':'东侧核心'):zone.id;
    label.title=zone.name;label.setAttribute('aria-label',zone.id+' '+zone.name);label.addEventListener('click',()=>selectZone(zone.id));label.addEventListener('dblclick',()=>selectZone(zone.id,true));$('room-labels').append(label);labelNodes.set(zone.id,label);
  }
  setView('overview');setLayers();setLighting();
  document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>setView(b.dataset.view)));
  $('reset').addEventListener('click',()=>setView('overview'));
  $('focus-room').addEventListener('click',()=>selected&&selectZone(selected.id,true));
  for(const id of ['cutaway','furniture','labels','ceiling'])$(id).addEventListener('change',()=>{if(id==='cutaway'&&$('cutaway').checked)$('ceiling').checked=false;setLayers();});
  $('light').addEventListener('click',()=>{warm=!warm;setLighting();});
  let startPoint;
  $('scene').addEventListener('pointerdown',e=>{startPoint=[e.clientX,e.clientY];});
  $('scene').addEventListener('pointerup',e=>{
    if(!startPoint||Math.hypot(e.clientX-startPoint[0],e.clientY-startPoint[1])>5||e.button!==0)return;
    const r=$('scene').getBoundingClientRect(),ray=new THREE.Raycaster();ray.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),camera);
    const hits=ray.intersectObjects(model.layers.get('zones').children,true);
    const hit=hits.find(h=>h.object.userData.entities?.[h.instanceId]);
    if(hit)selectZone(hit.object.userData.entities[hit.instanceId]);
  });
  $('scene').addEventListener('keydown',e=>{
    if(e.key==='Home'){e.preventDefault();setView('overview');return;}
    const directions={ArrowLeft:[-.12,0],ArrowRight:[.12,0],ArrowUp:[0,-.1],ArrowDown:[0,.1]};
    if(directions[e.key]){e.preventDefault();const s=new THREE.Spherical().setFromVector3(camera.position.clone().sub(controls.target));s.theta+=directions[e.key][0];s.phi=THREE.MathUtils.clamp(s.phi+directions[e.key][1],.02,Math.PI-.02);camera.position.copy(controls.target).add(new THREE.Vector3().setFromSpherical(s));}
    if(['+','=','-'].includes(e.key)){e.preventDefault();const f=e.key==='-'?1.15:.87;if(camera.isOrthographicCamera){camera.zoom=THREE.MathUtils.clamp(camera.zoom/f,.4,10);camera.updateProjectionMatrix();}else camera.position.sub(controls.target).multiplyScalar(f).add(controls.target);}
    controls.update();invalidate();
  });
  new ResizeObserver(resize).observe(viewport);document.addEventListener('visibilitychange',()=>{if(!document.hidden)invalidate();});
  reduced.addEventListener('change',()=>{controls.enableDamping=!reduced.matches;invalidate();});
  $('scene').addEventListener('webglcontextlost',e=>{e.preventDefault();$('loading').hidden=false;$('loading').textContent='图形上下文丢失，请刷新页面。';});
  $('loading').hidden=true;invalidate();
}
start().catch(error=>{$('loading').hidden=false;$('loading').textContent='无法加载室内模型：'+error.message;console.error(error);});
