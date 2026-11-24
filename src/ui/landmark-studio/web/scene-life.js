import * as T from 'three';
import {lane,sample,traffic} from './street-motion.js';

// Studio overlays own their geometry and never mutate the authored model or its bake.
export function mobileStudy(study){
 const parts=study.parts,keep=[];
 for(let i=0;i<parts.length;i++){const p=parts[i],group=parts.slice(i,i+7);
  if(p.kind==='box'&&p.layer==='context'&&p.scale.join(',')==='4.4,0.85,1.9'&&group.length===7&&group[1].material==='glass'&&group[2].material===p.material&&group.slice(3).every(x=>x.material==='rubber'&&x.layer==='context')){i+=6;continue}keep.push(p)}
 return {...study,parts:keep};
}
export function modelRoads(study){
 return study.parts.filter(p=>p.material==='asphalt'&&(p.kind==='box'||p.kind==='profile')).map((v,i)=>{
  const [x,y,z]=v.position,[w,h,d]=v.scale;
  const signal=i===0&&!study.id.includes('bridge');
  if(v.kind==='box'){
   const horiz=w>d;
   return {p:horiz?[[x-w/2,z],[x+w/2,z]]:[[x,z-d/2],[x,z+d/2]],y:y+h/2,w:Math.min(w,d),signal,poles:false};
  }
  // Road ribbons run out along one curb and return along the opposite curb.
  const points=v.points,n=points.length,centres=[];
  for(let j=0;j<n/2;j++){const a=points[j],b=points[n-1-j];centres.push([x+(a[0]+b[0])/2,z+(a[1]+b[1])/2])}
  const width=Math.hypot(points[0][0]-points[n-1][0],points[0][1]-points[n-1][1]);
  return {p:centres,y:y+h,w:width,signal,poles:false};
 })
}
const box=new T.BoxGeometry(1,1,1);
export function streetLife(roads,{surface=false}={}){
 const root=new T.Group();root.name='street-life';const sim=traffic(roads),obj=new T.Object3D(),items=new Map(),owned=[],materials=[];
 const standard=c=>{const m=new T.MeshStandardMaterial({color:c,roughness:.82});materials.push(m);return m};
 const basic=c=>{const m=new T.MeshBasicMaterial({color:c});materials.push(m);return m};
 const matrix=(x,y,z,w,h,d,angle=0)=>{obj.position.set(x,y,z);obj.rotation.set(0,-angle,0);obj.scale.set(w,h,d);obj.updateMatrix();return obj.matrix};
 const add=(key,color,...args)=>{if(!items.has(key))items.set(key,{color,a:[]});items.get(key).a.push(matrix(...args).clone())};
 const batch=(g,m,n)=>{const o=new T.InstancedMesh(g,m,n);o.frustumCulled=false;root.add(o);return o};
 const lamps=[],signals=[];const positions={road:[],walk:[]};
 // Continuous ribbons share the exact cross-section at bends.
 function ribbon(l,left,right,y,to){const verts=l.p.map((p,i)=>{
   const a=l.p[Math.max(0,i-1)],b=l.p[Math.min(l.p.length-1,i+1)],len=Math.hypot(b[0]-a[0],b[1]-a[1])||1,nx=-(b[1]-a[1])/len,nz=(b[0]-a[0])/len;
   return [[p[0]+nx*left,y,p[1]+nz*left],[p[0]+nx*right,y,p[1]+nz*right]]});
   for(let i=1;i<verts.length;i++){const [a,b]=verts[i-1],[c,d]=verts[i];to.push(...a,...b,...c,...c,...b,...d)}
 }
 for(const road of roads){const l=lane(road.p);if(l.p.length<2)continue;const w=road.w,y=road.y??-.4;
  if(surface){ribbon(l,-w/2,w/2,y,positions.road);for(const side of [-1,1])ribbon(l,side*(w/2),side*(w/2+1.3),y+.08,positions.walk);
   if(!road.dir&&w>=5.5)for(let t=5;t<l.length-3;t+=11){const p=sample(l,t);add('stripe',0xe1d5aa,p.x,y+.025,p.z,3,.035,.16,Math.atan2(p.dz,p.dx))}}
  if(road.poles!==false)for(let d=15;d<l.length-5;d+=36){const p=sample(l,d,w/2+.72),q=sample(l,d,w/2-.12),a=Math.atan2(p.dz,p.dx);add('pole',0x475b57,p.x,y+2.7,p.z,.18,5.4,.18);add('pole',0x475b57,q.x,y+5.45,q.z,.18,.15,1.9,a);lamps.push([q.x,y+5.34,q.z,a]);}
  if(road.signal&&l.length>24){const d=l.length*.54;const at=sample(l,d);const yaw=Math.atan2(at.dz,at.dx);
   for(let z=-w/2+.55;z<w/2-.2;z+=1){const p=sample(l,d,z);add('cross',0xdedbc7,p.x,y+.11,p.z,2.4,.025,.46,yaw)}
   for(const dir of [-1,1]){const p=sample(l,d-dir*2,dir*(w/2+.5));add('pole',0x475b57,p.x,y+1.55,p.z,.17,3.1,.17);add('signal',0x2a3838,p.x,y+3,p.z,.45,.83,.45);signals.push([p.x-.23*dir*at.dx,y+3.09,p.z-.23*dir*at.dz]);}
  }
 }
 for(const [key,v] of Object.entries(positions))if(v.length){const g=new T.BufferGeometry();g.setAttribute('position',new T.Float32BufferAttribute(v,3));g.computeVertexNormals();const m=standard(key==='road'?0x697674:0xb9b9a7);m.side=T.DoubleSide;const o=new T.Mesh(g,m);o.receiveShadow=true;root.add(o);owned.push(g)}
 for(const {color,a} of items.values()){const o=batch(box,standard(color),a.length);a.forEach((m,i)=>o.setMatrixAt(i,m))}
 const total=sim.actors.length;
 const coat=standard(0xffffff),glass=standard(0x415b61),rubber=standard(0x313e40),head=basic(0xffe4aa),tail=basic(0xcb6346),bulb=basic(0xffe9b0),signal=basic(0x85cf9f);
 const cars=batch(box,coat,total*2),windows=batch(box,glass,total),wheels=batch(box,rubber,total*2),heads=batch(box,head,total*2),tails=batch(box,tail,total*2);
 const colors=[0xc46d54,0xe9e3ca,0x567981,0x8eab9c,0xb49a62,0xa9bac4].map(c=>new T.Color(c));
 const lights=batch(box,bulb,lamps.length);lamps.forEach(([x,y,z,a],i)=>lights.setMatrixAt(i,matrix(x,y,z,.55,.13,.85,a)));
 const indicators=batch(box,signal,signals.length);signals.forEach(([x,y,z],i)=>indicators.setMatrixAt(i,matrix(x,y,z,.18,.2,.18)));
 const c=document.createElement('canvas');c.width=c.height=48;const ctx=c.getContext('2d'),grad=ctx.createRadialGradient(24,24,0,24,24,24);grad.addColorStop(0,'rgba(255,221,147,.48)');grad.addColorStop(.5,'rgba(255,217,136,.23)');grad.addColorStop(1,'rgba(255,220,155,0)');ctx.fillStyle=grad;ctx.fillRect(0,0,48,48);
 const tex=new T.CanvasTexture(c),poolMat=new T.MeshBasicMaterial({map:tex,transparent:true,depthWrite:false,polygonOffset:true,polygonOffsetFactor:-2});materials.push(poolMat);
 const flat=new T.PlaneGeometry(1,1);flat.rotateX(-Math.PI/2);owned.push(flat);
 const pool=batch(flat,poolMat,lamps.length);lamps.forEach(([x,y,z,a],i)=>pool.setMatrixAt(i,matrix(x,y-5.13,z,9,1,7,a)));
 sim.actors.forEach((a,i)=>{cars.setColorAt(2*i,colors[a.color]);cars.setColorAt(2*i+1,colors[a.color])});
 function draw(dt){sim.step(dt);for(const [i,car] of sim.actors.entries()){
   const p=sample(car.travel,car.d,car.side),yaw=Math.atan2(p.dz,p.dx),y=car.road.y??-.4,k=car.road.closed?1:Math.min(1,car.d/3,(car.travel.length-car.d)/3);
   const at=(o,id,along,side,h,w,v,d)=>o.setMatrixAt(id,matrix(p.x+k*(p.dx*along-p.dz*side),y+h*k,p.z+k*(p.dz*along+p.dx*side),w*k,v*k,d*k,yaw));
   at(cars,i*2,0,0,.7,4.25,.73,1.77);at(windows,i,-.22,0,1.19,2.52,.53,1.58);at(cars,i*2+1,-.26,0,1.48,2.1,.11,1.53);
   for(let j=0;j<2;j++){const side=(j?1:-1);at(wheels,i*2+j,side*1.24,0,.36,.68,.47,1.84);at(heads,i*2+j,2.13,side*.6,.78,.08,.19,.38);at(tails,i*2+j,-2.13,side*.63,.83,.08,.16,.32)}
  }for(const o of [cars,windows,wheels,heads,tails])o.instanceMatrix.needsUpdate=true;signal.color.setHex(sim.red?0xea7256:0x85cf9f);
 }
 draw(0);pool.visible=false;
 return {root,count:total,draw,night(on){pool.visible=on;head.color.setHex(on?0xffebbf:0xe0d9ba);bulb.color.setHex(on?0xffe5a3:0xe7e5cc)},dispose(){root.removeFromParent();root.traverse(o=>{if(o.isInstancedMesh)o.dispose()});for(const m of materials)m.dispose();for(const g of owned)g.dispose();tex.dispose()}};
}

