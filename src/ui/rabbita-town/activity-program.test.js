import test from 'node:test';
import assert from 'node:assert/strict';
import {cstInput,cstMillis,applicationPayload,launchPayload,createLaunchIntent,launchAvailability,launchPreviewRows} from './activity-program.js';

test('activity times use Beijing time independently of host timezone and reject rolled dates',()=>{
  assert.equal(cstMillis('2026-11-07T09:00'),'1794013200000');
  assert.equal(cstInput('1794013200000'),'2026-11-07T09:00');
  assert.throws(()=>cstMillis('2026-02-30T09:00'),/日期无效/);
  assert.throws(()=>cstMillis('2026-11-07T09:00Z'),/北京时间/);
});
const fields={title:' 半醒活动 ',topic:'咖啡',scope:'原创插画',audience:'街区居民',proposal:'主办准备素材并审核，投票后发奖。',prize_plan:'手办、布包、咖啡',contact:'联系主办',cash_budget_cny:'100',requested_instances:'2',requested_total_quota:'30',requested_participant_quota:'3'};
test('partial drafts can be saved but submitted plans must contain a real proposal and contact',()=>{
  const editor={id:'',revision:0,intent:'same-request'};
  const draft=applicationPayload({...fields,proposal:'',contact:''},editor);
  assert.equal(draft.title,'半醒活动');assert.equal(draft.cash_budget_cny,100);
  assert.equal(draft.intent,'same-request');assert.equal(draft.expected_revision,0);
  assert.throws(()=>applicationPayload({...fields,contact:''},editor,true),error=>error.field==='app-contact');
  assert.throws(()=>applicationPayload({...fields,requested_total_quota:'2.5'},editor),error=>error.field==='app-total');
});
const app={id:'app-approved',grant:{status:'active',starts_ms:cstMillis('2026-11-07T08:00'),ends_ms:cstMillis('2026-11-14T20:00'),remaining_instances:1,per_event_quota:20,remaining_generation_quota:12,participant_quota:3,cash_budget_cny:100,remaining_cash_budget_cny:40}};
const launch={title:'第一期',topic:'咖啡',scope:'原创插画',first_person_solution:'我写提示词并投稿。',prize_plan:'三个奖项',opens_ms:'2026-11-07T09:00',deadline_ms:'2026-11-12T18:00',voting_opens_ms:'2026-11-13T09:00',voting_closes_ms:'2026-11-13T17:00',awards_ms:'2026-11-13T18:00',event_quota:'12',participant_quota:'3',cash_budget_cny:'40'};
test('workbook validates against remaining aggregate grant rather than original maxima',()=>{
  const value=launchPayload(launch,app);assert.equal(value.event_quota,12);assert.equal(value.application_id,app.id);
  assert.throws(()=>launchPayload({...launch,event_quota:'13'},app),error=>error.field==='launch-quota');
  assert.throws(()=>launchPayload({...launch,cash_budget_cny:'41'},app),error=>error.field==='launch-cash');
  assert.throws(()=>launchPayload({...launch,awards_ms:'2026-11-15T09:00'},app),/授权有效期/);
  assert.throws(()=>launchPayload({...launch,voting_opens_ms:'2026-11-11T09:00'},app),/赛程应依次/);
  assert.throws(()=>launchPayload(launch,{...app,grant:{...app.grant,status:'revoked'}}),/授权不可用/);
});
test('ambiguous activity creation retries one immutable intent and refuses payload drift',()=>{
  let ids=0;const intent=createLaunchIntent(()=>`create-${++ids}`);
  const request={application_id:'a',event_quota:10};
  assert.deepEqual(intent.prepare(request),intent.prepare({...request}));assert.equal(ids,1);
  assert.deepEqual(intent.request,{...request,intent:'create-1'});
  assert.throws(()=>intent.prepare({...request,event_quota:20}),/原请求/);
  intent.clear();assert.equal(intent.prepare(request).intent,'create-2');
});
test('organizers see unavailable grant state before filling a launch workbook',()=>{
  assert.equal(launchAvailability(app,cstMillis('2026-11-08T09:00')).allowed,true);
  assert.equal(launchAvailability(app,cstMillis('2026-11-06T09:00')).reason,'授权尚未开始');
  assert.equal(launchAvailability(app,cstMillis('2026-11-15T09:00')).reason,'活动授权已到期');
  assert.equal(launchAvailability({...app,grant:{...app.grant,remaining_instances:0}},cstMillis('2026-11-08T09:00')).reason,'授权额度已用完');
});
test('publishing preview keeps the actual public wording and schedule without private application fields',()=>{
  const activity={...launchPayload(launch,app),scope:'最新作品要求',prize_plan:'主办修改后的兑奖方式',contact:'private-contact',proposal:'private-plan',binding:{provider_path:'/private/provider'}};
  const rows=launchPreviewRows(activity),preview=JSON.stringify(rows);
  assert.ok(preview.includes('最新作品要求'));assert.ok(preview.includes('主办修改后的兑奖方式'));
  assert.deepEqual(rows.find(([label])=>label==='投票截止'),['投票截止','2026-11-13 17:00']);
  assert.doesNotMatch(preview,/private-contact|private-plan|private\/provider/);
});
