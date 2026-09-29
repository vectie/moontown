// DOM / file / HTTP adapter. Validation and planning arithmetic live in MoonBit.
const $=id=>document.getElementById(id);
let planning, observation=null, source=null, receivedAt=null, activePanel='planning', requestSerial=0,exportUrl=null;
const node=(tag,text,className)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(className)n.className=className;return n;};
const number=(n,d=1)=>Number(n).toFixed(d);
const rows=()=>Array.from({length:12},(_,i)=>({rack:(i<6?'A':'B')+(i%6+1),used:26,total:42,servers:12,kw:planning.rack_kw}));
const ageText=stamp=>{
  const t=typeof stamp==='number'?stamp:Date.parse(stamp),age=Date.now()-t;
  if(!Number.isFinite(t)||t<=0)return {text:'时间未提供 / 无法判定新鲜度',stale:true};
  if(age< -60000)return {text:'时间在未来 / 时钟需核对',stale:true};
  return {text:`${new Date(t).toLocaleString()} · ${age>300000?'已过期（>5 分钟）':'5 分钟内记录'}`,stale:age>300000};
};
function table(headers,values){const t=node('table'),head=node('thead'),r=node('tr');for(const h of headers)r.append(node('th',h));head.append(r);t.append(head);const body=node('tbody');for(const row of values){const tr=node('tr');for(const v of row)tr.append(node('td',String(v)));body.append(tr);}t.append(body);return t;}
function drawPlanning(onRack){
  planning=globalThis.moonDataCenterReport(Number($('load').value));
  $('load-label').textContent=planning.load_percent+'%';$('metrics').replaceChildren();
  for(const [value,unit,label] of [[planning.racks,'柜','设计机位'],[planning.servers,'台','2U 服务器'],[number(planning.it_kw),'kW','机架 IT 估算'],[number(planning.headroom_kw),'kW','规划功率余量']]){
    const div=node('div',undefined,'metric'),strong=node('strong',String(value));strong.append(node('small',' '+unit));div.append(strong,node('span',label));$('metrics').append(div);
  }
  $('capacity-fill').style.width=(planning.it_kw/planning.capacity_kw*100)+'%';
  $('capacity-note').textContent=`机架 IT ${number(planning.it_kw)} / ${planning.capacity_kw} kW · 不含 Spine 与设施负荷`;
  const t=table(['机位','U 占用','服务器','估算 kW'],rows().map(r=>[r.rack,`${r.used}/${r.total}`,r.servers,number(r.kw,2)]));
  t.querySelectorAll('tbody tr').forEach((tr,i)=>{const b=node('button',rows()[i].rack);b.addEventListener('click',()=>onRack(rows()[i].rack));tr.children[0].replaceChildren(b);});
  $('rack-table').replaceChildren(t);$('assumptions').replaceChildren(...planning.assumptions.map(s=>node('li',s)));
}
function drawObservations(){
  const target=$('observations');target.replaceChildren();if(!observation)return;
  const age=ageText(observation.observed_at);
  target.append(node('p',`${source==='import'?'手动导入 / 非实时订阅':'同源服务快照 / 手动刷新'} · ${age.text}`,age.stale?'stale':''));
  target.append(node('p',`LunaNexa：${observation.cluster_state} · MoonGate：${observation.gateway_state}`));
  target.append(node('p',`${observation.machines.length} 个返回节点 · ${observation.model_count} 个路由模型（非 GPU 数量）`));
  if(!observation.machines.length)target.append(node('p','当前快照没有机器记录；不能据此推断实际集群为空。'));
  for(const m of observation.machines){
    const item=node('article',undefined,'observed-machine');item.append(node('h4',m.label));
    const timestamp=ageText(Number(m.observed_at_unix_ms));
    item.append(node('p',`${m.id} · ${m.state} · ${m.architecture}`));
    item.append(node('p',`${m.accelerator_count} 个加速器 · ${m.running_workloads} 个运行工作负载`));
    item.append(node('p',`加速器显存：总计 ${number(m.memory_total_mib/1024)} GiB / 可用 ${number(m.memory_free_mib/1024)} GiB`));
    item.append(node('p',timestamp.text,timestamp.stale?'stale':''));
    item.append(node('p','位置未分配 · 不自动映射 A1/B1。节点别名由当前快照序号生成，不能用作持久资产标识。'));
    target.append(item);
  }
  target.append(node('h3','外部服务 / 不属于本地机柜'));
  for(const r of observation.remote_routes){
    const item=node('div',undefined,'route-row');item.append(node('strong',r.label),node('span',r.state==='observed'?'路由已观测':'未观测'));item.title=r.evidence;target.append(item);
  }
  target.append(node('p','路由被观测 ≠ 正在执行任务。网络动效与这些记录没有实时因果绑定。'));
}
function accept(text,origin){
  const parsed=globalThis.moonDataCenterObservation(text);if(!parsed.ok)throw new Error(parsed.error);
  observation=parsed;source=origin;receivedAt=new Date().toISOString();drawObservations();
  $('source-status').textContent=parsed.mode==='unavailable'?'快照已读取，但服务没有可用观测。':'快照已验证；查看每条记录的时间。';
}
function buildReport(context){
  return {schema:'moontown.datacenter-review.v1',generated_at:new Date().toISOString(),selection:context(),planning,
    observation:observation?{source,received_at:receivedAt,freshness:ageText(observation.observed_at).text,data:observation}:null,
    boundaries:['All geometry is a concept study, not as-built inventory.','Animated flows are illustrative, not captured packets, circuit simulation or CFD.','No physical binding from snapshot aliases to rack / U slots.','No sensor history, PUE, measured temperature or throughput available.']};
}
function download(content,type,name){
  if(exportUrl)URL.revokeObjectURL(exportUrl);exportUrl=URL.createObjectURL(new Blob([content],{type}));
  $('save-report').href=exportUrl;$('save-report').download=name;$('export-text').value=content;
  $('export-title').textContent=name;$('export-status').textContent='';$('export-dialog').showModal();
}
const csvCell=value=>{
  // Prevent spreadsheet formula injection in imported labels and route evidence.
  let s=value==null?'':String(value);if(/^[\s]*[=+@-]/.test(s))s="'"+s;
  return '"'+s.replaceAll('"','""')+'"';
};
export function initReports({onRack,context}){
  $('close-export').addEventListener('click',()=>$('export-dialog').close());
  $('export-dialog').addEventListener('close',()=>{if(exportUrl)URL.revokeObjectURL(exportUrl);exportUrl=null;$('save-report').removeAttribute('href');});
  $('copy-report').addEventListener('click',async()=>{
    try{await navigator.clipboard.writeText($('export-text').value);$('export-status').textContent='已复制报告';}
    catch{$('export-text').focus();$('export-text').select();$('export-status').textContent='请按 ⌘C / Ctrl+C 复制已选内容';}
  });
  drawPlanning(onRack);
  $('load').addEventListener('input',()=>drawPlanning(onRack));
  document.querySelectorAll('[data-panel]').forEach(b=>b.addEventListener('click',()=>{
    activePanel=b.dataset.panel;document.querySelectorAll('[data-panel]').forEach(n=>n.setAttribute('aria-pressed',String(n===b)));
    $('planning-panel').hidden=activePanel!=='planning';$('observed-panel').hidden=activePanel!=='observed';drawObservations();
  }));
  $('refresh').addEventListener('click',async()=>{
    const serial=++requestSerial;const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),8000);
    $('refresh').disabled=true;$('source-status').textContent='读取同源只读投影…';
    try{
      const response=await fetch('/secret-compute-room.json',{credentials:'same-origin',cache:'no-store',signal:controller.signal,redirect:'error'});
      if(!response.ok)throw new Error(`HTTP ${response.status}；静态预览可能没有服务`);
      // Bound reads, even when Content-Length is absent or wrong.
      const reader=response.body.getReader();let bytes=0,text='';const decoder=new TextDecoder();
      for(;;){const {done,value}=await reader.read();if(done)break;bytes+=value.byteLength;if(bytes>262144){await reader.cancel();throw new Error('快照超过 256 KiB');}text+=decoder.decode(value,{stream:true});}
      text+=decoder.decode();if(serial===requestSerial)accept(text,'same-origin');
    }catch(e){if(serial===requestSerial)$('source-status').textContent=`没有新观测：${e.message}。${observation?'保留上次快照及其时间。':'可导入脱敏快照，或与 MoonTown 服务同源部署。'}`;}
    finally{clearTimeout(timeout);$('refresh').disabled=false;}
  });
  $('snapshot').addEventListener('change',async e=>{
    const f=e.target.files[0];if(!f)return;const serial=++requestSerial;
    try{if(f.size>262144)throw new Error('快照超过 256 KiB');const text=await f.text();if(serial===requestSerial)accept(text,'import');}
    catch(error){if(serial===requestSerial)$('source-status').textContent=`导入未接受：${error.message}。${observation?'上次快照保持不变。':''}`;}
    finally{e.target.value='';}
  });
  $('export-json').addEventListener('click',()=>{download(JSON.stringify(buildReport(context),null,2),'application/json','moontown-datacenter-report.json');$('status').textContent='JSON 报告已生成，可检查、下载或复制。';});
  $('export-csv').addEventListener('click',()=>{
    const report=buildReport(context),csv=[['scope','entity','metric','value','unit','provenance','observed_at']];
    csv.push(['metadata','report','generated_at',report.generated_at,'ISO 8601','report generation, not a measurement','']);
    csv.push(['metadata','report','design_selection',JSON.stringify(report.selection),'','concept model selection','']);
    for(const r of rows()){
      csv.push(['planning',r.rack,'occupied_u',r.used,'U','design scenario','']);
      csv.push(['planning',r.rack,'estimated_it_kw',number(r.kw,3),'kW',`180+420×${planning.load_percent}% W/server; +120 W/rack`,'']);
    }
    csv.push(['planning','facility','load_scenario',planning.load_percent,'%','assumed, not measured','']);
    csv.push(['coverage','facility','pue','','','unavailable: missing matched energy measurements','']);
    if(observation){
      csv.push(['observation','snapshot','source',source,'',report.observation.freshness,observation.observed_at]);
      for(const m of observation.machines)for(const key of ['accelerator_count','memory_total_mib','memory_free_mib','running_workloads'])csv.push(['observation',m.id,key,m[key],key.includes('mib')?'MiB':'count',source,m.observed_at_unix_ms]);
      for(const r of observation.remote_routes)csv.push(['observation',r.id,'route_state',r.state,'',source,observation.observed_at]);
    }
    download('\ufeff'+csv.map(row=>row.map(csvCell).join(',')).join('\r\n'),'text/csv;charset=utf-8','moontown-datacenter-report.csv');
    $('status').textContent='CSV 已生成，包含单位、来源与观测时间。';
  });
  $('print').addEventListener('click',()=>{
    const report=buildReport(context),root=$('print-report');root.replaceChildren(node('h1','MoonTown / 数据中心研究报告'),node('p',`生成时间：${report.generated_at}`),node('p',`检查位置：${JSON.stringify(report.selection)}`));
    root.append(node('h2','设计容量 · 非运行遥测'),node('p',`规划负载 ${planning.load_percent}% · 机架 IT ${number(planning.it_kw)} kW · 功率余量 ${number(planning.headroom_kw)} kW`));
    root.append(table(['设计机柜','使用 U / 总 U','服务器','估算 kW'],rows().map(r=>[r.rack,`${r.used}/${r.total}`,r.servers,number(r.kw,2)])));
    root.append(node('h2','假设与缺失测量'),...planning.assumptions.map(s=>node('p',s)));
    root.append(node('h2','观测 / 来源与时间'),node('pre',report.observation?JSON.stringify(report.observation,null,2):'未连接；没有已验证快照。'),...report.boundaries.map(s=>node('p',s)));
    window.print();
  });
  // Refresh freshness text without polling or inventing a time series.
  setInterval(()=>{if(!document.hidden&&activePanel==='observed')drawObservations();},60000);
}
