// Elevation dimensions are in metres along the source footprint and up from grade.
// Both the orbit viewer and the town painter consume these exact openings.
export function decodeStudyRing(text) {
  const raw = Uint8Array.from(atob(text), c => c.charCodeAt(0));
  const view = new DataView(raw.buffer);
  return Array.from({length: raw.length / 4}, (_, i) =>
    [view.getInt16(4*i, true) / 10, view.getInt16(4*i+2, true) / 10]);
}

const palettes = {
  housing: ['#d7c6ac','#b5a38d','#efe1c7','#bfb8a9','#596976','#6b8490','#96aeb1','#59656b'],
  limestone: ['#e3d8bb','#ada695','#f4ead1','#bab8a9','#42576c','#587687','#89a6ae','#666f75'],
  garden: ['#d8d0c1','#aa9884','#ede2ce','#aaa99f','#384e61','#526b7c','#87a2ab','#535f6a'],
  collegiate: ['#985a4c','#d8c8aa','#f0e3c9','#b8ada0','#503e39','#586672','#78858a','#766457'],
  campus: ['#c7c6b9','#89938f','#eee8d8','#b8c0ba','#405560','#557984','#82a4a9','#64757a'],
  industry: ['#a8b1ad','#6d7878','#d8ddcf','#a0a8a6','#354a50','#546f73','#819894','#515f62'],
  xingke: ['#616b70','#374549','#d4d8cf','#a0aaa8','#374d4e','#728980','#99aca1','#adb8b6'],
  delivery: ['#e6e5dc','#3e484e','#f6f3e7','#c2c5c2','#364854','#596d78','#879ba2','#c96c3d'],
  silver: ['#aeb9ba','#717f83','#d9ded6','#aab4b1','#43555a','#677f82','#92aaa7','#566368'],
  robotics: ['#e1dfd2','#9ca8a5','#f2eddb','#bac5bc','#2d4755','#4c6978','#829ca3','#888f8a'],
  hall: ['#d3c3a9','#927f70','#ebdfc7','#b3ac99','#425753','#647b74','#91a69b','#706d65']
};
const roles = ['wall','base','trim','roof','reveal','glass','sky','metal'];
const residential = {yiyuan:'collegiate', xingyao:'limestone', guoyu:'garden', guoxian:'garden', huanyu:'garden', jinmao:'limestone', peak:'limestone', rong:'garden'};
function hash(s) {
  let n=2166136261;
  for(const ch of s)n=Math.imul(n ^ ch.charCodeAt(0),16777619);
  return n>>>0;
}
export function facadePlan(project, form, height, ring, id='') {
  const seed=hash(project+'/'+id);
  const family=project==='xingke'||project==='robotics'?project:form==='homes'?'housing':
    form==='factory'?'industry':form==='hall'?'hall':'campus';
  let scheme=family;
  if(family==='housing')scheme=residential[project]||'housing';
  if(family==='xingke'&&form==='hall')scheme='silver';
  if(project==='xingke'&&id==='xingke/东组团/东侧1号厂房')scheme='delivery';
  const colors=Object.fromEntries(roles.map((k,i)=>[k,palettes[scheme][i]]));
  colors.lamp=colors.sky;
  const winding=Math.sign(ring.reduce((a,p,i)=>{const q=ring[(i+1)%ring.length];return a+p[0]*q[1]-q[0]*p[1]},0)) || 1;
  const edges=ring.map(([x,z],i)=>{
    const [x1,z1]=ring[(i+1)%ring.length], len=Math.hypot(x1-x,z1-z);
    const tx=(x1-x)/(len||1),tz=(z1-z)/(len||1);
    return {x,z,len,tx,tz,nx:tz*winding,nz:-tx*winding,index:i};
  });
  // A broad face looking south is a better residential frontage than a long blind gable.
  const score=e=>e.len*(.74+.26*e.nz);
  const primary=edges.reduce((best,e)=>score(e)>score(best)?e:best);
  for(const e of edges){
    const alignment=e.nx*primary.nx+e.nz*primary.nz;
    e.side=alignment>.68?'front':alignment<-.68?'back':'end';
  }
  const level=scheme==='collegiate'?2.9:family==='housing'?3.05:family==='industry'||family==='xingke'?5.6:family==='hall'?5.1:4.05;
  return {family,scheme,form,height,seed,colors,edges,floors:Math.max(1,Math.round(height/level))};
}

// Each part occupies a rectangle on the actual wall. Depth is the distance
// its front projects from the wall, also defining the paint order in plan view.
// Xingke's traced roofs start on the northwest corner. The solar strips run
// across the pitch, leaving the light service zones open at either end.
export function solarRows(plan, ring) {
  if (plan.family !== 'xingke') return [];
  const [nw,ne,se,sw] = ring;
  const point = (u,v) => nw.map((_,i) =>
    (1-v)*((1-u)*nw[i]+u*ne[i]) + v*((1-u)*sw[i]+u*se[i]));
  const count = Math.max(2,Math.round(plan.edges[1].len*.68/3.2));
  return Array.from({length:count},(_,i) => {
    const v=.15+.70*i/count, end=v+.55/count;
    return [point(.15,v),point(.83,v),point(.83,end),point(.15,end)];
  });
}

