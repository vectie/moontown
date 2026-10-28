import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { captureSubject, assertCurrentSources, sourceContext, attachSourceContext } from './pack_candidate_sources.js'
import { candidateDialog, installPackBridgePanel, packProductPath } from './pack_bridge_panel.js'
const makeState = () => ({ capabilities: [{pack_id:'one',display_name:'One',intake_operation_ids:['intake']},{pack_id:'two',display_name:'Two',intake_operation_ids:[]}], lifecycles:[{pack_id:'one',stage:'projecting'},{pack_id:'two',stage:'projecting'}], candidates:[], projections:['one','two'].map(id=>({contract_id:'moontown.pack-projection.v1',pack_id:id,product_id:id,version:'1.0.0',generated_at:'2026-10-13',subjects:[{subject_ref:`subjects/${id}.json`,schema_id:'subject.v1',title:`Title ${id}`,summary:`<script>source ${id}</script>`,lifecycle_state:'pending',evidence_refs:[`evidence/${id}.json`],operation_ids:[]}]})) })
const sourcesOf = state => state.projections.map(p=>captureSubject(p,p.subjects[0]))
const candidate = () => ({contract_id:'moontown.pack-candidate-intake.v1',candidate_ref:'town/candidates/fixture',origin_ref:'town/ideas/fixture',target_pack_id:'one',intake_operation_id:'intake',submitted_by:'moontown-operator',submitted_at:'2026-10-13',title:'Idea',rationale:'Why',claim_ceiling:'research-evidence',evidence_refs:['evidence/one.json'],domain_payload:{proposed_topic:'Domain-specific value'}})

test('attributed combination retains exact selected observations, independent connection notes and counterevidence',()=>{
 const state=makeState(), sources=sourcesOf(state), before=JSON.stringify(state)
 assertCurrentSources(sources,state)
 const result=attachSourceContext(candidate(),sources,['These costs suggest an opening','Independent user concern'],'Reject if no buyer confirms the need')
 assert.equal(JSON.stringify(state),before);assert.deepEqual(result.evidence_refs,['evidence/one.json','evidence/two.json']);assert.equal(result.domain_payload.proposed_topic,'Domain-specific value')
 const context=result.domain_payload.moontown_source_context;assert.equal(context.sources.length,2);assert.equal(context.sources[1].summary,'<script>source two</script>');assert.equal(context.genuine_emergence_verified,false);assert.equal(context.accepted_knowledge,false)
 assert.equal(result.claim_ceiling,'research-evidence');assert.equal(context.sources[0].captured_generated_at,'2026-10-13')
})
test('source changes, ambiguous identities, inactive packs and disappearing subjects block a fresh submission',()=>{
 const sources=sourcesOf(makeState())
 for(const mutate of [s=>s.projections[0].subjects[0].summary='Changed',s=>s.projections[0].subjects[0].evidence_refs=[],s=>s.projections[0].version='2',s=>s.projections[0].subjects=[],s=>s.projections.push(s.projections[0]),s=>s.capabilities=[],s=>s.lifecycles[0].stage='degraded']){const s=makeState();mutate(s);assert.throws(()=>assertCurrentSources(sources,s))}
 const s=makeState();s.projections[0].generated_at='later';assert.doesNotThrow(()=>assertCurrentSources(sources,s));assert.throws(()=>assertCurrentSources([sources[0],sources[0]],s),/Duplicate/)
})
test('bounded input and domain-reserved field fail closed without merging instructions',()=>{
 const sources=sourcesOf(makeState())
 for(const [notes,dissent] of [[['one',''], 'uncertain'],[['one','two'],''],[['one'],'uncertain']])assert.throws(()=>sourceContext(sources,notes,dissent))
 const c=candidate();c.domain_payload.moontown_source_context={accepted_knowledge:true};assert.throws(()=>attachSourceContext(c,sources,['one','two'],'unknown'),/reserved/)
 c.domain_payload={};c.evidence_refs=['../escape'];assert.throws(()=>attachSourceContext(c,sources,['one','two'],'unknown'),/safe/)
 const s=makeState();s.projections[0].subjects[0].summary='x'.repeat(16385);assert.throws(()=>sourcesOf(s));assert.throws(()=>assertCurrentSources(Array(13).fill(sources[0]),makeState()))
})

