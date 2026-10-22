// Opt-in, local diagnostics. No telemetry, account data or network reporting.
// The same probe is used for baseline and optimized builds.
if (new URLSearchParams(location.search).get('perf') === '1') {
  const root = document.documentElement;
  const round = n => Math.round(n * 100) / 100;
  const percentile = (values, p) => [...values].sort((a,b)=>a-b)[Math.floor((values.length-1)*p)] || 0;
  const result = {schema: 'moontown.ui-performance.v1', viewport: [innerWidth,innerHeight,devicePixelRatio], phases: []};
  const tasks = [];
  try { new PerformanceObserver(list => tasks.push(...list.getEntries().map(e=>({start:e.startTime,duration:e.duration})))).observe({type:'longtask',buffered:true}); } catch {}
  globalThis.__moontownGoldenValleyRenderBenchmark ||= {};
  let phase, previousFrame, lastCount=0, readyAt, finished=false;
  const publish = () => { root.dataset.performanceReport = JSON.stringify(result); };
  function begin(name) {
    const m=globalThis.__moontownGoldenValleyRenderBenchmark;
    phase={name,start:performance.now(),gaps:[],paints:[],count:m.invokedFullPaints||0,total:m.invokedFullPaintTotalMs||0};
    previousFrame=undefined;lastCount=m.invokedFullPaints||0;
    result.status=name;publish();
  }
  function end() {
    const m=globalThis.__moontownGoldenValleyRenderBenchmark, duration=performance.now()-phase.start;
    const paints=(m.invokedFullPaints||0)-phase.count;
    result.phases.push({name:phase.name,durationMs:round(duration),paints,paintFps:round(paints*1000/duration),paintMeanMs:round(((m.invokedFullPaintTotalMs||0)-phase.total)/Math.max(1,paints)),paintP95Ms:round(percentile(phase.paints,.95)),rafP95Ms:round(percentile(phase.gaps,.95)),gapsOver50ms:phase.gaps.filter(v=>v>50).length,longTasks:tasks.filter(t=>t.start>=phase.start).length});
    phase=null;result.status='complete';publish();
  }
  const button = document.createElement('button');
  button.textContent='性能复测 · 10 秒平移';
  button.style.cssText='position:fixed;bottom:12px;left:12px;z-index:9999;padding:10px;background:#213a32;color:white;border:1px solid #d6d6bc;border-radius:8px';
  button.onclick=()=>{if(!phase&&readyAt){begin('pan');button.disabled=true;}};
  addEventListener('DOMContentLoaded',()=>document.body.append(button),{once:true});
  let cameraStart;
  function tick(now) {
    const canvas=document.getElementById('energy-valley-canvas'), m=globalThis.__moontownGoldenValleyRenderBenchmark;
    if(canvas&&!result.canvasMs) result.canvasMs=round(now);
    if(!readyAt&&root.dataset.landmarkModels==='ready'&&root.dataset.wenyuGentleGroundTrial==='ready') {
      readyAt=now;result.readyMs=round(now);
      result.resources=performance.getEntriesByType('resource').map(e=>({path:new URL(e.name).pathname,bytes:e.encodedBodySize,transfer:e.transferSize,ms:round(e.duration)}));
      result.startupLongTasks=tasks.length;result.startupBlockingMs=round(tasks.reduce((s,t)=>s+Math.max(0,t.duration-50),0));publish();
    }
    if(readyAt&&!finished&&now-readyAt>1000){finished=true;begin('idle');button.disabled=true;}
    if(phase) {
      if(previousFrame)phase.gaps.push(now-previousFrame);
      if(m.invokedFullPaints!==lastCount){phase.paints.push(m.invokedFullPaintLastMs||0);lastCount=m.invokedFullPaints;}
      if(phase.name==='pan'){
        const c=globalThis.__moontownGoldenValleyCamera;
        cameraStart ||= {x:c.x,y:c.y};
        c.x=cameraStart.x+Math.sin((now-phase.start)/1000)*180;
        globalThis.__moontownGoldenValleyRender?.('performance-pan');
      }
      previousFrame=now;
      if(now-phase.start>=10000){
        if(cameraStart){const c=globalThis.__moontownGoldenValleyCamera;c.x=cameraStart.x;c.y=cameraStart.y;cameraStart=null;}
        end();button.disabled=false;
      }
    }
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}
