import * as THREE from 'three';
import { Reflector } from './vendor/Reflector.js';

// Generic rendering boundary. All landmark geometry and placements come from
// the compiled MoonBit module; no landmark-specific geometry is authored here.
export function createMaterials() {
  const colors = {
    ivory: '#e8e9dd', stone: '#b6baad', concrete: '#c6cbbc', paving: '#c8c7b5', paving2: '#aeb5aa',
    glass: '#3d626b', glassLight: '#65929b', glassAmber: '#556c68', silver: '#aebfbb',
    copper: '#be642d', amber: '#e09340', roof: '#7a8a86', metal: '#506567',
    grass: '#8caa74', earth: '#6b7963', sand: '#b7b794', leaf: '#527e57', lime: '#99b36a',
    sage: '#7f9a68', pine: '#3e6857', shrub: '#789354', bark: '#746651', blossom: '#deafa9',
    flower: '#ad96b8', wood: '#a68c64', asphalt: '#687575', mark: '#e7dfb9',
    water: '#659994', ripple: '#a4c2b4', coral: '#ad6551', navy: '#405b62', skin: '#d4b99b',
    rubber: '#394748', cable: '#a5b8b6', lamp: '#e4d9a8', trimLight: '#e4d9b3',
    plaster:'#eeeae0', oak:'#c39d6b', fabric:'#647a72', linen:'#c5c3ab',
    carpetSage:'#b8c4af', carpetRose:'#c9b4a8', carpetSand:'#d5cbb3',
    terracotta:'#b47a5e', screen:'#79a3ad', partitionGlass:'#b1d0cc',
  };
  const materials = {};
  for (const [key, color] of Object.entries(colors)) {
    const glass = key.startsWith('glass');
    materials[key] = new THREE.MeshStandardMaterial({
      color, roughness: glass ? 0.22 : key === 'water' ? 0.16 : 0.8,
      metalness: glass ? 0.42 : ['silver','metal','copper','cable'].includes(key) ? 0.48 : 0,
      side: THREE.DoubleSide,
    });
    if (key === 'lamp' || key === 'trimLight') {
      materials[key].emissive.set('#ffe1a0');
      materials[key].emissiveIntensity = 0.1;
    }
  }
  materials.partitionGlass.transparent=true;materials.partitionGlass.opacity=.23;materials.partitionGlass.depthWrite=false;materials.partitionGlass.roughness=.18;
  return materials;
}

function roundedShape(w, d, radius) {
  const s = new THREE.Shape();
  const x = -w / 2, z = -d / 2, r = Math.min(radius,w/2,d/2);
  s.moveTo(x+r,z);s.lineTo(x+w-r,z);s.quadraticCurveTo(x+w,z,x+w,z+r);
  s.lineTo(x+w,z+d-r);s.quadraticCurveTo(x+w,z+d,x+w-r,z+d);
  s.lineTo(x+r,z+d);s.quadraticCurveTo(x,z+d,x,z+d-r);
  s.lineTo(x,z+r);s.quadraticCurveTo(x,z,x+r,z);
  return s;
}

function extrude(shape,height) {
  const g = new THREE.ExtrudeGeometry(shape,{depth:height,bevelEnabled:false,curveSegments:8,steps:1});
  // The authored outline is X/Z; extrusion becomes +Y without mirroring it.
  const a = g.attributes.position;
  for (let i=0;i<a.count;i++) {const y=a.getY(i),z=a.getZ(i);a.setXYZ(i,a.getX(i),z,y);}
  // Swapping Y and Z reverses handedness. Restore triangle winding explicitly.
  for(let i=0;i<a.count;i+=3){const bx=a.getX(i+1),by=a.getY(i+1),bz=a.getZ(i+1);a.setXYZ(i+1,a.getX(i+2),a.getY(i+2),a.getZ(i+2));a.setXYZ(i+2,bx,by,bz);}
  g.computeVertexNormals();g.computeBoundingSphere();return g;
}