export function elevation(plan,e,emit) {
  const {family,scheme,height:h,floors:n,seed}=plan, w=e.len, front=e.side==='front', end=e.side==='end';
  if(w<1.2)return;
  const step=h/n, idx=e.index;
  function part(x,y,width,height,role,depth) {
    const x1=Math.max(.02,x),x2=Math.min(w-.02,x+width);
    const y1=Math.max(0,y),y2=Math.min(h,y+height);
    if(x2>x1+.015&&y2>y1+.015)emit(x1,y1,x2-x1,y2-y1,role,depth);
  }
  const color=(col,row)=> ((seed%53+col*17+row*29+idx*7)%13<2?'lamp':
    (col+idx)%5===0?'sky':'glass');
  // In a glass wall each bay has spandrels at floor level; mullions stay slender.
  function curtain(x,width,y,high,pitch=3.25) {
    if(width<.55||high<.55)return;
    part(x,y,width,high,'reveal',.068);
    const cols=Math.max(1,Math.round(width/pitch)),levels=Math.max(1,Math.round(high/step));
    const bay=width/cols,fl=high/levels;
    for(let row=0;row<levels;row++)for(let col=0;col<cols;col++){
      part(x+col*bay+.10,y+row*fl+.18,bay-.20,fl-.44,color(col,row),.10);
    }
  }
  function repeats(span,build) {
    const count=Math.max(1,Math.round(w/span)),bay=w/count;
    for(let i=0;i<count;i++)build(i*bay,bay,i,count);
  }
  part(0,0,w,Math.min(1,h*.11),'base',.065);
  if(scheme==='collegiate') {
    // Approximate living and bedroom openings from the published unit schedules.
    const collegiateOpening=i=>[2.4,1.8,1.5,1.8][i%4];
    const baseHeight=Math.min(2*step,h*.22);
    part(0,0,w,baseHeight,'base',.09);
    repeats(end?6.8:4.3,(x,b,i)=>{
      const ww=Math.min(b*.75,end?1.5:collegiateOpening(i)), left=x+(b-ww)/2;
      for(let f=0;f<n;f++){
        const sill=f*step+.24*step, wh=Math.min(step*.6,i%3===0?1.7:1.5);
        part(left-.13,sill-.13,ww+.26,wh+.26,'trim',.17);
        part(left,sill,ww,wh,'reveal',.20);
        part(left+.09,sill+.08,ww-.18,wh-.16,color(i,f),.23);
        part(left+ww*.48,sill,.09,wh,'metal',.26);
      }
      if(!end&&i%2===0)part(x+.08,baseHeight,.36,h-baseHeight,'trim',.39);
    });
    for(const y of [baseHeight,h-.72])part(0,y,w,.26,'trim',.58);
  } else if(scheme==='delivery'){
    const lower=h*.32;
    part(0,0,w,lower,'base',.06);
    curtain(w*.07,w*.86,.45,lower-.9,3.3);
    for(const y of [lower,h*.64]) {
      curtain(w*.035,w*.93,y+h*.055,h*.20,3.6);
      part(0,y,w,h*.052,'trim',.48);
    }
    if(front&&w>16){
      // The completion photo shows one coloured recess along the long elevation.
      part(w*.61,h*.71,w*.21,h*.18,'reveal',.14);
      part(w*.61,h*.86,w*.21,h*.045,'metal',.28);
      part(w*.61,h*.71,.52,h*.17,'metal',.27);
    }
  } else if(family==='housing') {
    repeats(end?7.6:5.55,(x,b,i,count)=>{
      const stair=!end&&!front&&i===Math.floor(count/2);
      if(stair)part(x+b*.19,.3,b*.62,h-.75,'base',.09);
      const balcony=front&&!end&&(scheme!=='housing'||i%3!==(seed%3));
      for(let f=0;f<n;f++){
        const y=f*step, ww=b*(end?.28:stair?.39:balcony?.82:.64), xx=x+(b-ww)/2;
        part(xx-.14,y+step*.23-.1,ww+.28,step*.61+.2,'reveal',.13);
        part(xx,y+step*.23,ww,step*.61,color(i,f),.17);
        if(ww>1.8)part(xx+ww*.51,y+step*.23,.105,step*.61,'trim',.21);
        if(balcony){
          part(xx-.17,y+step*.16,ww+.34,.19,'trim',.88);
          part(xx-.05,y+step*.22,ww+.10,step*.18,'metal',.70);
        }
      }
      if(front&&scheme!=='housing'&&i%3===0)part(x+.09,.48,.32,h-.93,'trim',.38);
    });
  } else if(family==='xingke'||family==='industry'){
    const feature=front && w>9, core=feature?Math.min(w*.18,8):0;
    const curtainWidth=feature?w*(family==='xingke'?.40:.25):0, solid=w-core-curtainWidth;
    // Intermittent slot glazing belongs to the dark cladding only.
    for(let level=end?1:0;level<n;level++){
      const y=level*step+step*(level===0?.68:.53);
      const margin=Math.min(solid*.14,3);
      const segments=Math.max(1,Math.ceil(solid/20)), bay=(solid-2*margin)/segments;
      for(let k=0;k<segments;k++){
        const span=bay*(end?.69:.86);
        curtain(margin+k*bay,span,y,Math.min(1.37,step*.24),3.3);
      }
    }
    if(feature){
      curtain(solid,curtainWidth,.22,h-.56,2.75);
      part(w-core,.15,core,h-.43,'metal',.28);
      for(let y=step*.49;y<h-.3;y+=step*.5)part(w-core,y,core,.085,'reveal',.32);
      part(solid,.09,curtainWidth,.30,'trim',.42);
    }else if(!end&&w>10){
      const door=Math.min(5,w*.18);
      part(w*.13,.1,door,Math.min(3.1,step*.58),'base',.15);
      for(let y=.6;y<Math.min(3.1,step*.58);y+=.55)part(w*.13,y,door,.10,'metal',.20);
    }
  } else if(family==='robotics'){
    const gable=end&&w>6;
    const margin=Math.min(2.3,w*.09),x=gable?w*.56:margin, width=gable?w*.26:w-2*margin;
    curtain(x,width,.60,h-1.35,3.15);
    const groups=Math.max(1,Math.round(width/9.8)),pitch=width/groups;
    for(let i=0;i<groups;i++){
      const axis=x+i*pitch;
      part(axis,.18,.38,h-.40,'trim',.64);
      part(axis+.78,.18,.27,h-.40,'trim',.56);
    }
    part(x+width-.38,.18,.38,h-.40,'trim',.64);
    part(x-.18,h-.92,width+.36,.65,'trim',.72);
    if(h>18)for(let f=2;f<n;f+=3)part(x,f*step-.2,width,.48,'wall',.39);
  } else if(family==='hall') {
    if(front&&w>5){
      curtain(w*.17,w*.66,.2,h*.68,2.6);
      part(w*.13,h*.68,w*.74,.42,'trim',1.15);
    }else{
      curtain(w*.10,w*.80,h*.62,Math.min(1.6,h*.23),3.1);
    }
  } else {
    const margin=Math.min(w*.09,2.1), x=end?w*.22:margin, width=w-x-(end?w*.23:margin);
    curtain(x,width,.28,h-.94,2.95);
    const spans=Math.max(1,Math.round(width/(front?8:6.5)));
    for(let i=0;i<=spans;i++)part(x+width*i/spans-.20,.25,.40,h-.62,'trim',.49);
    for(let f=1;f<n;f++)part(x,f*step-.05,width,front?.27:.45,'wall',.31);
    if(front&&width>7)part(x,.91*step,Math.min(7.4,width),.35,'trim',1.25);
  }
  part(0,h-.30,w,.30,'trim',.30);
}


