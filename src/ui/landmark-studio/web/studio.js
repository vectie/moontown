import * as THREE from 'three';
import { OrbitControls } from './vendor/OrbitControls.js';
import { RoomEnvironment } from './vendor/RoomEnvironment.js';
import { createMaterials, buildStudy } from './scene-adapter.js';
import { references } from './references.js';

const $ = id=>document.getElementById(id);
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
let renderer, scene, camera, controls, current, data, model, sun, fill, hemi;
let materials, clayMaterial, ground, environment, projection='perspective', lightMode='day';
let raf=0, dirty=0, lastFrame=0, frameCount=0, lastAspect=0;

function fail(error){$('loading').hidden=false;$('loading').replaceChildren();const title=document.createElement('span');title.textContent='The 3D viewer could not start. '+(error?.message||error)+' — Reload to retry.';$('loading').append(title);console.error(error);}

function invalidate(){dirty=30;if(!raf)raf=requestAnimationFrame(render);}
function render(time){
  raf=0;
  if(document.hidden)return;
  const delta=Math.min((time-lastFrame)/1000,0.05);lastFrame=time;
  controls.update(delta||0.016);
  renderer.render(scene,camera);frameCount++;
  const direction=camera.position.clone().sub(controls.target);
  $('north-arrow').style.transform=`rotate(${-Math.atan2(direction.x,direction.z)*180/Math.PI}deg)`;
  $('viewport').dataset.frames=String(frameCount);
  $('viewport').dataset.camera=camera.position.toArray().map(v=>v.toFixed(2)).join(',');
  $('viewport').dataset.drawCalls=String(renderer.info.render.calls);
  if(--dirty>0||controls.autoRotate)raf=requestAnimationFrame(render);
}

function resize(){
  const w=$('viewport').clientWidth,h=$('viewport').clientHeight;
  const aspect=w/h;
  renderer.setSize(w,h,false);
  if(camera.isPerspectiveCamera){
    if(lastAspect>0&&Math.abs(lastAspect-aspect)>.001){
      const factor=Math.max(1,1.3/aspect)/Math.max(1,1.3/lastAspect);
      camera.position.sub(controls.target).multiplyScalar(factor).add(controls.target);
    }
    camera.aspect=aspect;
  }
  else{const s=(current?.span||310)*.65*Math.max(1,1.3/aspect);camera.left=-s*aspect;camera.right=s*aspect;camera.top=s;camera.bottom=-s;}
  lastAspect=aspect;
  camera.updateProjectionMatrix();invalidate();
}

function bindControls(target){
  controls=new OrbitControls(camera,$('scene'));
  controls.target.copy(target);controls.enableDamping=!reducedMotion.matches;controls.dampingFactor=.12;
  controls.minDistance=8;controls.maxDistance=1500;controls.minPolarAngle=.015;controls.maxPolarAngle=Math.PI-.015;
  controls.maxZoom=12;controls.minZoom=.2;controls.autoRotateSpeed=.45;
  controls.autoRotate=$('rotate').checked&&!reducedMotion.matches;
  controls.addEventListener('change',invalidate);controls.addEventListener('start',()=>{$('view-status').textContent='Free orbit · full 360° inspection';});
}

function view(name){
  const scale=current.span/310;
  const target=new THREE.Vector3().fromArray(current.focus);
  target.y-=18;
  let offset;
  const aspect=$('viewport').clientWidth/$('viewport').clientHeight;
  const fit=aspect<1.3?1.3/aspect:1;
  switch(name){
    case 'detail':target.fromArray(current.detail_focus);offset=new THREE.Vector3().fromArray(current.detail_offset);break;
    case 'top':offset=new THREE.Vector3(0,420,.01);break;
    case 'front':offset=new THREE.Vector3(0,25,440);break;
    case 'side':offset=new THREE.Vector3(440,25,0);break;
    case 'reverse':offset=new THREE.Vector3(-270,175,-290);break;
    default:offset=current.id.includes('bridge')?new THREE.Vector3(160,150,340):new THREE.Vector3(265,215,295);
  }
  offset.multiplyScalar(scale*Math.max(1,fit));
  controls.target.copy(target);camera.position.copy(target).add(offset);camera.zoom=1;camera.updateProjectionMatrix();controls.update();
  if(camera.isOrthographicCamera&&name==='detail'){camera.zoom=3.2;camera.updateProjectionMatrix();}
  document.querySelectorAll('[data-view]').forEach(b=>b.classList.toggle('selected',b.dataset.view===name));
  $('view-status').textContent=name==='hero'?'Interpretive study · drag to explore every angle':`${name[0].toUpperCase()+name.slice(1)} view · drag to continue orbiting`;
  invalidate();
}