export function buildStudy(data,materials) {
  const root = new THREE.Group(), context = new THREE.Group(), landmark = new THREE.Group();
  root.add(context,landmark);root.name=data.id;
  const layers=new Map([['context',context],['landmark',landmark]]);
  const geometryCache = new Map(), batches = new Map(), owned = new Set();
  const ownedMaterials = [], ownedTextures = [];
  const primitiveGeometry = {
    box:new THREE.BoxGeometry(1,1,1),
    sphere:new THREE.SphereGeometry(.5,10,8),
    crown:new THREE.IcosahedronGeometry(.5,1),
    cone:new THREE.ConeGeometry(.5,1,8),
    cylinder:new THREE.CylinderGeometry(.5,.5,1,8),
    beam:new THREE.CylinderGeometry(1,1,1,6),
    girder:new THREE.BoxGeometry(1,1,1),
  };
  Object.values(primitiveGeometry).forEach(g=>owned.add(g));
  const dummy = new THREE.Object3D(), up = new THREE.Vector3(0,1,0);
  let reflector;
  for (const p of data.parts) {
    if (!materials[p.material]) throw new Error('Unknown material '+p.material);
    if(!layers.has(p.layer)){const layer=new THREE.Group();layer.name=p.layer;landmark.add(layer);layers.set(p.layer,layer);}
    const group = layers.get(p.layer);
    if(p.kind==='sign') {
      const canvas=document.createElement('canvas');canvas.width=1024;canvas.height=256;
      const ctx=canvas.getContext('2d');ctx.fillStyle='#334643';ctx.textAlign='center';ctx.textBaseline='middle';
      ctx.font='500 150px "PingFang SC", "Microsoft YaHei", sans-serif';ctx.fillText(p.caption,512,128,980);
      const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;ownedTextures.push(texture);
      const material=new THREE.MeshStandardMaterial({map:texture,transparent:true,roughness:.7,depthWrite:false,side:THREE.DoubleSide});ownedMaterials.push(material);
      const geometry=new THREE.PlaneGeometry(p.scale[0],p.scale[1]);owned.add(geometry);
      const mesh=new THREE.Mesh(geometry,material);mesh.position.fromArray(p.position);mesh.rotation.y=p.rotation;mesh.userData.originalMaterial=material;group.add(mesh);continue;
    }
    if(p.kind==='triangles') {
      const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(p.points.flat(),3));g.computeVertexNormals();g.computeBoundingSphere();owned.add(g);
      const m=new THREE.Mesh(g,materials[p.material]);m.castShadow=true;m.receiveShadow=true;m.userData.originalMaterial=m.material;group.add(m);continue;
    }
    // Large water surfaces get a live reflection; small water gardens use PBR.
    if(p.material==='water'&&p.scale[0]>200) {
      const g=new THREE.PlaneGeometry(p.scale[0],p.scale[2]);owned.add(g);
      reflector=new Reflector(g,{color:0x74a29f,textureWidth:768,textureHeight:768,clipBias:0.003});
      reflector.rotation.x=-Math.PI/2;reflector.position.set(p.position[0],p.position[1]+p.scale[1]/2+.01,p.position[2]);
      reflector.userData.originalMaterial=reflector.material;group.add(reflector);continue;
    }
    let key = p.kind, geometry = primitiveGeometry[p.kind];
    dummy.position.fromArray(p.position);dummy.rotation.set(0,p.rotation,0);dummy.scale.fromArray(p.scale);
    if(p.kind==='profile') {
      key='profile:'+JSON.stringify(p.points)+':'+p.scale[1];
      geometry=geometryCache.get(key);
      if(!geometry){const shape=new THREE.Shape(p.points.map(v=>new THREE.Vector2(v[0],v[1])));shape.closePath();geometry=extrude(shape,p.scale[1]);geometryCache.set(key,geometry);owned.add(geometry);}
      dummy.scale.set(1,1,1);
    } else if(p.kind==='round') {
      key='round:'+p.scale.join(',');geometry=geometryCache.get(key);
      if(!geometry){geometry=extrude(roundedShape(p.scale[0],p.scale[2],Math.min(p.scale[0],p.scale[2])*.05),p.scale[1]);geometry.translate(0,-p.scale[1]/2,0);geometryCache.set(key,geometry);owned.add(geometry);}
      dummy.scale.set(1,1,1);
    } else if(p.kind==='beam'||p.kind==='girder') {
      const a=new THREE.Vector3().fromArray(p.position),b=new THREE.Vector3().fromArray(p.points[0]);
      const direction=b.clone().sub(a),length=direction.length();
      if(length<1e-7)continue;
      dummy.position.copy(a).add(b).multiplyScalar(.5);dummy.quaternion.setFromUnitVectors(up,direction.normalize());dummy.scale.set(p.scale[0],length,p.kind==='girder'?p.scale[2]:p.scale[0]);
    }
    if(!geometry)throw new Error('Unsupported primitive '+p.kind);
    dummy.updateMatrix();
    const batchKey=p.layer+'|'+p.material+'|'+key;
    if(!batches.has(batchKey))batches.set(batchKey,{geometry,material:materials[p.material],group,matrices:[],entities:[]});
    batches.get(batchKey).matrices.push(dummy.matrix.clone());
    batches.get(batchKey).entities.push(p.caption||'');
  }
  for(const b of batches.values()){
    const mesh=new THREE.InstancedMesh(b.geometry,b.material,b.matrices.length);
    b.matrices.forEach((m,i)=>mesh.setMatrixAt(i,m));mesh.instanceMatrix.needsUpdate=true;mesh.computeBoundingSphere();mesh.castShadow=!b.material.transparent;mesh.receiveShadow=true;mesh.userData.originalMaterial=b.material;mesh.userData.entities=b.entities;b.group.add(mesh);
  }
  return {root,context,landmark,layers,reflector,dispose(){if(reflector)reflector.getRenderTarget().dispose();if(reflector)reflector.material.dispose();root.traverse(o=>{if(o.isInstancedMesh)o.dispose();});owned.forEach(g=>g.dispose());ownedMaterials.forEach(m=>m.dispose());ownedTextures.forEach(t=>t.dispose());}};
}
