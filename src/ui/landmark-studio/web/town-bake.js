import * as THREE from 'three';
import {buildStudy, createMaterials} from './scene-adapter.js';

// Cold-cache fallback / authoring export only. Never imported for shipped tiles.
// Original geometry and calibrated camera remain unchanged. The map owns a
// daylight material treatment; the complete viewer keeps createMaterials().
const bridge = p => p.id.endsWith('bridge');
function matrix(p) {
  const [ex,ey]=p.east, [sx,sy]=p.south, up=p.elevation;
  return new THREE.Matrix4().set(32*(ex-ey),0,32*(sx-sy),0,
    -16*(ex+ey),up,-16*(sx+sy),-up*(bridge(p)?10.2:2.3),
    16*(ex+ey),up,16*(sx+sy),0, 0,0,0,1);
}
function frontPart(part,p) {
  const ps=part.kind==='triangles'?part.points:[part.position,...(part.kind==='beam'||part.kind==='girder'?part.points:[])];
  const mean=ps.reduce((a,b)=>a.map((x,i)=>x+b[i]/ps.length),[0,0,0]);
  return mean[1]>11 && mean[2]*(p.south[0]+p.south[1])>0;
}
function bake(renderer,materials,study,p,frontOnly=false) {
  const parts=study.parts.filter(part=>{
    if(frontOnly)return part.layer!=='context'&&frontPart(part,p);
    if(part.layer!=='context')return true;
    const courtyard=part.kind==='round'&&part.material==='paving'&&part.scale[0]===263&&part.scale[2]===151;
    return !bridge(p)&&(courtyard||(Math.abs(part.position[0])<128&&Math.abs(part.position[2])<73&&part.scale[0]<140&&part.scale[2]<140&&part.material!=='asphalt'));
  });
  const model=buildStudy({...study,parts},materials);
  try {
    model.root.matrixAutoUpdate=false;model.root.matrix.copy(matrix(p));model.root.updateMatrixWorld(true);
    const box=new THREE.Box3().setFromObject(model.root);
    const sunVector=new THREE.Vector3(-350,600,900),ground=p.elevation*(bridge(p)?10.2:2.3);
    // Include the ground-projected bounds: shadows must not be cut at the old
    // sprite rectangle. This changes image padding, never model placement.
    const bounds=box.clone();
    if(!frontOnly)for(const x of [box.min.x,box.max.x])for(const y of [box.min.y,box.max.y])for(const z of [box.min.z,box.max.z]){
      const amount=Math.max(0,(y+z-ground)/(sunVector.y+sunVector.z));
      bounds.expandByPoint(new THREE.Vector3(x,y,z).addScaledVector(sunVector,-amount));
    }
    const pad=8,left=bounds.min.x-pad,right=bounds.max.x+pad,bottom=bounds.min.y-pad,top=bounds.max.y+pad;
    const width=right-left,height=top-bottom;
    const scene=new THREE.Scene();scene.add(model.root);
    scene.add(new THREE.AmbientLight(0xe7f4ee,.85));
    const sun=new THREE.DirectionalLight(0xfff0d5,2.1);sun.position.copy(sunVector);scene.add(sun);
    let receiver;
    if(!frontOnly){
      sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);sun.shadow.camera.left=-500;sun.shadow.camera.right=500;sun.shadow.camera.top=500;sun.shadow.camera.bottom=-500;sun.shadow.camera.far=2400;sun.shadow.normalBias=.3;sun.shadow.bias=-.0001;
      receiver=new THREE.Mesh(new THREE.PlaneGeometry(3000,3000),new THREE.ShadowMaterial({color:'#355d51',opacity:.28,depthWrite:false}));
      receiver.rotation.x=-Math.PI/4;receiver.position.y=ground-.08;receiver.receiveShadow=true;scene.add(receiver);
    }
    const camera=new THREE.OrthographicCamera(left,right,top,bottom,1,20000);camera.position.z=10000;
    const ratio=Math.min(4,2048/Math.max(width,height));
    renderer.setSize(Math.ceil(width*ratio),Math.ceil(height*ratio),false);renderer.render(scene,camera);
    const image=document.createElement('canvas');image.width=renderer.domElement.width;image.height=renderer.domElement.height;
    image.getContext('2d').drawImage(renderer.domElement,0,0);
    const result={left,top,width,height,source:image.toDataURL('image/png')};
    if(receiver){receiver.geometry.dispose();receiver.material.dispose();}sun.shadow.map?.dispose();
    return result;
  } finally {model.dispose();}
}
export async function bakeTiles(places) {
  await import('./models.js');
  const renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,preserveDrawingBuffer:true});
  const materials=createMaterials(),records=[];
  // Diffuse blue-green glass keeps the facade readable without a black/white
  // window checkerboard. No model parts, roof details or bridge ribs are removed.
  const palette={ivory:'#fff2d7',stone:'#c3d2bc',concrete:'#d9dfc7',paving:'#ede2c6',paving2:'#d8d7b6',
    glass:'#5296a5',glassLight:'#83c4cb',glassAmber:'#77a79a',silver:'#a9c1b2',roof:'#789f8d',metal:'#467b84',
    copper:'#d68d57',amber:'#f0c270',grass:'#abd85e',earth:'#67894f',sand:'#eeddb8',leaf:'#347c4d',lime:'#a6cf60',sage:'#6fa052',pine:'#286147',shrub:'#70aa4f',bark:'#967a55',blossom:'#f2a7ae',flower:'#c8ace5',wood:'#c7a475',asphalt:'#a2b299',water:'#319fc8'};
  for(const [key,m] of Object.entries(materials)){
    if(palette[key])m.color.set(palette[key]);m.metalness=0;m.roughness=.92;
    if(key.startsWith('glass')){m.emissive.copy(m.color);m.emissiveIntensity=.03;}
  }
  try {
    renderer.setClearColor(0,0);renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.05;
    renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
    for(const p of places){
      const study=globalThis.wenyuLandmarkStudies.find(s=>s.id===p.id);
      records.push({id:p.id,...bake(renderer,materials,study,p),front:bridge(p)?bake(renderer,materials,study,p,true):null});
      await new Promise(resolve=>requestAnimationFrame(resolve));
    }
    return records;
  } finally {
    Object.values(materials).forEach(m=>m.dispose());renderer.dispose();renderer.forceContextLoss();
  }
}