function setLighting(mode){
  lightMode=mode;
  const presets={
    day:{bg:'#dce6e0',sun:'#fff1d7',power:2.2,sky:'#d1e5f2',ambient:.85,pos:[-100,220,100],exposure:.83},
    golden:{bg:'#e6d9c5',sun:'#ffd09b',power:2.7,sky:'#b6cdd8',ambient:.65,pos:[-170,95,90],exposure:.87},
    blue:{bg:'#263e50',sun:'#b5cee7',power:.8,sky:'#7c9abf',ambient:.8,pos:[-90,150,-100],exposure:1.0},
  };
  const l=presets[mode];scene.background=new THREE.Color(l.bg);scene.fog.color.set(l.bg);ground.material.color.set(l.bg);
  sun.color.set(l.sun);sun.intensity=l.power;sun.position.fromArray(l.pos);hemi.color.set(l.sky);hemi.intensity=l.ambient;
  fill.intensity=mode==='blue'?.2:.3;renderer.toneMappingExposure=l.exposure;scene.environmentIntensity=mode==='blue'?.3:.45;
  materials.lamp.emissiveIntensity=mode==='blue'?4:mode==='golden'?1:.1;
  materials.trimLight.emissiveIntensity=mode==='blue'?2:.1;
  for(const k of ['glass','glassLight','glassAmber']){materials[k].emissive.set('#f5b75e');materials[k].emissiveIntensity=mode==='blue'?.10:0;}
  document.querySelectorAll('[data-light]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.light===mode)));
  $('viewport').dataset.lighting=mode;invalidate();
}

function setClay(){
  model.landmark.traverse(o=>{if(o.isMesh)o.material=$('clay').checked?clayMaterial:o.userData.originalMaterial;});invalidate();
}

function select(id){
  const next=data.find(d=>d.id===id)||data[0];
  $('loading').hidden=false;
  if(model){scene.remove(model.root);model.dispose();}
  current=next;model=buildStudy(current,materials);scene.add(model.root);
  if(model.reflector){
    // Exclude the exhibition plinth and studio floor from the reflected view.
    const reflect=model.reflector.onBeforeRender;
    model.reflector.onBeforeRender=function(...args){
      const excluded=[];
      scene.traverse(o=>{if(o.visible&&(o===ground||o.material===materials.earth)){excluded.push(o);o.visible=false;}});
      try{reflect.apply(this,args);}finally{excluded.forEach(o=>o.visible=true);}
    };
  }
  model.context.visible=$('context').checked;setClay();
  for(const key of ['title','subtitle','description','note'])$(key).textContent=current[key];
  $('ordinal').textContent=`0${data.indexOf(current)+1} / 04`;
  $('interior-link').style.display=current.id==='center'?'flex':'none';
  $('reference-count').textContent=`${references[current.id].length} views · source photographs & diagrams`;
  document.querySelectorAll('[data-study]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.study===current.id)));
  $('viewport').dataset.study=current.id;$('viewport').dataset.parts=String(current.parts.length);
  history.replaceState(null,'','#'+current.id);document.title=current.title+' · Wenyu Landmark Atelier';
  view('hero');$('loading').hidden=true;invalidate();
}

function showReferences(){
  $('reference-title').textContent=current.title+' · References';
  $('reference-grid').replaceChildren();
  for(const [title,kind,url,source] of references[current.id]){
    const figure=document.createElement('figure'),link=document.createElement('a'),img=document.createElement('img'),caption=document.createElement('figcaption'),sourceLink=document.createElement('a');
    link.href=url;link.target='_blank';link.rel='noopener noreferrer';img.src=url;img.alt=title;img.loading='lazy';img.referrerPolicy='no-referrer';link.append(img);
    img.addEventListener('error',()=>{img.alt=title+' — preview unavailable; open the original publisher link below.';});
    caption.textContent=title;const tag=document.createElement('span');tag.className='source-kind';tag.textContent=kind;caption.append(tag);
    sourceLink.href=source;sourceLink.target='_blank';sourceLink.rel='noopener noreferrer';sourceLink.textContent='Original publisher ↗';caption.append(sourceLink);figure.append(link,caption);$('reference-grid').append(figure);
  }
  $('reference-dialog').showModal();
}

async function start(){
  await import('./models.js');data=globalThis.wenyuLandmarkStudies;
  if(!Array.isArray(data)||data.length!==4)throw new Error('Model data is missing. Run the MoonBit studio build.');
  renderer=new THREE.WebGLRenderer({canvas:$('scene'),antialias:true,alpha:false,powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.outputColorSpace=THREE.SRGBColorSpace;
  scene=new THREE.Scene();scene.fog=new THREE.Fog('#dce6e0',650,1500);
  camera=new THREE.PerspectiveCamera(38,1,.25,2400);
  materials=createMaterials();clayMaterial=new THREE.MeshStandardMaterial({color:'#d5d7cb',roughness:.9,side:THREE.DoubleSide});
  const pmrem=new THREE.PMREMGenerator(renderer),room=new RoomEnvironment();environment=pmrem.fromScene(room,.04);scene.environment=environment.texture;room.dispose();pmrem.dispose();
  hemi=new THREE.HemisphereLight('#d1e5f2','#87906e',2);scene.add(hemi);
  sun=new THREE.DirectionalLight('#fff1d7',3);sun.castShadow=true;sun.shadow.mapSize.set(4096,4096);
  Object.assign(sun.shadow.camera,{left:-250,right:250,top:220,bottom:-220,near:1,far:650});sun.shadow.bias=-.00015;sun.shadow.normalBias=.35;sun.shadow.radius=3;scene.add(sun);
  fill=new THREE.DirectionalLight('#c4dfec',.7);fill.position.set(80,100,-120);scene.add(fill);
  ground=new THREE.Mesh(new THREE.PlaneGeometry(4000,4000),new THREE.MeshStandardMaterial({color:'#dce6e0',roughness:1}));ground.rotation.x=-Math.PI/2;ground.position.y=-9;ground.receiveShadow=true;scene.add(ground);
  bindControls(new THREE.Vector3());
  document.querySelectorAll('[data-study]').forEach(b=>b.addEventListener('click',()=>select(b.dataset.study)));
  document.querySelectorAll('[data-light]').forEach(b=>b.addEventListener('click',()=>setLighting(b.dataset.light)));
  document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>view(b.dataset.view)));
  $('context').addEventListener('change',()=>{model.context.visible=$('context').checked;ground.visible=$('context').checked;invalidate();});
  $('clay').addEventListener('change',setClay);
  $('rotate').addEventListener('change',()=>{controls.autoRotate=$('rotate').checked;invalidate();});
  $('reset').addEventListener('click',()=>view('hero'));
  $('projection').addEventListener('click',()=>{
    projection=projection==='perspective'?'orthographic':'perspective';
    const pos=camera.position.clone(),target=controls.target.clone();controls.dispose();
    camera=projection==='perspective'?new THREE.PerspectiveCamera(38,1,.25,2400):new THREE.OrthographicCamera(-250,250,200,-200,.25,2400);
    camera.position.copy(pos);bindControls(target);resize();controls.update();
    $('projection').setAttribute('aria-pressed',String(projection==='orthographic'));$('viewport').dataset.projection=projection;invalidate();
  });
  $('references').addEventListener('click',showReferences);$('close-references').addEventListener('click',()=>$('reference-dialog').close());
  $('reference-dialog').addEventListener('click',e=>{if(e.target===$('reference-dialog')){const r=e.target.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)e.target.close();}});
  $('scene').addEventListener('keydown',e=>{
    if(e.key==='Home'){e.preventDefault();view('hero');return;}
    const arrows={ArrowLeft:[-.12,0],ArrowRight:[.12,0],ArrowUp:[0,-.1],ArrowDown:[0,.1]};
    if(arrows[e.key]){e.preventDefault();const s=new THREE.Spherical().setFromVector3(camera.position.clone().sub(controls.target));s.theta+=arrows[e.key][0];s.phi=THREE.MathUtils.clamp(s.phi+arrows[e.key][1],.02,Math.PI-.02);camera.position.copy(controls.target).add(new THREE.Vector3().setFromSpherical(s));controls.update();invalidate();}
    if(['+','=','-','_'].includes(e.key)){e.preventDefault();const factor=e.key==='+'||e.key==='='?.85:1.18;if(camera.isPerspectiveCamera)camera.position.sub(controls.target).multiplyScalar(factor).add(controls.target);else{camera.zoom=THREE.MathUtils.clamp(camera.zoom/factor,.2,12);camera.updateProjectionMatrix();}controls.update();invalidate();}
  });
  reducedMotion.addEventListener('change',()=>{controls.enableDamping=!reducedMotion.matches;if(reducedMotion.matches){controls.autoRotate=false;$('rotate').checked=false;}invalidate();});
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)invalidate();});
  $('scene').addEventListener('webglcontextlost',e=>{e.preventDefault();cancelAnimationFrame(raf);fail(new Error('WebGL context lost'));});
  $('scene').addEventListener('webglcontextrestored',()=>location.reload());
  new ResizeObserver(resize).observe($('viewport'));
  window.addEventListener('hashchange',()=>{if(location.hash.slice(1)!==current.id)select(location.hash.slice(1));});
  setLighting('day');select(location.hash.slice(1)||'center');resize();
  // Read-only diagnostics, also reflected in the DOM for UI verification.
  Object.defineProperty(globalThis,'wenyuStudio',{get:()=>({study:current.id,parts:current.parts.length,drawCalls:renderer.info.render.calls,triangles:renderer.info.render.triangles,camera:camera.position.toArray(),projection,lightMode,frames:frameCount})});
}
start().catch(fail);
