import * as THREE from 'three';
import {OrbitControls} from './vendor/OrbitControls.js';
import {RoomEnvironment} from './vendor/RoomEnvironment.js';
import {buildStudy,createMaterials} from './scene-adapter.js';
import {buildFlows} from './datacenter-flows.js';
import {initReports} from './datacenter-reports.js';

const $=id=>document.getElementById(id),viewport=$('viewport'),reduced=matchMedia('(prefers-reduced-motion: reduce)');
let renderer,scene,camera,controls,sun,views,current,model,flows,materials,highlight,selected;
let family='none',activeFlow='',playing=false,raf=0,dirty=0,lastTime=0,flowTime=0,aspect=0;
let rackId='A1',slotId='U3',cameraMode='overview';const labelNodes=new Map();
const names={site:'园区概览',hall:'01 号机房',rack:'机柜',server:'服务器',board:'系统主板'};
function invalidate(){dirty=5;if(!raf&&!document.hidden)raf=requestAnimationFrame(render);}
function render(now){
  raf=0;if(document.hidden){lastTime=0;return;}const dt=lastTime?Math.min((now-lastTime)/1000,.05):0;lastTime=now;
  controls.update();if(playing&&family!=='none'){flowTime+=dt;flows.tick(flowTime);}
  renderer.render(scene,camera);placeLabels();
  viewport.dataset.view=current.study.id;viewport.dataset.camera=camera.position.toArray().map(v=>v.toFixed(4)).join(',');viewport.dataset.drawCalls=renderer.info.render.calls;
  viewport.dataset.family=family;viewport.dataset.playing=String(playing);viewport.dataset.parts=current.study.parts.length;
  if(--dirty>0||(playing&&family!=='none'))raf=requestAnimationFrame(render);
}
function placeLabels(){
  const boxes=[];const entities=[...current.entities].sort((a,b)=>(b.id===selected?.id?1:0)-(a.id===selected?.id?1:0));
  for(const entity of entities){
    const point=new THREE.Vector3().fromArray(entity.position);if(entity.id==='heatsink')point.y+=Number($('explode').value)/100*.12;
    point.project(camera);const x=(point.x*.5+.5)*viewport.clientWidth,y=(-point.y*.5+.5)*viewport.clientHeight,label=labelNodes.get(entity.id);
    const width=label.offsetWidth||100,height=30,b={left:x-width/2,right:x+width/2,top:y-height,bottom:y+6};
    const overlaps=boxes.some(a=>a.left<b.right+7&&a.right>b.left-7&&a.top<b.bottom+5&&a.bottom>b.top-5);
    const bottom=family==='none'?115:235;
    label.hidden=!$('show-labels').checked||point.z>1||point.z< -1||x<width/2+8||x>viewport.clientWidth-width/2-8||y<140||y>viewport.clientHeight-bottom||overlaps;
    if(!label.hidden)boxes.push(b);label.style.left=x+'px';label.style.top=y+'px';
  }
}
function resize(){
  const w=viewport.clientWidth,h=viewport.clientHeight,next=w/h;renderer.setSize(w,h,false);camera.aspect=next;
  if(aspect){const fit=Math.max(1,1.35/next)/Math.max(1,1.35/aspect);camera.position.sub(controls.target).multiplyScalar(fit).add(controls.target);}
  aspect=next;camera.setViewOffset(w,h,0,family==='none'?10:60,w,h);camera.updateProjectionMatrix();invalidate();
}
function resetCamera(mode='overview'){
  const damping=controls.enableDamping;controls.enableDamping=false;controls.update();
  cameraMode=mode;const study=current.study,target=new THREE.Vector3().fromArray(study.focus),offset=new THREE.Vector3().fromArray(study.detail_offset);
  if(mode==='reverse'){offset.x*=-1;offset.z*=-1;}
  if(mode==='top'){offset.set(0,offset.length(),.0001);}
  const framing=study.id==='site'?1.22:study.id==='rack'?1.2:1;
  offset.multiplyScalar(framing*(family==='none'?1:1.16)*Math.max(1,1.35/(viewport.clientWidth/viewport.clientHeight)));
  controls.target.copy(target);camera.position.copy(target).add(offset);camera.near=study.span/5000;camera.far=study.span*60;camera.updateProjectionMatrix();
  controls.minDistance=study.span*.045;controls.maxDistance=study.span*8;controls.update();controls.enableDamping=damping;invalidate();
}
function select(id,focus=false){
  const entity=current.entities.find(e=>e.id===id);if(!entity)return;selected=entity;viewport.dataset.selected=id;
  $('entity-kind').textContent=entity.kind;$('entity-name').textContent=entity.name;$('entity-detail').textContent=entity.detail;
  $('focus').disabled=false;$('enter').disabled=!entity.visit;$('enter').textContent=entity.visit?`进入${names[entity.visit]} →`:'此层已到设备';
  document.querySelectorAll('[data-entity]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.entity===id)));
  labelNodes.forEach((n,key)=>n.classList.toggle('selected',key===id));
  if(highlight){scene.remove(highlight);highlight.geometry.dispose();highlight.material.dispose();highlight=null;}
  const group=model.layers.get(id);if(group){const bounds=new THREE.Box3().setFromObject(group);if(!bounds.isEmpty()){highlight=new THREE.Box3Helper(bounds,0x7b9a63);highlight.material.depthTest=false;highlight.material.transparent=true;highlight.material.opacity=.75;highlight.renderOrder=10;scene.add(highlight);}}
  if(focus){
    const target=new THREE.Vector3().fromArray(entity.position),span=current.study.span;
    let distance=span*(current.study.id==='site'?.28:current.study.id==='hall'?.21:.22);
    if(group){const size=new THREE.Box3().setFromObject(group).getSize(new THREE.Vector3());distance=Math.max(distance,size.length()*.95);}
    const direction=camera.position.clone().sub(controls.target).normalize();controls.target.copy(target);camera.position.copy(target).addScaledVector(direction,distance*Math.max(1,1.2/camera.aspect));controls.update();
  }
  invalidate();
}
function enter(){if(!selected?.visit)return;if(current.study.id==='hall'&&/^[AB][1-6]$/.test(selected.id))rackId=selected.id;if(current.study.id==='rack'&&/^U\d+$/.test(selected.id))slotId=selected.id;showView(selected.visit);}
function layers(){
  const cut=$('cutaway').checked;
  if(model.layers.has('shell'))model.layers.get('shell').visible=!cut;
  if(model.layers.has('walls'))model.layers.get('walls').visible=!cut;
  if(model.layers.has('lid'))model.layers.get('lid').visible=!cut;
  if(model.layers.has('containment'))model.layers.get('containment').visible=$('containment').checked;
  if(model.layers.has('heatsink'))model.layers.get('heatsink').position.y=Number($('explode').value)/100*.12;
  if(selected)select(selected.id);viewport.dataset.cutaway=String(cut);viewport.dataset.explode=$('explode').value;invalidate();
}
function setFamily(next){
  const factor=family==='none'&&next!=='none'?1.16:family!=='none'&&next==='none'?1/1.16:1;
  camera.position.sub(controls.target).multiplyScalar(factor).add(controls.target);
  family=next;const list=current.flows.filter(f=>f.family===family||(family==='cooling'&&f.family==='heat'));
  if(!list.some(f=>f.id===activeFlow))activeFlow=list[0]?.id||'';
  document.querySelectorAll('[data-family]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.family===next)));
  $('flow-story').hidden=next==='none';$('play').disabled=next==='none';$('flow-steps').replaceChildren();
  for(const [index,flow] of list.entries()){
    const button=document.createElement('button');button.textContent=`${index+1} · ${flow.title}`;button.setAttribute('aria-pressed',String(flow.id===activeFlow));button.addEventListener('click',()=>{activeFlow=flow.id;setFamily(family);});$('flow-steps').append(button);
  }
  $('flow-detail').textContent=list.find(f=>f.id===activeFlow)?.detail||'';$('flow-legend').textContent=next==='cooling'?'蓝 = 冷却介质 · 铜红 = 热量 / 热回流':'';
  flows.set(next,activeFlow);resize();invalidate();
}
function showView(id){
  const data=views.find(v=>v.study.id===id)||views[0];if(model){scene.remove(model.root);model.dispose();scene.remove(flows.root);flows.dispose();}
  if(highlight){scene.remove(highlight);highlight.geometry.dispose();highlight.material.dispose();highlight=null;}
  current=data;selected=null;delete viewport.dataset.selected;model=buildStudy(data.study,materials);flows=buildFlows(data.flows,data.study.span);scene.add(model.root,flows.root);
  $('title').textContent=data.study.title;$('chapter').textContent=data.study.subtitle;
  const context=id==='site'?names.site:`${names.hall}${['rack','server','board'].includes(id)?' / '+rackId:''}${['server','board'].includes(id)?' / '+slotId+'–'+(Number(slotId.slice(1))+1):''}${id==='board'?' / PCB':''}`;
  $('location').textContent=context;$('model-note').textContent='CONCEPT / NOT AS-BUILT';
  $('entity-count').textContent=data.entities.length+' 项';$('entities').replaceChildren();$('labels').replaceChildren();labelNodes.clear();
  for(const [index,entity] of data.entities.entries()){
    const b=document.createElement('button'),n=document.createElement('span'),copy=document.createElement('span'),small=document.createElement('small');b.dataset.entity=entity.id;b.setAttribute('aria-pressed','false');
    n.className='entity-index';n.textContent=String(index+1).padStart(2,'0');copy.textContent=entity.name;small.textContent=entity.kind;copy.append(small);b.append(n,copy);
    b.addEventListener('click',()=>select(entity.id));b.addEventListener('dblclick',()=>{select(entity.id);enter();});$('entities').append(b);
    const label=document.createElement('button');label.className='model-label';label.textContent=entity.name;label.addEventListener('click',()=>select(entity.id));label.addEventListener('dblclick',()=>{select(entity.id);enter();});$('labels').append(label);labelNodes.set(entity.id,label);
  }
  $('entity-kind').textContent='EXPLORE';$('entity-name').textContent='选择一个设备';$('entity-detail').textContent='点击模型或左侧列表检查设备；进入下一层可查看内部结构。所有相机都支持拖拽环视。';$('focus').disabled=true;$('enter').disabled=true;$('enter').textContent='进入下一层 →';
  $('cutaway').checked=['hall','server','board'].includes(id);$('cutaway').disabled=['rack','board'].includes(id);$('containment-option').hidden=id!=='hall';$('explode-option').hidden=!['server','board'].includes(id);$('explode').value=0;
  const s=data.study.span;sun.position.set(-s*.45,s*.85,s*.6);sun.target.position.fromArray(data.study.focus);Object.assign(sun.shadow.camera,{left:-s*.65,right:s*.65,top:s*.65,bottom:-s*.65,near:s*.005,far:s*3});sun.shadow.camera.updateProjectionMatrix();sun.shadow.normalBias=s*.0002;sun.shadow.bias=-.00006;
  document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.view===id)));
  layers();resetCamera();setFamily(family);history.replaceState(null,'','#'+data.study.id);$('status').textContent='拖拽环视 · 滚轮缩放 · 点击设备 · 双击进入';
  document.querySelector('.inspector').scrollTop=0;$('entities').scrollTop=0;document.querySelector('main').scrollTop=0;
}
function toggleStats(open){$('stats').hidden=!open;$('open-stats').setAttribute('aria-expanded',String(open));if(open)$('close-stats').focus();else $('open-stats').focus();invalidate();}
async function start(){
  await import('./models.js');views=globalThis.moonDataCenter?.views;if(!views?.length)throw new Error('请先构建 MoonBit 模型');
  renderer=new THREE.WebGLRenderer({canvas:$('scene'),antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.02;renderer.outputColorSpace=THREE.SRGBColorSpace;
  scene=new THREE.Scene();scene.background=new THREE.Color('#e2e8dd');materials=createMaterials();
  materials.screen.emissive.set('#458f9e');materials.screen.emissiveIntensity=.25;
  const pmrem=new THREE.PMREMGenerator(renderer),room=new RoomEnvironment(),env=pmrem.fromScene(room,.04);scene.environment=env.texture;scene.environmentIntensity=.38;pmrem.dispose();room.dispose();
  scene.add(new THREE.HemisphereLight('#e7f2fc','#adac8e',2));sun=new THREE.DirectionalLight('#fff0d5',3);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);scene.add(sun,sun.target);
  const fill=new THREE.DirectionalLight('#d9eaf4',1.1);fill.position.set(1,1,-1);scene.add(fill);
  camera=new THREE.PerspectiveCamera(38,1,.001,2000);controls=new OrbitControls(camera,$('scene'));controls.enableDamping=!reduced.matches;controls.dampingFactor=.15;controls.minPolarAngle=.015;controls.maxPolarAngle=Math.PI-.015;controls.addEventListener('change',invalidate);
  document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>showView(b.dataset.view)));
  document.querySelectorAll('[data-family]').forEach(b=>b.addEventListener('click',()=>setFamily(b.dataset.family)));
  $('play').addEventListener('click',()=>{playing=!playing;$('play').textContent=playing?'暂停流动':'播放流动';$('play').setAttribute('aria-pressed',String(playing));lastTime=0;invalidate();});
  $('reset').addEventListener('click',()=>resetCamera());$('reverse').addEventListener('click',()=>resetCamera('reverse'));$('top').addEventListener('click',()=>resetCamera('top'));
  $('focus').addEventListener('click',()=>selected&&select(selected.id,true));$('enter').addEventListener('click',enter);
  for(const id of ['cutaway','show-labels','containment'])$(id).addEventListener('change',layers);$('explode').addEventListener('input',layers);
  $('open-stats').addEventListener('click',()=>toggleStats($('stats').hidden));$('close-stats').addEventListener('click',()=>toggleStats(false));
  initReports({onRack:id=>{rackId=id;showView('rack');toggleStats(false);},context:()=>({view:current.study.id,design_rack:rackId,design_slot:slotId,entity:selected?.id||null,flow_family:family,flow:activeFlow,camera:cameraMode})});
  let pointerStart,lastPicked=null;
  $('scene').addEventListener('pointerdown',e=>{pointerStart=[e.clientX,e.clientY];});
  $('scene').addEventListener('pointerup',e=>{
    lastPicked=null;
    if(!pointerStart||e.button!==0||Math.hypot(e.clientX-pointerStart[0],e.clientY-pointerStart[1])>5)return;
    const r=$('scene').getBoundingClientRect(),ray=new THREE.Raycaster();ray.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),camera);
    const hits=ray.intersectObject(model.root,true);
    for(const hit of hits){let group=hit.object,visible=true,id='';for(let o=group;o;o=o.parent){if(!o.visible)visible=false;if(current.entities.some(e=>e.id===o.name))id=o.name;}if(id&&visible){lastPicked=id;select(id);break;}}
  });
  $('scene').addEventListener('dblclick',()=>{if(lastPicked===selected?.id)enter();});
  $('scene').addEventListener('keydown',e=>{
    if(e.key==='Home'){e.preventDefault();resetCamera();return;}
    if(e.key==='Enter'){e.preventDefault();enter();return;}
    const directions={ArrowLeft:[-.12,0],ArrowRight:[.12,0],ArrowUp:[0,-.1],ArrowDown:[0,.1]};
    if(directions[e.key]){e.preventDefault();const s=new THREE.Spherical().setFromVector3(camera.position.clone().sub(controls.target));s.theta+=directions[e.key][0];s.phi=THREE.MathUtils.clamp(s.phi+directions[e.key][1],.02,Math.PI-.02);camera.position.copy(controls.target).add(new THREE.Vector3().setFromSpherical(s));}
    if(['+','=','-'].includes(e.key)){e.preventDefault();camera.position.sub(controls.target).multiplyScalar(e.key==='-'?1.15:.87).add(controls.target);}controls.update();invalidate();
  });
  document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('export-dialog').open&&!$('stats').hidden)toggleStats(false);});
  new ResizeObserver(resize).observe(viewport);document.addEventListener('visibilitychange',()=>{lastTime=0;if(!document.hidden)invalidate();});
  reduced.addEventListener('change',()=>{controls.enableDamping=!reduced.matches;if(reduced.matches){playing=false;$('play').textContent='播放流动';$('play').setAttribute('aria-pressed','false');}invalidate();});
  $('scene').addEventListener('webglcontextlost',e=>{e.preventDefault();playing=false;$('loading').hidden=false;$('loading').textContent='图形上下文丢失，请刷新恢复模型。';});
  showView(views.some(v=>v.study.id===location.hash.slice(1))?location.hash.slice(1):'site');resize();$('loading').hidden=true;invalidate();
}
start().catch(error=>{$('loading').hidden=false;$('loading').textContent='无法加载数据中心：'+error.message;console.error(error);});