// Future Yiyuan, developer attachment 4 and its numbered aerial. At buildings
// 10–12 the low unit is on the east end. Building 9 rises at the west end.
// Equal unit widths approximate the stepped envelope within its reviewed roof.
const yiyuanWestToEast={
  'yiyuan-962102794-3':[7,5,5],
  'yiyuan-962102794-6':[6,6,6,4],
  'yiyuan-962102794-9':[6,6,6,4],
  'yiyuan-962102794-12':[7,7,7,4]
};
export function buildingBands(id,metric,height){
 const floors=yiyuanWestToEast[id];
 if(!floors||metric.length!==4)return [{height,shape:ring=>ring}];
 const order=metric.map((_,i)=>i).sort((a,b)=>metric[a][0]-metric[b][0]);
 const northFirst=(a,b)=>metric[a][1]-metric[b][1];
 const [nw,sw]=order.slice(0,2).sort(northFirst),[ne,se]=order.slice(2).sort(northFirst);
 const mix=(a,b,t)=>[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t];
 const result=[];
 for(let i=0;i<floors.length;){
   let j=i+1;while(j<floors.length&&floors[j]===floors[i])j++;
   const l=i/floors.length,r=j/floors.length;
   result.push({height:floors[i]*2.9,shape:p=>[mix(p[nw],p[ne],l),mix(p[nw],p[ne],r),mix(p[sw],p[se],r),mix(p[sw],p[se],l)]});i=j;
 }
 return result;
}