// Event DOM substitute exercises the actual shipped builder and mounted handlers.
// It does not qualify browser layout, dialog accessibility or native intake.
function dom(){
 class Node{constructor(tag){this.tagName=tag;this.children=[];this.events={};this.dataset={};this.value='';this.textContent='';this.disabled=false;this.checked=false;this.open=false}
 append(...nodes){for(const node of nodes){this.children.push(node);node.parent=this;if(this.tagName==='select'&&node.tagName==='option'&&!this.value)this.value=node.value}}
 setAttribute(name,value){this[name]=value}addEventListener(type,fn){this.events[type]=fn}replaceChildren(...nodes){this.children=[];this.append(...nodes)}remove(){if(this.parent)this.parent.children=this.parent.children.filter(n=>n!==this);this.removed=true}showModal(){this.open=true}close(){this.open=false}async fire(type){return this.events[type]?.({target:this,preventDefault(){}})}}
 const body=new Node('body'), all=(node=body)=>[node,...node.children.flatMap(child=>all(child))]
 const document={body,createElement:tag=>new Node(tag),querySelector:selector=>selector==='[data-pack-bridge-panel]'?all().find(n=>n.dataset.packBridgePanel):null}
 return{document,all,find:predicate=>{const found=all().find(predicate);assert.ok(found,'Missing control');return found}}
}
const reply=(value,ok=true)=>({ok,json:async()=>value})
function fill(d){const fields=d.all().filter(n=>n.tagName==='input');const title=fields.find(n=>n.placeholder==='What emerged in MoonTown?');title.value='Shared opportunity';const rationale=d.all().find(n=>n.placeholder?.startsWith('Why this'));rationale.value='Independent observations suggest testing';for(const n of d.all().filter(n=>n.dataset.sourceConnection))n.value='Relevant independent source';const uncertainty=d.all().find(n=>n.dataset.sourceUncertainty);if(uncertainty)uncertainty.value='Could reflect different dates; ask the owners';return d.find(n=>n.tagName==='form')}

