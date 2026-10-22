import * as THREE from 'three';
import {buildStudy, createMaterials} from './scene-adapter.js';

// Cold-cache fallback / authoring export only. Never imported for shipped tiles.
// Original geometry, calibrated camera, materials and lighting are unchanged.
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
    const pad=8,left=box.min.x-pad,right=box.max.x+pad,bottom=box.min.y-pad,top=box.max.y+pad;
    const width=right-left,height=top-bottom;
    const scene=new THREE.Scene();scene.add(model.root);
    scene.add(new THREE.AmbientLight(0xfff8e5,2));
    const sun=new THREE.DirectionalLight(0xffffff,2.3);sun.position.set(-350,600,900);scene.add(sun);
    const camera=new THREE.OrthographicCamera(left,right,top,bottom,1,20000);camera.position.z=10000;
    const ratio=Math.min(4,2048/Math.max(width,height));
    renderer.setSize(Math.ceil(width*ratio),Math.ceil(height*ratio),false);renderer.render(scene,camera);
    const image=document.createElement('canvas');image.width=renderer.domElement.width;image.height=renderer.domElement.height;
    image.getContext('2d').drawImage(renderer.domElement,0,0);
    return {left,top,width,height,source:image.toDataURL('image/png')};
  } finally {model.dispose();}
}
export async function bakeTiles(places) {
  await import('./models.js');
  const renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,preserveDrawingBuffer:true});
  const materials=createMaterials(),records=[];
  try {
    renderer.setClearColor(0,0);renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;
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