// Visible traffic shares the display clock with camera motion.
// Camera dragging still redraws at the display rate. Hidden/reduced-motion views sleep.
export function runStreet(life,canvas,paint,visible=()=>true){
 const media=matchMedia('(prefers-reduced-motion: reduce)');let inView=true,timer=0,last=0,paused=false;
 const active=()=>!paused&&!media.matches&&!document.hidden&&inView&&visible()&&life.count;
 function wake(){cancelAnimationFrame(timer);timer=0;last=0;if(active())timer=requestAnimationFrame(step)}
 function step(){timer=0;if(!active())return;const t=performance.now();life.draw(last?(t-last)/1000:0);last=t;paint();timer=requestAnimationFrame(step)}
 const ob=new IntersectionObserver(es=>{inView=es[0].isIntersecting;wake()});ob.observe(canvas);media.addEventListener('change',wake);document.addEventListener('visibilitychange',wake);wake();
 return {wake,pause(on){paused=on;wake()},dispose(){cancelAnimationFrame(timer);ob.disconnect();media.removeEventListener('change',wake);document.removeEventListener('visibilitychange',wake);life.dispose()}};
}
export function fixtureLights(study,model){
 const fixtures=study.parts.filter(p=>['lamp','screen','led','trimLight'].includes(p.material)&&p.kind!=='beam');
 const group=new T.Group();model.root.add(group);
 // Bare circuit boards have no luminous surfaces: use a neutral inspection light above the board.
 if(!fixtures.length&&study.id==='board'){const d=study.span,light=new T.PointLight(0xf6e7cb,d*d*.32,d*2,2);light.position.set(-d*.25,d*.55,d*.18);group.add(light)}
 const picks=[];for(const p of fixtures){if(picks.every(q=>Math.hypot(...q.position.map((n,i)=>n-p.position[i]))>study.span*.19)){picks.push(p);if(picks.length===3)break}}
 for(const p of picks){const d=Math.min(11,Math.max(.035,study.span*.20)),light=new T.PointLight(p.material==='lamp'?0xffdb9e:0xacddd3,d*d*.16,d,2);light.position.fromArray(p.position);light.position.y-=Math.min(.12,d*.025);group.add(light)}
 return group;
}