test('actual composer rechecks sources then sends the native v1 envelope with editable pack vocabulary and literal source text',async()=>{
 const d=dom();globalThis.document=d.document;const state=makeState(), calls=[];let refreshed=0
 try{candidateDialog(state,async()=>{refreshed++},sourcesOf(state),{fetcher:async(url,opts)=>{calls.push({url,opts});return reply(url.endsWith('candidates')?{receipt:{status:'review-pending'}}:{...state,projections:{projections:state.projections}})}})
 const form=fill(d);await form.fire('submit');assert.equal(calls.length,2);assert.equal(calls[0].url,'/api/pack-bridge');const sent=JSON.parse(calls[1].opts.body);assert.equal(sent.contract_id,'moontown.pack-candidate-intake.v1');assert.equal(sent.domain_payload.moontown_source_context.sources.length,2);assert.equal(refreshed,1);assert.ok(d.all().some(n=>n.textContent==='<script>source one</script>'));assert.ok(d.find(n=>n.type==='submit').disabled);await form.fire('submit');assert.equal(calls.length,2)
 }finally{delete globalThis.document}
})
test('changed observation prevents POST, keeps notes editable and reports reselection',async()=>{
 const d=dom();globalThis.document=d.document;const state=makeState(), changed=makeState();changed.projections[0].subjects[0].summary='new';let posts=0
 try{candidateDialog(state,async()=>{},sourcesOf(state),{fetcher:async(url)=>{if(url.endsWith('candidates'))posts++;return reply({...changed,projections:{projections:changed.projections}})}});await fill(d).fire('submit');assert.equal(posts,0);assert.ok(d.all().some(n=>n.textContent.includes('source content changed')));assert.ok(d.all().filter(n=>n.dataset.sourceConnection).every(n=>!n.disabled))}finally{delete globalThis.document}
})
test('uncertain POST retry preserves exact candidate identity and bytes, freezes form and avoids a second preflight',async()=>{
 const d=dom();globalThis.document=d.document;const state=makeState(), bodies=[];let gets=0
 try{candidateDialog(state,async()=>{},sourcesOf(state),{fetcher:async(url,opts)=>{if(!url.endsWith('candidates')){gets++;return reply({...state,projections:{projections:state.projections}})}bodies.push(opts.body);if(bodies.length===1)throw Error('Lost response');return reply({receipt:{status:'review-pending'}})}})
 const form=fill(d);await form.fire('submit');assert.equal(d.find(n=>n.type==='submit').textContent,'核对并重试');assert.ok(d.all().filter(n=>n.dataset.sourceConnection).every(n=>n.disabled));await form.fire('submit');assert.equal(bodies.length,2);assert.equal(bodies[0],bodies[1]);assert.equal(gets,1)
 }finally{delete globalThis.document}
})
test('double submission and dismissal while request is pending cannot send another candidate',async()=>{
 const d=dom();globalThis.document=d.document;let release;const promise=new Promise(r=>release=r);let posts=0;const state=makeState()
 try{const dialog=candidateDialog(state,async()=>{},sourcesOf(state),{fetcher:async(url)=>{if(!url.endsWith('candidates'))return reply({...state,projections:{projections:state.projections}});posts++;await promise;return reply({receipt:{status:'review-pending'}})}});dialog.showModal();const form=fill(d);const active=form.fire('submit');await new Promise(r=>setTimeout(r,0));await form.fire('submit');await d.find(n=>n.textContent==='关闭').fire('click');assert.equal(dialog.open,true);assert.equal(posts,1);release();await active}catch(error){release();throw error}finally{delete globalThis.document}
})
test('mounted Pack layers selects actual subjects, preserves selection across filters, opens linked proposal',async()=>{
 const d=dom();globalThis.document=d.document;const old=globalThis.fetch;const state=makeState();globalThis.fetch=async()=>reply({...state,projections:{projections:state.projections}})
 try{installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click');const choices=d.all().filter(n=>n.dataset.sourceSubject);for(const c of choices){c.checked=true;await c.fire('change')};const filter=d.all().find(n=>n.type==='checkbox'&&!n.dataset.sourceSubject);filter.checked=false;await filter.fire('change');const open=d.find(n=>n.textContent==='整理问题 · 2 份资料');await open.fire('click');assert.equal(d.all().filter(n=>n.dataset.sourceConnection).length,2)}finally{globalThis.fetch=old;delete globalThis.document}
})
test('production asset declaration and native intake contract preserve source context without widening schema',async()=>{
 const build=await readFile(new URL('./scripts/assemble-production-build.mjs',import.meta.url),'utf8');assert.match(build,/'pack_candidate_sources.js'/)
 const types=await readFile(new URL('../../pack_town_bridge/types.mbt',import.meta.url),'utf8');const validation=await readFile(new URL('../../pack_town_bridge/validation.mbt',import.meta.url),'utf8');const store=await readFile(new URL('../../pack_town_bridge_runtime/store.mbt',import.meta.url),'utf8');
 assert.match(types,/domain_payload : Json/);assert.match(validation,/candidate.domain_payload is Object/);assert.match(store,/candidate_envelopes.push\(candidate\)/);assert.match(store,/candidate identity is already bound to another payload/)
})

test('mounted uncertain candidate reopens the same dialog and cannot become an accidental duplicate',async()=>{
 const d=dom();globalThis.document=d.document;const old=globalThis.fetch;const state=makeState();let posts=0
 globalThis.fetch=async(url)=>{if(url.endsWith('candidates')){posts++;throw Error('Lost connection')};return reply({...state,projections:{projections:state.projections}})}
 try{installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click');const choice=d.find(n=>n.dataset.sourceSubject);choice.checked=true;await choice.fire('change');const launch=d.find(n=>n.textContent==='整理问题 · 1 份资料');await launch.fire('click');const dialog=d.find(n=>n.tagName==='dialog');await fill(d).fire('submit');assert.equal(posts,1);assert.equal(dialog.dataset.candidatePending,'true');dialog.close();await launch.fire('click');assert.equal(d.all().filter(n=>n.tagName==='dialog').length,1);assert.equal(dialog.open,true);assert.equal(d.find(n=>n.type==='submit').textContent,'核对并重试')}
 finally{globalThis.fetch=old;delete globalThis.document}
})
test('unavailable freshness fetch and removed destination retain unsent form without POST',async()=>{
 for(const unavailable of [true,false]){const d=dom();globalThis.document=d.document;const state=makeState(), changed=makeState();changed.capabilities[0].intake_operation_ids=[];let posts=0
 try{candidateDialog(state,async()=>{},sourcesOf(state),{fetcher:async(url)=>{if(url.endsWith('candidates'))posts++;return unavailable?reply({},false):reply({...changed,projections:{projections:changed.projections}})}});await fill(d).fire('submit');assert.equal(posts,0);assert.equal(d.find(n=>n.type==='submit').textContent,'提交审阅');assert.ok(d.all().filter(n=>n.dataset.sourceConnection).every(n=>!n.disabled))}finally{delete globalThis.document}}
})
test('legacy manual candidate composer remains compatible without selected projection sources',async()=>{
 const d=dom();globalThis.document=d.document;const calls=[]
 try{candidateDialog(makeState(),async()=>{},[],{fetcher:async(url,opts)=>{calls.push({url,opts});return reply({receipt:{status:'review-pending'}})}});await fill(d).fire('submit');assert.equal(calls.length,1);assert.equal(calls[0].url,'/api/pack-bridge/candidates');assert.deepEqual(JSON.parse(calls[0].opts.body).domain_payload,{})}finally{delete globalThis.document}
})

test('whole candidate serializer enforces the exact native UTF-8 byte boundary including envelope overhead',async()=>{
 const { serializeCandidate, CANDIDATE_BODY_LIMIT } = await import('./pack_candidate_sources.js')
 assert.equal(CANDIDATE_BODY_LIMIT,131072)
 const value=candidate();value.domain_payload={padding:''}
 const emptyBytes=Buffer.byteLength(JSON.stringify(value),'utf8'), room=CANDIDATE_BODY_LIMIT-emptyBytes
 for(const suffix of ['', 'é', '雪', '🌓']){
   const suffixBytes=Buffer.byteLength(suffix,'utf8')
   value.domain_payload.padding='x'.repeat(room-suffixBytes)+suffix
   assert.equal(Buffer.byteLength(serializeCandidate(value),'utf8'),131072)
   value.domain_payload.padding+='a';assert.throws(()=>serializeCandidate(value),/native 128 KiB/)
 }
 // A context can fit its own limit yet exceed the native guard after wrapping.
 const envelope=candidate();envelope.domain_payload={moontown_source_context:{padding:''}}
 const contextBytes=Buffer.byteLength(JSON.stringify(envelope.domain_payload.moontown_source_context))
 envelope.domain_payload.moontown_source_context.padding='x'.repeat(131072-contextBytes)
 assert.equal(Buffer.byteLength(JSON.stringify(envelope.domain_payload.moontown_source_context)),131072)
 assert.throws(()=>serializeCandidate(envelope),/including source context and JSON overhead/)
 const guard=await readFile(new URL('../../cmd/desktop_server/main.mbt',import.meta.url),'utf8')
 assert.match(guard,/size < 0 \|\| size > 128 \* 1024/)
 assert.match(guard,/path == @town_contract.desktop_pack_candidate_path\(\)[\s\S]*?reject_unsafe_operator_write\(request, conn\)/)
})
test('oversized ASCII or multibyte envelope is rejected locally with editable form and zero fetches',async()=>{
 for(const padding of ['x'.repeat(131072),'雪'.repeat(44000),'🌓'.repeat(33000)]){
 const d=dom();globalThis.document=d.document;let calls=0
 try{candidateDialog(makeState(),async()=>{},[],{fetcher:async()=>{calls++;throw Error('Must reject locally')}});const form=fill(d);d.find(n=>n.spellcheck===false).value=JSON.stringify({padding});await form.fire('submit');assert.equal(calls,0);assert.ok(d.all().some(n=>n.textContent.includes('native 128 KiB request limit')));assert.equal(d.find(n=>n.type==='submit').disabled,false);assert.equal(d.find(n=>n.spellcheck===false).disabled,false)}finally{delete globalThis.document}
 }
})
test('definite native size rejection unlocks correction instead of trapping identical retry',async()=>{
 const d=dom();globalThis.document=d.document;let calls=0
 try{const dialog=candidateDialog(makeState(),async()=>{},[],{fetcher:async()=>{calls++;return{status:413,ok:false,json:async()=>({ok:false,error:'request body too large'})}}});await fill(d).fire('submit');assert.equal(calls,1);assert.equal(dialog.dataset.candidatePending,'false');assert.equal(d.find(n=>n.type==='submit').textContent,'提交审阅');assert.equal(d.find(n=>n.spellcheck===false).disabled,false);assert.ok(d.all().some(n=>n.textContent.includes('before intake')))}finally{delete globalThis.document}
})

test('public town shows one actionable account boundary without probing private Pack APIs or mounting forms', async () => {
 const d=dom(), oldFetch=globalThis.fetch;globalThis.document=d.document;globalThis.__MOONTOWN_PUBLIC_PLATFORM=true;let calls=0
 globalThis.fetch=async()=>{calls++;throw Error('Public town must not probe Pack APIs')}
 try{
  installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click')
  assert.equal(calls,0);assert.equal(d.find(n=>n.dataset.packBridgeWorkspace).hidden,true)
  assert.equal(d.find(n=>n.dataset.packAccountLink).href,'/user/')
  assert.ok(d.all().some(n=>n.textContent.includes('登录账户不代表工作区已连接')))
  assert.equal(d.all().filter(n=>n.dataset.vocabularyExplorer||n.dataset.observationChanges||n.dataset.materialDiscovery||n.dataset.crossPackQuestion).length,0)
  assert.equal(d.all().filter(n=>n.tagName==='textarea').length,0)
 }finally{delete globalThis.__MOONTOWN_PUBLIC_PLATFORM;delete globalThis.document;globalThis.fetch=oldFetch}
})

test('hosted scope failure never probes APIs and offers reload rather than a false empty research workspace', async () => {
 const d=dom(), oldFetch=globalThis.fetch;globalThis.document=d.document;globalThis.__MOONTOWN_BASE_PATH='/moontown/workspace';globalThis.__MOONTOWN_SCOPE_READY=false;let calls=0
 globalThis.fetch=async()=>{calls++;throw Error('Scope is not ready')}
 try{
  installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click')
  assert.equal(calls,0);assert.equal(d.find(n=>n.dataset.packBridgeRetry).textContent,'重新载入')
  assert.equal(d.all().filter(n=>n.tagName==='textarea').length,0)
 }finally{delete globalThis.__MOONTOWN_BASE_PATH;delete globalThis.__MOONTOWN_SCOPE_READY;delete globalThis.document;globalThis.fetch=oldFetch}
})

test('401, 403, 404, malformed and empty capabilities stay concise and never construct discovery forms', async () => {
 const oldFetch=globalThis.fetch
 try{for(const result of [{status:401,ok:false},{status:403,ok:false},{status:404,ok:false},reply({}),reply({capabilities:[],lifecycles:[],projections:{projections:[]}})]){
  const d=dom();globalThis.document=d.document;let calls=0;globalThis.fetch=async()=>{calls++;return result}
  installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click')
  assert.equal(calls,1);assert.equal(d.find(n=>n.dataset.packBridgeWorkspace).hidden,true)
  assert.equal(d.find(n=>n.dataset.packBridgeEmpty).hidden,false)
  assert.equal(d.all().filter(n=>n.tagName==='textarea').length,0)
  assert.ok(d.find(n=>n.dataset.packBridgeRetry));assert.equal(d.all().filter(n=>n.dataset.vocabularyExplorer).length,0)
 }}finally{delete globalThis.document;globalThis.fetch=oldFetch}
})

test('connected workspace exposes exactly one discovery mode while keeping source selections and drafts mounted', async () => {
 const d=dom(), oldFetch=globalThis.fetch;globalThis.document=d.document;const state=makeState()
 globalThis.fetch=async()=>reply({...state,projections:{projections:state.projections}})
 try{
  installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click')
  const panes=d.all().filter(n=>n.dataset.packDiscoveryPane), mode=d.find(n=>n.dataset.packDiscoveryMode)
  assert.equal(panes.length,5);assert.deepEqual(panes.filter(n=>!n.hidden).map(n=>n.dataset.packDiscoveryPane),['browse'])
  const source=d.find(n=>n.dataset.sourceSubject);source.checked=true;await source.fire('change')
  for(const key of ['vocabulary','changes','shared','question','browse']){
   mode.value=key;await mode.fire('change');assert.deepEqual(panes.filter(n=>!n.hidden).map(n=>n.dataset.packDiscoveryPane),[key])
  }
  assert.equal(source.checked,true);assert.ok(d.find(n=>n.textContent==='整理问题 · 1 份资料'))
  assert.ok(d.all().some(n=>n.tagName==='details'&&!n.open&&n.children.some(c=>c.textContent==='高级 · 检索规则与文件')))
 }finally{delete globalThis.document;globalThis.fetch=oldFetch}
})

test('outage hides the whole workspace and retry restores the selected mode without automatic POST', async () => {
 const d=dom(), oldFetch=globalThis.fetch;globalThis.document=d.document;const state=makeState();let fail=false,posts=0
 globalThis.fetch=async(url)=>{if(url.endsWith('candidates'))posts++;if(fail)return{status:404,ok:false};return reply({...state,projections:{projections:state.projections}})}
 try{
  installPackBridgePanel();const launch=d.find(n=>n.dataset.packBridgePanel==='launch');await launch.fire('click')
  const mode=d.find(n=>n.dataset.packDiscoveryMode);mode.value='changes';await mode.fire('change')
  fail=true;await launch.fire('click');assert.equal(d.find(n=>n.dataset.packBridgeWorkspace).hidden,true)
  fail=false;await d.find(n=>n.dataset.packBridgeRetry).fire('click')
  assert.equal(d.find(n=>n.dataset.packBridgeWorkspace).hidden,false);assert.equal(mode.value,'changes');assert.equal(posts,0)
 }finally{delete globalThis.document;globalThis.fetch=oldFetch}
})

test('candidate parameters are advanced by default, invalid JSON reveals correction, and public mode never posts', async () => {
 const d=dom();globalThis.document=d.document;let calls=0
 try{
  candidateDialog(makeState(),async()=>{},[],{fetcher:async()=>{calls++;throw Error('Must not send')}})
  const form=fill(d),payload=d.find(n=>n.spellcheck===false),details=payload.parent.parent
  assert.equal(details.tagName,'details');assert.equal(Boolean(details.open),false)
  payload.value='{bad';await form.fire('submit');assert.equal(details.open,true);assert.equal(calls,0)
  payload.value='{}';globalThis.__MOONTOWN_PUBLIC_PLATFORM=true;await form.fire('submit');assert.equal(calls,0)
  assert.ok(d.all().some(n=>n.textContent.includes('没有发送候选')))
 }finally{delete globalThis.__MOONTOWN_PUBLIC_PLATFORM;delete globalThis.document}
})

test('Pack requests resolve standalone, authenticated workspace and embedded product mounts without doubling the base', async () => {
 const oldFetch=globalThis.fetch,oldLocation=globalThis.location
 try{
  for(const [base,pathname,prefix] of [['','/index.html',''],['/moontown','/moontown/index.html','/moontown'],['/moontown/workspace','/moontown/workspace/index.html','/moontown/workspace'],['','/pack-apps/moontown/index.html','/pack-apps/moontown']]){
   globalThis.__MOONTOWN_BASE_PATH=base;globalThis.location={pathname};globalThis.__MOONTOWN_SCOPE_READY=true
   assert.equal(packProductPath('/api/pack-bridge'),`${prefix}/api/pack-bridge`)
   const d=dom(),state=makeState(),calls=[];globalThis.document=d.document
   globalThis.fetch=async(url,opts)=>{calls.push({url,opts});return reply({...state,projections:{projections:state.projections}})}
   installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click')
   assert.equal(calls[0].url,`${prefix}/api/pack-bridge`);assert.equal(calls[0].opts.credentials,'same-origin')
   candidateDialog(state,async()=>{},sourcesOf(state),{fetcher:async(url,opts)=>{calls.push({url,opts});return reply(url.endsWith('candidates')?{receipt:{status:'review-pending'}}:{...state,projections:{projections:state.projections}})}})
   await fill(d).fire('submit')
   assert.equal(calls[1].url,`${prefix}/api/pack-bridge`);assert.equal(calls[2].url,`${prefix}/api/pack-bridge/candidates`)
   assert.equal(calls[2].opts.credentials,'same-origin')
  }
 }finally{delete globalThis.document;delete globalThis.__MOONTOWN_BASE_PATH;delete globalThis.__MOONTOWN_SCOPE_READY;globalThis.location=oldLocation;globalThis.fetch=oldFetch}
})

test('read-only Pack capabilities keep material browsing but cannot open a destinationless submission form', async () => {
 const d=dom(),oldFetch=globalThis.fetch,state=makeState();globalThis.document=d.document
 for(const capability of state.capabilities)capability.intake_operation_ids=[]
 globalThis.fetch=async()=>reply({...state,projections:{projections:state.projections}})
 try{
  installPackBridgePanel();await d.find(n=>n.dataset.packBridgePanel==='launch').fire('click')
  assert.equal(d.all().filter(n=>n.dataset.sourceSubject).length,2)
  const launch=d.find(n=>n.textContent==='整理问题');assert.equal(launch.disabled,true)
  await launch.fire('click');assert.equal(d.all().filter(n=>n.tagName==='dialog').length,0)
 }finally{delete globalThis.document;globalThis.fetch=oldFetch}
})

test('Pack disclosures retain light-surface contrast and hidden modes cannot be overridden by existing grid styles', async () => {
 const css=await readFile(new URL('./styles/pack-bridge-panel.css',import.meta.url),'utf8')
 assert.match(css,/\.pack-bridge-panel \[hidden\],[\s\S]*?display: none !important/)
 assert.match(css,/\.pack-bridge-panel \.town-advanced,[\s\S]*?var\(--town-ui-ink, #334155\)/)
})
