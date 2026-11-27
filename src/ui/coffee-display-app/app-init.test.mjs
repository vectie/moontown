import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const source=await readFile(new URL('./app-init.js',import.meta.url),'utf8');
const flush=async()=>{await Promise.resolve();await Promise.resolve()};
function setup({origin='https://suanli.kechuangfuwu.com:8443',frame=false,loading=false}={}){
 const calls=[],listeners={},timers=[];let reloads=0,fetches=0,next={ok:true,version:'one'};
 const makePage=version=>({title:'第四期',body:{dataset:{cover:'winter'}},images:[{complete:true,naturalWidth:1672,getBoundingClientRect:()=>({width:1280,height:720,right:1280,bottom:720,left:0,top:0})}],stage:{dataset:{paused:'false'}},dialog:false,querySelectorAll:()=>[{getAttribute:name=>name==='src'?version+'.js':null}],querySelector(selector){return selector==='.copy h1'?{textContent:'把冬天泡开'}:selector==='.carousel-cycle'?{querySelectorAll:()=>Array(18)}:selector==='#hero-art'?{}:selector==='.display'?this.stage:selector==='dialog[open]'&&this.dialog?{}:null}});
 const document=Object.assign(makePage('one'),{readyState:loading?'loading':'complete',addEventListener:(name,fn)=>{listeners[name]=fn}});
 const window={lepusa:{invoke:async(route,payload)=>{calls.push([route,payload])}}};window.top=frame?{}:window;
 const location={origin,pathname:'/disp/',reload:()=>reloads++};
 vm.runInNewContext(source,{window,document,location,innerWidth:1280,innerHeight:720,console,AbortController,setTimeout,clearTimeout,setInterval:(fn,ms)=>timers.push([fn,ms]),fetch:async()=>{fetches++;return{ok:next.ok,text:async()=>next.version}},DOMParser:class{parseFromString(text){return makePage(text)}}});
 return {calls,listeners,timers,document,setResponse:r=>{next=r},reloads:()=>reloads,fetches:()=>fetches};
}
test('native startup enters fullscreen, reflects the loaded topic and F11 toggles it',async()=>{
 const app=setup();await flush();const full=()=>app.calls.filter(([route])=>route==='window.setFullscreen').map(([,p])=>p.fullscreen);
 assert.deepEqual(full(),[true]);assert.ok(app.calls.some(([r,p])=>r==='window.setTitle'&&p.title==='未来社区 · 把冬天泡开'));
 let prevented=0;const event={key:'F11',preventDefault:()=>prevented++,stopPropagation:()=>{}};
 app.listeners.keydown(event);await flush();app.listeners.keydown(event);await flush();assert.deepEqual(full(),[true,false,true]);assert.equal(prevented,2);
 assert.equal(app.timers[0][1],300000);
});
test('untrusted origins and child frames never receive native window operations',async()=>{
 for(const options of [{origin:'https://other.test'}, {frame:true}]){const app=setup(options);await flush();assert.equal(app.calls.length,0);assert.equal(app.timers.length,0)}
 const app=setup({loading:true});assert.equal(app.calls.length,0);app.listeners.DOMContentLoaded();await flush();assert.equal(app.calls[0][1].fullscreen,true);
});
test('poster updates retain the current release on errors and defer during pause or enlargement',async()=>{
 const app=setup();await flush();const poll=app.timers[0][0];await poll();assert.equal(app.reloads(),0);
 app.setResponse({ok:false,version:'two'});await poll();assert.equal(app.reloads(),0);
 app.setResponse({ok:true,version:'two'});app.document.stage.dataset.paused='true';const before=app.fetches();await poll();assert.equal(app.fetches(),before);
 app.document.stage.dataset.paused='false';app.document.dialog=true;await poll();assert.equal(app.reloads(),0);
 app.document.dialog=false;await poll();assert.equal(app.reloads(),1);
});
