import * as THREE from 'three';

// Render model-authored paths. Animation is a teaching aid, never telemetry.
const palette={data:0x287c75,power:0xc78c3e,cooling:0x398fc4,heat:0xc66b48};
export function buildFlows(definitions,span){
  const root=new THREE.Group(),items=[];root.renderOrder=20;
  for(const flow of definitions){
    const points=flow.points.map(p=>new THREE.Vector3().fromArray(p)),curve=new THREE.CurvePath();
    for(let i=1;i<points.length;i++)curve.add(new THREE.LineCurve3(points[i-1],points[i]));
    const material=new THREE.MeshBasicMaterial({color:palette[flow.family],transparent:true,opacity:.85,depthTest:false,depthWrite:false});
    const tube=new THREE.Mesh(new THREE.TubeGeometry(curve,Math.max(32,points.length*12),span*.0022,6,false),material);tube.renderOrder=20;
    const arrows=[];const geometry=new THREE.ConeGeometry(span*.006,span*.02,7),arrowMaterial=material.clone();arrowMaterial.opacity=1;
    for(let i=0;i<5;i++){const m=new THREE.Mesh(geometry,arrowMaterial);m.renderOrder=21;root.add(m);arrows.push(m);}
    root.add(tube);items.push({flow,curve,tube,arrows,geometry,material,arrowMaterial});
  }
  const up=new THREE.Vector3(0,1,0);
  function tick(time){for(const item of items){if(!item.tube.visible)continue;item.arrows.forEach((a,i)=>{const t=(i/5+time*.09)%1;a.position.copy(item.curve.getPoint(t));a.quaternion.setFromUnitVectors(up,item.curve.getTangent(t).normalize());});}}
  return {root,tick,set(family,active){for(const item of items){const visible=item.flow.family===family||(family==='cooling'&&item.flow.family==='heat');item.tube.visible=visible;item.arrows.forEach(a=>a.visible=visible);item.material.opacity=item.flow.id===active?.9:.22;item.arrowMaterial.opacity=item.flow.id===active?1:.25;}tick(0);},dispose(){for(const i of items){i.tube.geometry.dispose();i.geometry.dispose();i.material.dispose();i.arrowMaterial.dispose();}}};
}
