import test from 'node:test'
import assert from 'node:assert/strict'
import {labelPng,csvCell,creativeEndpoint,votingRows,creationPhase,generationCredits,generationStatus,originalImage} from './coffee-contest.js'

test('original downloads recover once from a broken body without retrying authorization failures',async()=>{
  const image = new Blob([new Uint8Array(64)],{type:'image/png'});
  let calls=0,retries=0;
  const result=await originalImage('/original',async(_,options)=>{
    calls++;
    assert.equal(options.credentials,'same-origin');
    assert.equal(options.cache,'no-store');
    return {ok:true,blob:async()=>{if(calls===1)throw new TypeError('connection terminated');return image}};
  },()=>retries++);
  assert.equal(result,image);
  assert.equal(calls,2);
  assert.equal(retries,1);
  calls=0;
  await assert.rejects(originalImage('/private',async()=>{calls++;return {ok:false,status:403}}));
  assert.equal(calls,1);
  calls=0;
  const cancelled=new AbortController();
  cancelled.abort();
  await assert.rejects(originalImage('/original',async()=>{calls++;return image},()=>{},cancelled.signal));
  assert.equal(calls,0);
});

test('original retries are bounded and reject incomplete image bodies',async()=>{
  let calls=0;
  await assert.rejects(originalImage('/original',async()=>{calls++;throw new TypeError('offline')}));
  assert.equal(calls,2);
  calls=0;
  await assert.rejects(originalImage('/original',async()=>{calls++;return {ok:true,blob:async()=>new Blob([])}}));
  assert.equal(calls,1);
});

test('queue copy uses authoritative position and server clock without promising an exact finish',()=>{
  const job={state:'queued',queue:{ahead:19,status:'queued',estimated_start_ms:'181000',estimated_ready_ms:'190000'}}
  assert.equal(generationStatus(job,1000),'前面还有 19 人 · 预计约 3 分钟开始')
  assert.equal(generationStatus({...job,state:'running'},181000),'正在生成 · 预计还需约 10 秒')
  assert.equal(generationStatus({...job,state:'running'},190000),'正在收尾，请稍等。')
  assert.equal(generationStatus({...job,queue:{...job.queue,ahead:0}},181000),'马上轮到你 · 预计约 10 秒完成')
})

test('uncertain or paused queues never show a stale countdown',()=>{
  const job={state:'queued',queue:{ahead:19,status:'blocked',reason:'reconcile',estimated_start_ms:'181000'}}
  assert.equal(generationStatus(job,1000),'队列暂时暂停，等待主办核对。')
  assert.equal(generationStatus({...job,queue:{...job.queue,reason:'closed'}},1000),'本期已截止，排队任务正在结算。')
  assert.match(generationStatus({...job,queue:{...job.queue,status:'delayed'}},1000),/前面还有 19 人/)
  assert.doesNotMatch(generationStatus(job,1000,{generation_allowed:false}),/预计|分钟|秒/)
  assert.match(generationStatus({state:'running'},1000),/正在把想象画出来/)
})

test('generation allowance copy respects the shared event budget even with personal credits left',()=>{
  const value={remaining:2,event_remaining:1,event:{participant_quota:3}}
  assert.match(generationCredits(value,true),/还可生成 1 张/)
  assert.match(generationCredits(value,false),/最多可生成 1 张/)
  assert.equal(generationCredits({...value,event_remaining:0},true),'本期生成名额已用完 · 已生成图片仍可投稿')
  assert.equal(generationCredits({...value,event_remaining:0,generations:[{state:'queued'}]},true),'')
  assert.match(generationCredits({...value,event_remaining:0,generations:[{state:'completed'}]},true),/已生成图片仍可投稿/)
  assert.match(generationCredits({...value,event_remaining:20},true),/还可生成 2 张/)
})

test('scheduled activities distinguish upcoming, open and closed at exact boundaries',()=>{
  const event={opens_ms:'1000',deadline_ms:'2000'}
  assert.equal(creationPhase(event,999),'waiting')
  assert.equal(creationPhase(event,1000),'open')
  assert.equal(creationPhase(event,1999),'open')
  assert.equal(creationPhase(event,2000),'closed')
})

test('activity endpoint never silently falls back to the legacy contest for a malformed activity',()=>{
  assert.equal(creativeEndpoint('https://town.example/moontown/coffee-contest.html').pathname,'/moontown/api/creative/')
  assert.equal(creativeEndpoint('https://town.example/coffee-qa/coffee-contest.html?activity=activity-abc').pathname,'/coffee-qa/api/activities/activity-abc/')
  for(const id of ['', '../private','https://other.example','a/b','a%2fb'])assert.throws(()=>creativeEndpoint(`https://town.example/moontown/coffee-contest.html?activity=${encodeURIComponent(id)}`))
})

test('ranking uses server counts and rank ties without revealing withdrawn work metadata',()=>{
  const value={gallery:[{id:'a',title:'小城',display_name:'A'},{id:'b',title:'云朵',display_name:'B'}],voting:{settled:true,counts:[{entry_id:'b',votes:2,rank:1,eligible:true},{entry_id:'a',votes:2,rank:1,eligible:true},{entry_id:'removed',votes:4,rank:0,eligible:false}]}}
  assert.deepEqual(votingRows(value).map(row=>[row.entry_id,row.votes,row.rank]),[['a',2,1],['b',2,1]])
  assert.equal(votingRows(value).some(row=>row.entry_id==='removed'),false)
})

test('download label is a valid PNG text chunk without changing pixel chunks',()=>{
  const original=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aH2QAAAAASUVORK5CYII=','base64')
  const result=Buffer.from(labelPng(original,'generation-fixture'))
  assert.deepEqual(result.subarray(0,original.length-12),original.subarray(0,-12))
  assert.deepEqual(result.subarray(-12),original.subarray(-12))
  const offset=original.length-12, length=result.readUInt32BE(offset)
  assert.equal(result.subarray(offset+4,offset+8).toString(),'tEXt')
  const metadata=result.subarray(offset+8,offset+8+length).toString().split('\0')
  assert.equal(metadata[0],'AIGC')
  assert.equal(JSON.parse(metadata[1]).Label,'1')
  assert.equal(JSON.parse(metadata[1]).ProduceID,'generation-fixture')
  let crc=0xffffffff
  for(const byte of result.subarray(offset+4,offset+8+length)){
    crc^=byte
    for(let bit=0;bit<8;bit++)crc=(crc>>>1)^((crc&1)?0xedb88320:0)
  }
  assert.equal(result.readUInt32BE(offset+8+length),(crc^0xffffffff)>>>0)
  assert.throws(()=>labelPng(new Uint8Array([1,2,3])))
})

test('host export quotes values and neutralizes spreadsheet formulas',()=>{
  assert.equal(csvCell('树, "半醒"'),'"树, ""半醒"""')
  assert.equal(csvCell('=HYPERLINK("https://bad.example")'),'"\'=HYPERLINK(""https://bad.example"")"')
  assert.equal(csvCell('  +123'),'"\'  +123"')
  assert.equal(csvCell('小城还没醒'),'"小城还没醒"')
})
