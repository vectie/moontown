import {coffeeAuth} from './coffee-auth.js';

const appFields = {title:'app-title',topic:'app-topic',scope:'app-scope',audience:'app-audience',proposal:'app-proposal',prize_plan:'app-prizes',contact:'app-contact',cash_budget_cny:'app-cash',requested_instances:'app-instances',requested_total_quota:'app-total',requested_participant_quota:'app-person'};
const applicationStates = {draft:'草稿',submitted:'等待市长审核',changes_requested:'需要补充',approved:'企划已批准',rejected:'未获批准'};
const activityStates = {preparing:'准备资源中',failed:'准备未完成',ready:'等待发布',published:'已发布',paused:'已暂停',revoked:'授权已撤销'};
function inputError(message, field) { const error=new Error(message); error.field=field; return error; }
function integer(value,field,min=1,max=1000000) {
  if (!/^\d+$/.test(String(value)) || !Number.isSafeInteger(Number(value)) || Number(value)<min || Number(value)>max) throw inputError(min ? '请填写范围内的正整数。' : '请填写范围内的非负整数。',field);
  return Number(value);
}
function text(value,field,max,required=true) {
  const result=String(value ?? '').trim();
  if (result.length>max || required && !result) throw inputError(required ? '请完整填写这项内容。' : '这项内容过长，请缩短后重试。',field);
  return result;
}
export function cstInput(value) {
  const millis=Number(value);
  if (!Number.isFinite(millis) || Math.abs(millis)>8e15) return '';
  return new Date(millis+8*3600000).toISOString().slice(0,16);
}
export function cstMillis(value,field='date') {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value)) throw inputError('请填写完整的北京时间。',field);
  const millis=Date.parse(`${value}:00+08:00`);
  if (!Number.isFinite(millis) || cstInput(millis)!==value) throw inputError('日期无效，请重新选择。',field);
  return String(millis);
}
export function applicationPayload(values,editor,submit=false) {
  const result={application_id:editor.id || '',expected_revision:editor.revision || 0,intent:editor.intent};
  for (const [key,max] of Object.entries({title:120,topic:200,scope:2000,audience:1000,proposal:12000,prize_plan:2000,contact:500})) result[key]=text(values[key],appFields[key],max,key==='title' || submit);
  result.cash_budget_cny=integer(values.cash_budget_cny,'app-cash',0);
  result.requested_instances=integer(values.requested_instances,'app-instances');
  result.requested_total_quota=integer(values.requested_total_quota,'app-total');
  result.requested_participant_quota=integer(values.requested_participant_quota,'app-person');
  return result;
}
export function launchPayload(values,app) {
  const grant=app.grant;
  if (!grant || grant.status!=='active') throw new Error('活动授权不可用，请查看审核结果。');
  if (Number(grant.remaining_instances)<=0) throw new Error('已用完获批期数，请申请新的活动计划。');
  const result={application_id:app.id};
  for (const [key,max] of Object.entries({title:120,topic:200,scope:2000,first_person_solution:2000,prize_plan:2000})) result[key]=text(values[key],`launch-${({title:'name',first_person_solution:'solution',prize_plan:'prizes'})[key] || key}`,max);
  const dateFields={opens_ms:'launch-opens',deadline_ms:'launch-deadline',voting_opens_ms:'launch-voting',voting_closes_ms:'launch-close',awards_ms:'launch-awards'};
  for (const [key,id] of Object.entries(dateFields)) result[key]=cstMillis(values[key],id);
  const [opens,deadline,votes,close,awards]=Object.keys(dateFields).map(key=>Number(result[key]));
  if (!(opens<deadline && deadline<=votes && votes<close && close<=awards)) throw inputError('赛程应依次为征集开始、投稿截止、投票开始、投票截止、公布结果。','launch-opens');
  if (opens<Number(grant.starts_ms) || awards>Number(grant.ends_ms)) throw inputError('赛程超出授权有效期，请调整时间或申请延期。','launch-opens');
  result.event_quota=integer(values.event_quota,'launch-quota',1,Math.min(Number(grant.per_event_quota),Number(grant.remaining_generation_quota)));
  result.participant_quota=integer(values.participant_quota,'launch-person',1,Math.min(Number(grant.participant_quota),result.event_quota));
  result.cash_budget_cny=integer(values.cash_budget_cny,'launch-cash',0,Number(grant.remaining_cash_budget_cny ?? grant.cash_budget_cny));
  return result;
}
export function createLaunchIntent(newId=()=>crypto.randomUUID()) {
  let saved=null;
  return {
    prepare(payload) {
      const content=JSON.stringify(payload);
      if (saved && saved.content!==content) throw new Error('创建请求已经发出，请先重试原请求或查看活动列表。');
      if (!saved) saved={content,payload:{...payload,intent:newId()}};
      return {...saved.payload};
    },
    get pending() { return Boolean(saved); },
    get request() { return saved ? {...saved.payload} : null; },
    clear() { saved=null; }
  };
}
export function launchAvailability(app,now) {
  const grant=app?.grant;
  if(!grant || grant.status!=='active')return {allowed:false,reason:'活动授权不可用'};
  if(Number(now)<Number(grant.starts_ms))return {allowed:false,reason:'授权尚未开始'};
  if(Number(now)>=Number(grant.ends_ms))return {allowed:false,reason:'活动授权已到期'};
  if(Number(grant.remaining_instances)<=0 || Number(grant.remaining_generation_quota)<=0)return {allowed:false,reason:'授权额度已用完'};
  return {allowed:true,reason:''};
}
export function launchPreviewRows(activity) {
  const rows=[['作品要求',activity.scope],['怎么玩',activity.first_person_solution],['奖品',activity.prize_plan]];
  for(const [label,key]of [['征集开始','opens_ms'],['投稿截止','deadline_ms'],['投票开始','voting_opens_ms'],['投票截止','voting_closes_ms'],['公布结果','awards_ms']])rows.push([label,cstInput(activity[key]).replace('T',' ')]);
  rows.push(['生成额度',`${activity.event_quota} 次，每人 ${activity.participant_quota} 次`]);
  if(activity.cash_budget_cny!==undefined)rows.push(['现金预算',`${activity.cash_budget_cny} 元`]);
  return rows;
}
if (typeof document!=='undefined') init();
function init() {
  const $=id=>document.getElementById(id), endpoint=new URL('./api/program/',location.href);
  const node=(tag,value,className)=>{ const el=document.createElement(tag); if(value!==undefined) el.textContent=value; if(className)el.className=className; return el; };
  const notify=(message,error=false,target='program-notice')=>{ $(target).textContent=message; $(target).dataset.error=String(error); $(target).dataset.source='action'; };
  let state=null,actor='',writing=false,refreshing=false,epoch=0,timer,appStep=0,launchStep=0;
  let editor={id:'',revision:0,intent:crypto.randomUUID()},launchApp=null,reviewApp=null,revokeApp=null,publishActivity=null;
  let editorDirty=false,launchIntent=createLaunchIntent();
  function fitDialog() {
    const viewport=window.visualViewport,height=viewport?.height || innerHeight;
    document.querySelectorAll('dialog[open]').forEach(dialog=>{
      dialog.style.setProperty('--dialog-height',`${height}px`);
      dialog.style.setProperty('--dialog-center',`${(viewport?.offsetTop || 0)+height/2}px`);
    });
  }
  const auth=coffeeAuth({loginUrl:$('login').href,fitDialog,onSignedIn:async()=>{
    epoch+=1; render(await request('mine'));
    if(!actor)throw new Error('登录状态尚未确认，请重试。');
    notify('已登录，可以填写活动企划。');
  }});
  window.visualViewport?.addEventListener('resize',fitDialog);
  window.visualViewport?.addEventListener('scroll',fitDialog);
  window.addEventListener('resize',fitDialog);
  $('login').onclick=event=>{ if(!actor){event.preventDefault();auth.open();} };
  async function request(path,options={}) {
    const response=await fetch(new URL(path,endpoint),{credentials:'same-origin',cache:'no-store',...options});
    const body=await response.json().catch(()=>({}));
    if(!response.ok){ const error=new Error(body.message || (response.status===401?'请先登录。':'活动服务暂时不可用，请稍后重试。')); error.status=response.status;error.code=body.error;throw error; }
    return body;
  }
  function clearPrivate() {
    for(const id of ['application-form','launch-form','review-form','revoke-form','publish-form'])$(id).reset();
    for(const id of ['review-dialog','revoke-dialog','publish-dialog'])$(id).close();
    for(const id of ['application-editor','launch-editor','my-applications','owner-review'])$(id).hidden=true;
    for(const id of ['application-list','review-list','grant-list','activity-list'])$(id).replaceChildren();
    editor={id:'',revision:0,intent:crypto.randomUUID()};editorDirty=false;launchApp=reviewApp=revokeApp=publishActivity=null;launchIntent.clear();$('publish-preview').replaceChildren();
  }
  function render(value) {
    if(!value?.viewer || !Array.isArray(value.applications) || !Array.isArray(value.activities))throw new Error('活动服务返回内容不完整，请刷新重试。');
    if(state && value.viewer.account_id===actor && value.revision<state.revision)return;
    const changed=!state || value.revision!==state.revision || actor!==value.viewer.account_id || value.viewer.owner!==state.viewer.owner || JSON.stringify(value.activities)!==JSON.stringify(state.activities);
    if(actor && actor!==value.viewer.account_id){clearPrivate();notify('账户已切换，已清理上一账户的企划。');}
    actor=value.viewer.account_id || ''; state=value;
    $('login').textContent=actor?'账户 ↗':'登录 ↗';
    $('program-description').textContent=state.template.name?`提交「${state.template.name}」企划，通过后填写活动落地书。`:'提交企划，通过后填写活动落地书。';
    $('start-application').textContent=actor?editorDirty?'继续填写企划':'新建企划':'登录后申请';
    $('review-shortcut').hidden=!state.viewer.owner;
    $('owner-review').hidden=!state.viewer.owner;
    if(changed){renderApplications();renderActivities();}
    setBusy();
  }
  function details(title,body){const el=node('details');el.append(node('summary',title),body);return el;}
  function facts(rows){const dl=node('dl');for(const [key,value]of rows){if(value===undefined || value===null || value==='')continue;dl.append(node('dt',key),node('dd',String(value)));}return dl;}
  function button(label,callback,primary=false){const el=node('button',label,primary?'secondary':'text-button');el.type='button';el.onclick=callback;el.disabled=writing;return el;}
  function applicationBody(app){const body=node('div');body.append(facts([['主题',app.topic],['参与者',app.audience],['作品范围',app.scope],['奖品',app.prize_plan],['联系方式',app.contact]]),node('p',app.proposal));return body;}
  function renderApplications() {
    const mine=state.applications.filter(app=>app.actor===actor);
    $('my-applications').hidden=!mine.length;
    $('application-list').replaceChildren(...mine.map(app=>{
      const card=node('article',undefined,'program-card');card.append(node('h3',app.title),node('span',app.grant?.status==='revoked'?'授权已撤销':applicationStates[app.status] || app.status,'state'));
      if(app.review_note)card.append(node('p',app.review_note));
      const actions=node('div',undefined,'actions');
      if(['draft','changes_requested'].includes(app.status))actions.append(button('继续填写',()=>editApplication(app),true));
      if(app.status==='rejected')actions.append(button('以此新建企划',()=>editApplication({...app,id:'',revision:0}),true));
      if(app.status==='approved' && app.grant?.status==='active'){
        card.append(node('p',`剩余 ${app.grant.remaining_instances} 期 · ${app.grant.remaining_generation_quota} 次生成 · ${app.grant.remaining_cash_budget_cny ?? app.grant.cash_budget_cny} 元`,'fine-print'));
        const launch=button('填写活动落地书',()=>openLaunch(app),true);launch.dataset.launchApplication=app.id;actions.append(launch);
        card.append(node('p',`授权至 ${cstInput(app.grant.ends_ms).replace('T',' ')}（北京时间）`,'fine-print'));
      }
      card.append(details('查看企划',applicationBody(app)),actions);return card;
    }));
    if(!state.viewer.owner)return;
    const submitted=state.applications.filter(app=>app.status==='submitted');
    $('review-shortcut').textContent=submitted.length?`审核企划 · ${submitted.length} 项`:'活动审批';
    $('review-list').replaceChildren(...submitted.map(app=>{
      const card=node('article',undefined,'program-card');card.append(node('h3',app.title),node('p',app.topic),node('p',`${app.requested_instances} 期 · ${app.requested_total_quota} 次生成 · 现金 ${app.cash_budget_cny} 元`,'fine-print'),details('查看完整企划',applicationBody(app)),button('审核这份企划',()=>openReview(app),true));return card;
    }));
    if(!submitted.length)$('review-list').append(node('p','暂时没有待审企划。','fine-print'));
    const grants=state.applications.filter(app=>app.grant?.status==='active');
    $('owner-grants').hidden=!grants.length;
    $('grant-list').replaceChildren(...grants.map(app=>{
      const card=node('article',undefined,'program-card');card.append(node('h3',app.title),node('p',`剩余 ${app.grant.remaining_instances} 期 · ${app.grant.remaining_generation_quota} 次生成`,'fine-print'),button('撤销活动授权',()=>{
        revokeApp=app;$('revoke-summary').textContent=app.title;$('revoke-reason').value='';notify('',false,'revoke-notice');$('revoke-dialog').showModal();fitDialog();$('revoke-reason').focus();
      }));return card;
    }));
  }
  function renderActivities() {
    const activities=state.activities;
    $('activities-section').hidden=!activities.length;
    $('activity-list').replaceChildren(...activities.map(activity=>{
      const card=node('article',undefined,'program-card');card.id=`activity-${activity.id}`;
      card.append(node('h3',activity.title),node('span',activityStates[activity.status] || activity.status,'state'));
      if(activity.reason)card.append(node('p',activity.reason));
      const actions=node('div',undefined,'actions');
      if(['published','paused'].includes(activity.status)){
        const link=node('a','打开活动','secondary');link.href=`coffee-contest.html?activity=${encodeURIComponent(activity.id)}`;actions.append(link);
        if(activity.may_manage){const manage=node('a','审核作品','text-button');manage.href=`${link.href}#moderation`;actions.append(manage);}
      }
      if(activity.may_manage){
        if(activity.status==='failed')actions.append(button('重试准备',()=>write('retry-activity',{activity_id:activity.id}),true));
        const sourceApplication=state.applications.find(app=>app.id===activity.application_id);
        if(activity.status==='ready' && (activity.may_publish ?? (state.viewer.owner || sourceApplication?.grant?.allow_publish)))actions.append(button('核对并发布',()=>{
          publishActivity=activity;$('publish-preview').replaceChildren(node('h3',activity.title),node('p',activity.topic),facts(launchPreviewRows(activity)));notify('',false,'publish-notice');$('publish-dialog').showModal();setBusy();fitDialog();
        },true));
        if(activity.status==='published')actions.append(button('暂停活动',()=>write('pause-activity',{activity_id:activity.id})));
        if(activity.status==='paused')actions.append(button('恢复活动',()=>write('resume-activity',{activity_id:activity.id}),true));
        card.append(node('p',`本期上限 ${activity.event_quota} 次生成 · 每人 ${activity.participant_quota} 次`,'fine-print'));
        const binding=activity.binding || {};
        const rows=[['策展书',binding.book_id],['策展 profile',binding.curator_profile || binding.profile_id],['工作流',binding.workflow_id],['版本',binding.workflow_version]];
        if(rows.some(([,value])=>value))card.append(details('策展与资源',facts(rows)));
      }
      card.append(actions);return card;
    }));
  }
  function setBusy() {
    $('start-application').disabled=!state || writing;
    document.querySelectorAll('.program-cards button').forEach(control=>control.disabled=writing);
    document.querySelectorAll('[data-launch-application]').forEach(control=>{
      const app=state?.applications.find(item=>item.id===control.dataset.launchApplication),availability=launchAvailability(app,state?.server_ms || Date.now());
      control.disabled=writing || !availability.allowed;
      control.textContent=availability.allowed?'填写活动落地书':availability.reason;
    });
    for(const id of ['application-form','review-form','revoke-form','publish-form'])$(id).querySelectorAll('input,textarea,select,button').forEach(control=>control.disabled=writing);
    const currentPublication=state?.activities.find(activity=>activity.id===publishActivity?.id);
    $('confirm-publish').disabled=writing || !currentPublication || currentPublication.status!=='ready' || currentPublication.may_publish===false;
    $('launch-form').querySelectorAll('input,textarea,select').forEach(control=>control.disabled=writing || launchIntent.pending);
    for(const id of ['launch-next','launch-back'])$(id).disabled=writing || launchIntent.pending;
    $('launch-create').disabled=writing;
    $('launch-create').textContent=writing?'正在生成…':launchIntent.pending?'重试生成活动':'确认生成活动';
    for(const id of ['review-dialog','revoke-dialog','publish-dialog'])$(id).querySelector('.dialog-close').disabled=writing;
  }
  async function write(action,payload,target='program-notice') {
    if(writing)return null;
    if(!actor){auth.open();return null;}
    writing=true;setBusy();notify('',false,target);
    try{
      const value=await request('actions',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,payload,expected_actor_id:actor})});
      writing=false;render(value);notify('已保存。',false,target);return value;
    }catch(error){
      notify(error.message,true,target);
      if(error.status===401 || error.code==='identity_changed'){clearPrivate();actor='';state=null;epoch+=1;setTimeout(refresh,0);}
      return null;
    }finally{writing=false;setBusy();}
  }
  async function refresh() {
    if(refreshing || writing)return;
    refreshing=true;const currentEpoch=epoch;
    try{
      let value;try{value=await request('mine');}catch(error){if(error.status!==401)throw error;value=await request('public');}
      if(currentEpoch===epoch){
        render(value);
        if($('program-notice').dataset.source==='refresh')notify('');
      }
    }catch(error){notify(error.message,true);$('program-notice').dataset.source='refresh';}finally{refreshing=false;}
  }
  function showAppStep(step) {
    appStep=step;document.querySelectorAll('[data-app-step]').forEach(el=>el.hidden=Number(el.dataset.appStep)!==step);
    $('application-editor-title').textContent=`${['活动想法','企划与奖品','资源与联络'][step]} · ${step+1}/3`;
    $('app-back').hidden=step===0;$('app-next').hidden=step===2;$('app-submit').hidden=step!==2;
  }
  function editApplication(app=null) {
    if(editorDirty && app?.id!==editor.id && !confirm('当前企划尚未保存，放弃本次修改？'))return;
    editor={id:app?.id || '',revision:app?.revision || 0,intent:crypto.randomUUID()};
    $('application-form').reset();
    for(const [key,id]of Object.entries(appFields))$(id).value=app?.[key] ?? '';
    $('app-instances').value=app?.requested_instances || 1;
    $('app-total').value=app?.requested_total_quota || Math.min(40,state.template.max_total_quota || 40);
    $('app-person').value=app?.requested_participant_quota || Math.min(3,state.template.max_participant_quota || 3);
    $('app-cash').value=app?.cash_budget_cny ?? 0;
    editorDirty=false;showAppStep(0);notify('',false,'application-notice');$('application-editor').hidden=false;$('launch-editor').hidden=true;
    $('application-editor').scrollIntoView({block:'start'});$('app-title').focus({preventScroll:true});
  }
  function appValues(){return Object.fromEntries(Object.entries(appFields).map(([key,id])=>[key,$(id).value]));}
  function showError(error,target) {
    notify(error.message,true,target);
    if(!error.field)return;
    const field=$(error.field);
    if(!field)return;
    const app=field.closest('[data-app-step]'),launch=field.closest('[data-launch-step]');
    if(app)showAppStep(Number(app.dataset.appStep));if(launch)showLaunchStep(Number(launch.dataset.launchStep));
    field.focus();
  }
  async function saveApplication(submit) {
    try{
      const payload=applicationPayload(appValues(),editor,submit),value=await write('save-application',payload,'application-notice');
      if(!value)return;
      const saved=value.applications.find(app=>app.id===(value.application_id || editor.id));
      if(!saved)throw new Error('草稿已保存，请从企划列表重新打开。');
      editor.id=saved.id;editor.revision=saved.revision;editorDirty=false;
      if(submit){
        const submitted=await write('submit-application',{application_id:saved.id,expected_revision:saved.revision},'application-notice');
        if(submitted){$('application-editor').hidden=true;notify('企划已提交，等待市长审核。');$('my-applications').scrollIntoView({block:'start'});}
      }else notify('草稿已保存。',false,'application-notice');
    }catch(error){showError(error,'application-notice');}
  }
  $('start-application').onclick=()=>{if(!actor)return auth.open();if(editorDirty){$('application-editor').hidden=false;$('application-editor').scrollIntoView({block:'start'});}else editApplication();};
  $('application-form').addEventListener('input',()=>{editorDirty=true;$('start-application').textContent='继续填写企划';});
  $('close-application').onclick=()=>{$('application-editor').hidden=true;$('start-application').focus();};
  $('app-back').onclick=()=>showAppStep(appStep-1);
  $('app-next').onclick=()=>showAppStep(Math.min(2,appStep+1));
  $('app-save').onclick=()=>saveApplication(false);
  $('application-form').onsubmit=event=>{event.preventDefault();saveApplication(true);};
  function latestLaunchApp(){return state.applications.find(app=>app.id===launchApp?.id) || launchApp;}
  function openLaunch(app) {
    launchApp=app;launchIntent=createLaunchIntent();$('launch-form').reset();
    for(const [id,key]of Object.entries({'launch-name':'title','launch-topic':'topic','launch-scope':'scope','launch-prizes':'prize_plan'}))$(id).value=app[key];
    $('launch-solution').value='我写提示词，生成一张图，再选一张正式参赛。';
    const grant=app.grant,start=Math.ceil(Math.max(Number(state.server_ms || Date.now())+300000,Number(grant.starts_ms))/60000)*60000;
    const span=Math.min(8*86400000,Number(grant.ends_ms)-start);
    if(span<1800000){notify('授权剩余时间不足，请先申请延长有效期。',true);return;}
    const moments={'launch-opens':start,'launch-deadline':start+span*.6,'launch-voting':start+span*.65,'launch-close':start+span*.9,'launch-awards':start+span*.95};
    for(const [id,millis]of Object.entries(moments))$(id).value=cstInput(millis);
    $('launch-quota').value=Math.min(Number(grant.per_event_quota),Number(grant.remaining_generation_quota));
    $('launch-person').value=Math.min(Number(grant.participant_quota),Number($('launch-quota').value));
    $('launch-cash').value=0;
    $('grant-summary').textContent=`剩余 ${grant.remaining_instances} 期 · ${grant.remaining_generation_quota} 次生成 · ${grant.remaining_cash_budget_cny ?? grant.cash_budget_cny} 元`;
    notify('',false,'launch-notice');showLaunchStep(0);$('launch-editor').hidden=false;$('application-editor').hidden=true;setBusy();$('launch-editor').scrollIntoView({block:'start'});$('launch-name').focus({preventScroll:true});
  }
  function launchValues(){return Object.fromEntries(Object.entries({title:'launch-name',topic:'launch-topic',scope:'launch-scope',first_person_solution:'launch-solution',prize_plan:'launch-prizes',opens_ms:'launch-opens',deadline_ms:'launch-deadline',voting_opens_ms:'launch-voting',voting_closes_ms:'launch-close',awards_ms:'launch-awards',event_quota:'launch-quota',participant_quota:'launch-person',cash_budget_cny:'launch-cash'}).map(([key,id])=>[key,$(id).value]));}
  function showLaunchStep(step){
    launchStep=step;document.querySelectorAll('[data-launch-step]').forEach(el=>el.hidden=Number(el.dataset.launchStep)!==step);
    $('launch-title').textContent=`${['活动落地书','赛程与额度','发布前预览'][step]} · ${step+1}/3`;
    $('launch-back').hidden=step===0;$('launch-next').hidden=step===2;$('launch-create').hidden=step!==2;
  }
  $('launch-next').onclick=()=>{
    if(launchStep===0){showLaunchStep(1);return;}
    try{
      const payload=launchPayload(launchValues(),latestLaunchApp());
      $('launch-preview').replaceChildren(node('h3',payload.title),node('p',payload.topic),facts(launchPreviewRows(payload)),node('p',latestLaunchApp().grant.allow_publish?'资源就绪后自动发布。':'生成活动后，由市长核对活动内容并发布。','fine-print'));
      showLaunchStep(2);
    }catch(error){showError(error,'launch-notice');}
  };
  $('launch-back').onclick=()=>showLaunchStep(launchStep-1);
  $('close-launch').onclick=()=>{$('launch-editor').hidden=true;$('activities-section').hidden?$('start-application').focus():$('activities-section').scrollIntoView({block:'start'});};
  $('launch-form').onsubmit=async event=>{
    event.preventDefault();
    try{
      const payload=launchIntent.request || launchIntent.prepare(launchPayload(launchValues(),latestLaunchApp()));
      const result=await write('create-activity',payload,'launch-notice');
      if(!result){setBusy();return;}
      launchIntent.clear();$('launch-editor').hidden=true;notify('活动已建立，正在检查策展与算力资源。');
      $(`activity-${result.activity_id}`)?.scrollIntoView({block:'start'});
    }catch(error){showError(error,'launch-notice');}
  };
  function openReview(app){
    reviewApp=app;$('review-form').reset();$('review-dialog-title').textContent=`审核：${app.title}`;
    $('review-brief').replaceChildren(applicationBody(app),facts([['申请期数',app.requested_instances],['申请总额度',app.requested_total_quota],['每人上限',app.requested_participant_quota],['现金预算',`${app.cash_budget_cny} 元`]]));
    const template=state.template,now=Number(state.server_ms || Date.now());
    $('grant-start').value=cstInput(now-60000);$('grant-end').value=cstInput(now+30*86400000);
    $('grant-instances').value=Math.min(app.requested_instances,template.max_instances);
    $('grant-total').value=Math.min(app.requested_total_quota,template.max_total_quota);
    $('grant-event').value=Math.min(Number($('grant-total').value),template.max_event_quota);
    $('grant-person').value=Math.min(app.requested_participant_quota,template.max_participant_quota);
    $('grant-cash').value=Math.min(app.cash_budget_cny,template.max_cash_budget_cny);
    $('grant-publish').checked=false;notify('',false,'review-notice');$('review-dialog').showModal();fitDialog();
  }
  async function review(decision){
    try{
      const payload={application_id:reviewApp.id,expected_revision:reviewApp.revision,decision,note:$('review-note').value.trim()};
      if(decision!=='approve' && !payload.note)throw inputError('请写明需要补充或不予批准的原因。','review-note');
      if(decision==='approve'){
        payload.starts_ms=cstMillis($('grant-start').value,'grant-start');payload.ends_ms=cstMillis($('grant-end').value,'grant-end');
        if(Number(payload.ends_ms)<=Number(payload.starts_ms))throw inputError('授权结束时间必须晚于开始时间。','grant-end');
        for(const [key,id,cap]of [['max_instances','grant-instances','max_instances'],['total_generation_quota','grant-total','max_total_quota'],['per_event_quota','grant-event','max_event_quota'],['participant_quota','grant-person','max_participant_quota']])payload[key]=integer($(id).value,id,1,state.template[cap]);
        payload.cash_budget_cny=integer($('grant-cash').value,'grant-cash',0,state.template.max_cash_budget_cny);payload.allow_publish=$('grant-publish').checked;
        if(payload.per_event_quota>payload.total_generation_quota || payload.participant_quota>payload.per_event_quota)throw inputError('单期和个人额度不能大于已批准总额。','grant-event');
      }
      if(await write('review-application',payload,'review-notice')){$('review-dialog').close();notify(decision==='approve'?'企划已批准，申请人可以填写活动落地书。':decision==='request-changes'?'已退回补充。':'已记录不予批准。');}
    }catch(error){showError(error,'review-notice');}
  }
  $('review-form').onsubmit=event=>{event.preventDefault();review('approve');};
  $('request-changes').onclick=()=>review('request-changes');$('reject-plan').onclick=()=>review('reject');
  $('close-review').onclick=()=>$('review-dialog').close();$('close-revoke').onclick=()=>$('revoke-dialog').close();
  $('close-publish').onclick=()=>$('publish-dialog').close();
  $('publish-form').onsubmit=async event=>{
    event.preventDefault();if(!publishActivity)return;
    const result=await write('publish-activity',{activity_id:publishActivity.id},'publish-notice');
    if(result){$('publish-dialog').close();publishActivity=null;notify('活动已发布。');}
  };
  $('revoke-form').onsubmit=async event=>{event.preventDefault();if(await write('revoke-grant',{application_id:revokeApp.id,reason:$('revoke-reason').value.trim()},'revoke-notice')){$('revoke-dialog').close();notify('已撤销活动授权，已登录的会话也不能继续管理。');}};
  for(const id of ['review-dialog','revoke-dialog','publish-dialog'])$(id).addEventListener('cancel',event=>{if(writing)event.preventDefault();});
  $('refresh-program').onclick=refresh;
  async function poll(){clearTimeout(timer);if(!document.hidden)await refresh();timer=setTimeout(poll,state?.activities.some(activity=>activity.status==='preparing')?4000:15000);}
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)poll();});window.addEventListener('focus',refresh);window.addEventListener('pagehide',()=>clearTimeout(timer));poll();
}
