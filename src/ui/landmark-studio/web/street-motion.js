// Straight-line distances along a polyline. x east, z south: the right-hand
// curb is the left normal of the tangent in these coordinates.
export function lane(points) {
  const p=[],s=[];let length=0;
  for(const v of points){const a=p.at(-1),d=a?Math.hypot(v[0]-a[0],v[1]-a[1]):0;if(a&&d<.02)continue;length+=d;p.push(v);s.push(length)}
  return {p,s,length};
}
export function sample(l,d,side=0) {
  const {p,s,length}=l;d=Math.max(0,Math.min(length,d));let i=1;
  while(i<s.length-1&&s[i]<d)i++;const a=p[i-1],b=p[i],k=1/(s[i]-s[i-1]),dx=(b[0]-a[0])*k,dz=(b[1]-a[1])*k;
  return {x:a[0]+dx*(d-s[i-1])-dz*side,z:a[1]+dz*(d-s[i-1])+dx*side,dx,dz};
}
export function frontage(rings){
  const outside=(p,r)=>{let v=false;for(let i=0,j=r.length-1;i<r.length;j=i++){const a=r[i],b=r[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])v=!v}return !v};
  // For a local plan with no surveyed streets, sketch one connected perimeter,
  // then look for an actual clear passage between opposing parcel edges.
  const pts=rings.flat().sort((a,b)=>a[0]-b[0]||a[1]-b[1]);
  const cross=(a,b,c)=>(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
  function half(ps){const res=[];for(const p of ps){while(res.length>1&&cross(res.at(-2),res.at(-1),p)<=0)res.pop();res.push(p)}res.pop();return res}
  const hull=[...half(pts),...half([...pts].reverse())];if(hull.length<3)return [];
  const normal=(a,b)=>{const k=1/(Math.hypot(b[0]-a[0],b[1]-a[1])||1);return [(b[1]-a[1])*k,(a[0]-b[0])*k]};
  const loop=[];for(let i=0;i<hull.length;i++){const p=hull[i],u=normal(hull[(i+hull.length-1)%hull.length],p),v=normal(p,hull[(i+1)%hull.length]);
   let angle=Math.atan2(u[1],u[0]),turn=(Math.atan2(v[1],v[0])-angle+2*Math.PI)%(2*Math.PI),n=Math.max(1,Math.ceil(turn/.32));
   for(let k=0;k<=n;k++){let a=angle+turn*k/n;loop.push([p[0]+7*Math.cos(a),p[1]+7*Math.sin(a)])}}
  loop.push(loop[0]);const roads=[{p:loop,w:6.4,closed:true}];
  const edges=rings.map(r=>r.map((a,i)=>lane([a,r[(i+1)%r.length]])).filter(l=>l.length>25));
  for(let i=0;i<edges.length;i++)for(let j=i+1;j<edges.length;j++){let best=null;
   for(const a of edges[i])for(const b of edges[j]){const u=sample(a,a.length/2),v=sample(b,b.length/2);
    const dot=u.dx*v.dx+u.dz*v.dz,side=(v.x-u.x)*(-u.dz)+(v.z-u.z)*u.dx,along=(v.x-u.x)*u.dx+(v.z-u.z)*u.dz;
    if(Math.abs(dot)<.93||Math.abs(side)<10||Math.abs(side)>40||Math.min(a.length,b.length)*.6<Math.abs(along))continue;
    const x=(u.x+v.x)/2,z=(u.z+v.z)/2;const hits=[];
    for(let q=1;q<loop.length;q++){const l=loop[q-1],r=loop[q],dx=r[0]-l[0],dz=r[1]-l[1],det=u.dx*dz-u.dz*dx;if(Math.abs(det)<1e-6)continue;
     const t=((l[0]-x)*dz-(l[1]-z)*dx)/det,h=((l[0]-x)*u.dz-(l[1]-z)*u.dx)/det;if(h>=0&&h<=1)hits.push(t)}
    if(hits.length!==2)continue;hits.sort((a,b)=>a-b);const p=hits.map(t=>[x+u.dx*t,z+u.dz*t]);const link=lane(p);let clear=true;
    for(let d=0;d<=link.length+2&&clear;d+=2)for(const off of [-4.8,0,4.8]){const c=sample(link,d,off);if(rings.some(r=>!outside([c.x,c.z],r))){clear=false;break}}
    if(clear&&(!best||Math.abs(side)<best.gap))best={p,w:6.4,gap:Math.abs(side)};
   }if(best)roads.push(best)
  }return roads;
}
export function traffic(roads){
 const actors=[],lanes=[];let seconds=0;
 roads.forEach((road,i)=>{const path=lane(road.p);if(path.length<22)return;for(const dir of road.dir?[road.dir]:[1,-1]){
   const queue=[],n=Math.min(6,Math.max(1,Math.floor(path.length/70)));
   const signal=road.signal?path.length*.54:null;
   const travel=dir>0?path:lane([...road.p].reverse());const stop=signal===null?null:(dir>0?signal:path.length-signal)-5;
   lanes.push({queue,length:path.length,stop});
   for(let j=0;j<n;j++){const car={road,travel,dir,side:road.dir?0:Math.min(5.4,road.w*.24),d:(j+.18+((i*7+(dir>0?3:5))%11)/20)*path.length/n,v:0,target:5+(i*3+j*2)%4,color:(i*3+j+(dir>0?1:3))%6};queue.push(car);actors.push(car)}
 }});
 return {actors,get red(){return seconds%16>=10},step(dt){dt=Math.max(0,Math.min(.18,dt));seconds+=dt;
   for(const {queue,length,stop} of lanes){const distances=queue.map(a=>a.d);
    queue.forEach((a,i)=>{let gap=queue.length===1?Infinity:(distances[(i+1)%queue.length]-a.d+length)%length-6;
     if(stop!==null&&this.red&&stop>=a.d)gap=Math.min(gap,stop-a.d);
     const v=Math.min(a.target,Math.sqrt(2*3.5*Math.max(0,gap)));a.v+=Math.max(-5.5*dt,Math.min(2.8*dt,v-a.v));a.d=(a.d+Math.max(0,Math.min(gap,a.v*dt)))%length;
    });
   }
 }};
}
