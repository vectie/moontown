import { coffeeAuth } from './coffee-auth.js';
import { draftStore } from './coffee-drafts.js';
import { coffeeClaim, claimGroup } from './coffee-claim.js';
import { coffeeShare, suggestedTitle, shareableEntry } from './coffee-share.js';
export const DEFAULT_PROMPT = '一只装着清晨的咖啡杯，杯中是一座还没有醒来的微缩小城，奶油色和森林绿，温暖的手绘插画，安静而奇妙，不要文字和商标';
export function generationPrompt(value) { return value.trim() || DEFAULT_PROMPT; }
export function personalWorks(value) {
  return (value.generations || []).filter(job => job.state === 'completed').toReversed().map(job => ({job,entry:(value.entries || []).toReversed().find(entry => entry.generation_id === job.id)}));
}
function creativeEndpoint(href) {
  const page = new URL(href);
  const id = page.searchParams.get('activity');
  if (id === null) return new URL('./api/creative/', page);
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(id)) throw new Error('活动链接无效，请从活动列表重新打开。');
  return new URL(`./api/activities/${encodeURIComponent(id)}/`, page);
}
function votingRows(value) {
  const gallery = new Map((value.gallery || []).map(entry => [entry.id, entry]));
  return (value.voting?.counts || []).filter(row => row.eligible).map(row => ({
    ...row, title: gallery.get(row.entry_id)?.title || '作品已撤回',
    display_name: gallery.get(row.entry_id)?.display_name || ''
  })).sort((a,b) => a.rank - b.rank || a.entry_id.localeCompare(b.entry_id));
}
function creationPhase(event,now) {
  return now<Number(event.opens_ms)?'waiting':now<Number(event.deadline_ms)?'open':'closed';
}
function generationCredits(value,signedIn) {
  if(signedIn && value.generations?.some(job=>['queued','running','needs_reconcile'].includes(job.state)))return '';
  if(value.event_remaining===0)return '本期生成名额已用完 · 已生成图片仍可投稿';
  const personal=signedIn || value.viewer?.guest_id ? value.remaining:value.event.participant_quota;
  const remaining=Number.isFinite(value.event_remaining)?Math.min(personal,value.event_remaining):personal;
  return signedIn?`本期还可生成 ${remaining} 张 · 投稿前仅自己可见`:`本期最多可生成 ${remaining} 张 · 投稿前仅自己可见`;
}
async function originalImage(path, fetcher = fetch, onRetry = () => {}, signal) {
  for (let attempt = 0; attempt < 2; attempt++) {
    if (signal?.aborted) throw new DOMException('请求已取消','AbortError');
    const controller = new AbortController();
    const abort = () => controller.abort();
    signal?.addEventListener('abort',abort,{once:true});
    const timeout = setTimeout(abort,12000);
    try {
      const response = await fetcher(path, {credentials:'same-origin',cache:'no-store',signal:controller.signal});
      if (!response.ok) {
        const error = new Error('原图暂不可用');
        error.status = response.status;
        throw error;
      }
      const blob = await response.blob();
      if (blob.size < 32 || blob.size > 12 * 1024 * 1024) {
        const error = new Error('原图数据不完整');
        error.status = 422;
        throw error;
      }
      return blob;
    } catch (error) {
      if (signal?.aborted || attempt || error.status && error.status < 500) throw error;
      onRetry();
      await new Promise(resolve => setTimeout(resolve, 250 + Math.random() * 250));
    } finally {
      clearTimeout(timeout);
      signal?.removeEventListener('abort',abort);
    }
  }
}
const jobLabels = Object.freeze({
  queued: "已经排好队，轮到你就开始画。",
  running: "正在把想象画出来，请稍等。离开页面也不会丢失任务。",
  needs_reconcile: "这次生成需要主办核对。我们会保留记录，不会自动重复生成。",
  failed: "这次没有完成，次数已退回。可以再试一次。"
});
const entryLabels = Object.freeze({ pending: "审核中", approved: "参赛中", rejected: "未过审", superseded: "已被新版替换", withdrawn: "已撤回", disqualified:'已下架' });
function generationStatus(job, now, activity) {
  if (!job) return '';
  if (!['queued', 'running'].includes(job.state) || !job.queue) return jobLabels[job.state] || '';
  if (activity?.generation_allowed === false) return '活动暂不可生成，排队进度等待主办确认。';
  const q = job.queue, ahead = Math.max(0, Number(q.ahead) || 0);
  if (q.status === 'blocked') return q.reason === 'closed' ? '本期已截止，排队任务正在结算。' : '队列暂时暂停，等待主办核对。';
  if (q.status === 'delayed') return job.state === 'running' ? '还在生成，已超过预计时间。离开页面也不会丢失任务。' : `前面还有 ${ahead} 人，当前生成比预计久一些。`;
  const time = job.state === 'running' || ahead === 0 ? q.estimated_ready_ms : q.estimated_start_ms;
  if (time == null || !Number.isFinite(Number(time))) return jobLabels[job.state];
  const seconds = Math.max(0, Math.ceil((Number(time) - now) / 1000));
  const duration = seconds >= 60 ? `${Math.ceil(seconds / 60)} 分钟` : `${Math.max(5, Math.ceil(seconds / 5) * 5)} 秒`;
  if (job.state === 'running') return seconds === 0 ? '正在收尾，请稍等。' : `正在生成 · 预计还需约 ${duration}`;
  return ahead ? `前面还有 ${ahead} 人 · 预计约 ${duration}开始` : `马上轮到你 · 预计约 ${duration}完成`;
}
const prizeLabels = Object.freeze({ creative: "一等奖 · 手办", popular: "二等奖 · 帆布包", coffee: "三等奖 · 咖啡券" });
function csvCell(value) {
  const text = String(value ?? "");
  return `"${(/^[\s]*[=+@\-\t\r]/.test(text) ? "'" : "") + text.replaceAll('"', '""')}"`;
}
function labelPng(bytes, produceId = "") {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 20 || !signature.every((n, i) => bytes[i] === n)) throw new Error("图片格式不可用");
  const payload = new TextEncoder().encode("AIGC\0" + JSON.stringify({ Label: "1", ContentProducer: "LunaNexa", ProduceID: produceId, ContentPropagator: "MoonTown", PropagateID: produceId }));
  const chunk = new Uint8Array(payload.length + 12);
  new DataView(chunk.buffer).setUint32(0, payload.length);
  chunk.set([116, 69, 88, 116], 4);
  chunk.set(payload, 8);
  let crc = 4294967295;
  for (const byte of chunk.subarray(4, -4)) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = crc >>> 1 ^ (crc & 1 ? 3988292384 : 0);
  }
  new DataView(chunk.buffer).setUint32(chunk.length - 4, (crc ^ 4294967295) >>> 0);
  const offset = bytes.length - 12;
  if (String.fromCharCode(...bytes.subarray(offset + 4, offset + 8)) !== "IEND") throw new Error("图片数据不完整");
  const result = new Uint8Array(bytes.length + chunk.length);
  result.set(bytes.subarray(0, offset));
  result.set(chunk, offset);
  result.set(bytes.subarray(offset), offset + chunk.length);
  return result;
}
if (typeof document !== "undefined") init();
function init() {
  const $ = (id) => document.getElementById(id);
  let endpoint;
  try { endpoint = creativeEndpoint(location.href); }
  catch (error) { $('notice').textContent = error.message; $('notice').dataset.error = 'true'; $('phase').textContent='活动链接无效'; return; }
  const url = (path) => new URL(path, endpoint).href;
  let state = null, selected = "", actor = "", pendingIntent = null, writing = false, refreshing = false, timer, clockOffset = 0;
  const reviewDrafts = /* @__PURE__ */ new Map();
  const reviewReturns = new Set();
  let reviewKey = '';
  let votingDirty = false, followGeneration = false, identityEpoch = 0;
  let rankingKey = '', historyKey = '';
  let refreshError = '';
  let artworkRequest = 0, artworkUrl = '';
  let artworkController = null, downloadController = null;
  let artworkReturn = null;
  let disqualifyEntry = '';
  let draftOwner = 'visitor', afterAuth = '', uploadDraft = null, ownWallKey = '', wall = 'auto';
  let titleJob='',titleAuto=false;
  const drafts = draftStore(endpoint.href, message => notice(message,true,'draft-notice'));
  function currentDraft() {
    return {prompt:$('prompt').value,selected,pendingIntent,following:followGeneration,title:$('entry-title').value,name:$('display-name').value,titleJob,titleAuto};
  }
  function saveDraft() { drafts.write(draftOwner,currentDraft()); }
  async function restoreDraft(owner, inherited) {
    const epoch=identityEpoch, promptBefore=$('prompt').value;
    const value = inherited || await drafts.read(owner);
    if(owner!==draftOwner || epoch!==identityEpoch || !inherited && $('prompt').value!==promptBefore)return;
    if (value) {
      $('prompt').value=typeof value.prompt==='string'?value.prompt.slice(0,2000):'';
      $('prompt-count').textContent=`${$('prompt').value.length} / 2000`;
      selected=typeof value.selected==='string'?value.selected:'';
      pendingIntent=value.pendingIntent || null;
      followGeneration=Boolean(value.following);
      $('entry-title').value=value.title || ''; $('display-name').value=value.name || '';
      titleJob=value.titleJob || '';titleAuto=Boolean(value.titleAuto);
      if(inherited)saveDraft();
    }
    uploadDraft=null;
    drafts.readFile(owner).then(value=>{
      if(owner!==draftOwner || epoch!==identityEpoch)return;
      uploadDraft=value;
      $('replace-upload').hidden=!value?.file;
      if(value?.file){$('choose-upload').textContent='继续上传已选作品';notice(`已恢复：${value.name}`,false,'upload-notice');}
    });
    queueMicrotask(()=>{if(owner===draftOwner && epoch===identityEpoch && state)render(state);});
  }
  const initialDraft=restoreDraft(draftOwner);
  const dialog = $("submit-dialog");
  function fitDialog() {
    const viewport = window.visualViewport;
    const height = viewport?.height || window.innerHeight;
    document.querySelectorAll('dialog[open]').forEach(openDialog => {
      openDialog.style.setProperty("--dialog-height", `${height}px`);
      openDialog.style.setProperty("--dialog-center", `${(viewport?.offsetTop || 0) + height / 2}px`);
    });
  }
  const claim = coffeeClaim({fitDialog, now:() => Date.now() + clockOffset, onDone:() => {
    showWall('mine'); $('own-wall').querySelector('button')?.focus({preventScroll:true});
  }});
  const sharing=coffeeShare({getState:()=>state,fitDialog,now:()=>Date.now()+clockOffset,
    imageUrl:id=>url(`images/${id}/preview`),loadImage:(path,signal)=>originalImage(path,fetch,()=>{},signal),labelPng});
  let titleVariant=0,sharedTargetHandled=false;
  const sharedTarget=new URL(location.href).searchParams.get('entry');
  $('claim-group').onclick = () => claim.open(state?.event);
  $('my-works-link').onclick = () => showWall('mine');
  const auth = coffeeAuth({ loginUrl: $("login").href, fitDialog, onSignedIn: async () => {
    identityEpoch += 1;
    render(await request('mine'));
    if (!actor) throw new Error('登录状态尚未确认，请重试。');
    notice('已登录，草稿和之前生成的作品已保留。');
    const next=afterAuth;afterAuth='';
    setTimeout(()=>{if(next==='submit' && selected)openSubmission();else if(next==='upload'){$('choose-upload').focus();notice('已登录，点击上传按钮选择作品。',false,'upload-notice');}else if(next==='mine')showWall('mine');},0);
  } });
  $("login").addEventListener('click', event => { if (!actor) { event.preventDefault(); auth.open(); } });
  window.visualViewport?.addEventListener("resize", fitDialog);
  window.visualViewport?.addEventListener("scroll", fitDialog);
  window.addEventListener("resize", fitDialog);
  const node = (tag, text, className) => {
    const element = document.createElement(tag);
    if (text !== void 0) element.textContent = text;
    if (className) element.className = className;
    return element;
  };
  const notice = (message, error = false, target = "notice") => {
    if (target === 'notice') refreshError = '';
    const surface=$(target);
    if(!surface) return;
    surface.textContent = message;
    surface.dataset.error = String(error);
  };
  const active = () => state?.generations?.some((job) => ["queued", "running", "needs_reconcile"].includes(job.state));
  const open = () => state && Date.now() + clockOffset >= Number(state.event.opens_ms) && Date.now() + clockOffset < Number(state.event.deadline_ms);
  function clearPrivate() {
    downloadController?.abort();
    downloadController = null;
    $('download').disabled = false;
    $('download').textContent = '保存图片 ↓';
    selected = "";
    titleJob='';titleAuto=false;
    pendingIntent = null;
    followGeneration = false;
    $("create-form").reset();
    $("submit-form").reset();
    $("prompt-count").textContent = "0 / 2000";
    document.querySelectorAll("[data-prompt]").forEach(button => button.setAttribute("aria-pressed", "false"));
    $("submit-dialog").close();
    $("artwork-dialog").close();
    $('disqualify-dialog').close();disqualifyEntry='';
    claim.close(); wall='auto'; ownWallKey='';
    sharing.close();
    $("artwork-image").removeAttribute("src");
    $("result-image").removeAttribute("src");
    $("result-image").removeAttribute("data-job");
    $("result").hidden = true;
    $("empty-preview").hidden = false;
    $("result-panel").classList.add("is-empty");
    $("moderation").hidden = true;
    $("host-shortcut").hidden = true;
    $('vote-feedback').textContent = '';
    rankingKey = '';
    $("my-entry").hidden = true;
    $("history").replaceChildren();
    historyKey = '';
    reviewDrafts.clear();
    reviewReturns.clear();
    reviewKey = '';
    votingDirty = false;
    $("voting-form").reset();
    $("award-form").reset();
  }
  async function request(path, options = {}) {
    let response;
    try { response=await fetch(url(path), { credentials: "same-origin", cache: "no-store", signal:AbortSignal.timeout(path==='uploads'?60000:15000), ...options }); }
    catch { throw new Error('连接暂时中断，草稿已保留。恢复网络后可以继续。'); }
    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      const error = new Error(body.message || (response.status === 401 ? "登录后就能开始创作。" : "暂时无法完成，请稍后重试。"));
      error.status = response.status;
      error.code = body.error;
      throw error;
    }
    return body;
  }
  async function loadArtwork() {
    artworkController?.abort();
    artworkController = new AbortController();
    const controller = artworkController;
    const token = ++artworkRequest, epoch = identityEpoch;
    const current = () => token === artworkRequest && epoch === identityEpoch && $('artwork-dialog').open;
    if (artworkUrl) URL.revokeObjectURL(artworkUrl);
    artworkUrl = '';
    $('artwork-image').hidden = true;
    $('artwork-loading').hidden = false;
    $('artwork-loading').textContent = '正在加载原图…';
    $('retry-artwork').hidden = true;
    try {
      const blob = await originalImage(url(`images/${$('artwork-image').dataset.job}`), fetch, () => {
        if (current()) $('artwork-loading').textContent = '连接较慢，正在重新加载…';
      },controller.signal);
      if (!current()) return;
      artworkUrl = URL.createObjectURL(blob);
      $('artwork-image').src = artworkUrl;
      await $('artwork-image').decode();
      if (!current()) return;
      $('artwork-image').hidden = false;
      $('artwork-loading').hidden = true;
    } catch {
      if (!current()) return;
      $('artwork-loading').textContent = '原图暂时无法加载，请重试。';
      $('retry-artwork').hidden = false;
    }
  }
  function openArtwork(jobId, title) {
    artworkReturn = document.activeElement;
    $('artwork-title').textContent = title;
    $('artwork-image').dataset.job = jobId;
    $('artwork-image').alt = title;
    $('artwork-dialog').showModal();
    fitDialog();
    loadArtwork();
  }
  $('retry-artwork').onclick = loadArtwork;
  $('open-result-image').onclick = () => { if (selected) openArtwork(selected, '生成作品'); };
  function image(jobId, title, variant = 'thumb') {
    const wrap = node("button", void 0, "image-wrap image-open");
    wrap.type = "button";
    wrap.setAttribute("aria-label", `放大查看：${title}`);
    wrap.onclick = () => openArtwork(jobId,title);
    const img = node("img");
    if (variant === 'thumb') {
      img.sizes = '(max-width: 590px) calc((100vw - 44px) / 2), (max-width: 800px) calc((100vw - 92px) / 3), (max-width: 1180px) calc((100vw - 120px) / 3), 354px';
      img.srcset = `${url(`images/${jobId}/thumb`)} 384w, ${url(`images/${jobId}/preview`)} 768w`;
    }
    img.src = url(`images/${jobId}/${variant}`);
    img.alt = title;
    img.loading = "lazy";
    img.decoding = 'async';
    img.width = variant === 'preview' ? 768 : 384;
    img.height = img.width;
    img.addEventListener("error", () => {
      img.alt = "预览暂不可用，点按查看原图。";
    });
    wrap.append(img, node("span", "AI 生成", "ai-label"));
    return wrap;
  }
  function render(value) {
    if (state && value.viewer.account_id === actor && value.revision < state.revision) return;
    const nextActor = value.viewer.account_id;
    const galleryChanged = !state || JSON.stringify(value.gallery) !== JSON.stringify(state.gallery);
    const changed = !state || value.revision !== state.revision || nextActor !== actor || value.viewer.operator !== state.viewer.operator || value.awards?.length !== state.awards?.length;
    if (value.server_ms) clockOffset = Number(value.server_ms) - Date.now();
    const nextOwner=nextActor || value.viewer.guest_id || 'visitor';
    if(nextOwner!==draftOwner){
      const current=currentDraft();
      const meaningful=current.prompt.trim() || current.selected || current.title || current.pendingIntent;
      const inherited=!actor && meaningful && (nextActor || draftOwner==='visitor')?current:null;
      saveDraft();
      if(actor && actor!==nextActor){clearPrivate();notice('已切换账户，原账户草稿仍保存在本机。');}
      draftOwner=nextOwner;restoreDraft(nextOwner,inherited);ownWallKey='';
    }
    actor = nextActor;
    state = value;
    const now = Date.now() + clockOffset, ev = state.event, phase=creationPhase(ev,now);
    $("login").textContent = actor ? "账户 ↗" : "登录 ↗";
    const activityAllowed = state.activity?.generation_allowed !== false;
    $('activity-message').hidden = !state.activity?.message;
    $('activity-message').textContent = state.activity?.message || '';
    const canCreate=Boolean(actor || state.viewer.guest_id && ev.guest_generation);
    $("generate").disabled = writing || !activityAllowed || !open() || active() || state.remaining===0 || state.event_remaining===0 || !ev.provider_ready || !canCreate;
    $("generate").textContent = !activityAllowed ? '活动暂不可生成' : phase==='waiting' ? '创作尚未开始' : phase==='closed' ? '本期投稿已截止' : active() ? '正在生成，请稍等…' : state.remaining===0 ? '本期次数已用完' : state.event_remaining===0 ? '本期生成名额已用完' : !ev.provider_ready || !canCreate ? '生成服务准备中' : '生成一张图';
    $("generate").formNoValidate = false;
    $("generate").setAttribute("aria-busy", String(writing || active()));
    $("submit-entry").disabled = writing;
    $("submit-entry").textContent = writing && dialog.open ? "正在提交…" : "提交审核";
    $("credits").textContent = generationCredits(state,Boolean(actor));
    $("credits").hidden = !$("credits").textContent;
    const closed = phase==='closed';
    $("create-form").hidden = closed;
    document.querySelector('.create-section').classList.toggle('is-closed', closed);
    if(ev.name){$("event-name").textContent=ev.name;document.title=`${ev.name}｜未来社区`;}
    $('choose-upload').disabled=writing || closed;
    $('replace-upload').disabled=writing;
    document.querySelector('.upload-option').hidden=closed;
    if(ev.topic)$("event-topic").textContent=`本期主题：${ev.topic}`;
    if(ev.scope)$("event-scope").textContent=ev.scope;
    if(ev.first_person_solution)$("first-person-solution").textContent=ev.first_person_solution;
    if(ev.prize_plan)$('prize-description').textContent=ev.prize_plan;
    const date = (value,withTime=false) => new Intl.DateTimeFormat('zh-CN',{timeZone:'Asia/Shanghai',month:'2-digit',day:'2-digit',weekday:'short',...(withTime?{hour:'2-digit',minute:'2-digit',hour12:false}:{})}).format(Number(value));
    $("start-time").textContent=date(ev.opens_ms);
    $("deadline-time").textContent=date(ev.deadline_ms,true);
    $("deadline-note").textContent = `${new Intl.DateTimeFormat('zh-CN',{timeZone:'Asia/Shanghai',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',hour12:false}).format(Number(ev.deadline_ms))} 截稿`;
    $("awards-time").textContent=date(ev.awards_ms);
    $("phase").textContent = phase==='waiting' ? "即将开始" : phase==='open' && !ev.provider_ready ? "创作即将开放" : phase==='open' ? "正在征集灵感" : now < Number(ev.voting_opens_ms) ? "投稿结束 · 正在审核" : now < Number(ev.voting_closes_ms) ? "一起为灵感投票" : "本期已结束";
    const jobs = state.generations || [], completed = jobs.filter((j) => j.state === "completed");
    $("studio").hidden = closed && !jobs.length;
    const job = jobs.find((j) => ["queued", "running", "needs_reconcile"].includes(j.state)) || jobs.at(-1);
    if (followGeneration && job?.state === "completed") selected = job.id;
    if (!completed.some((j) => j.id === selected)) selected = completed.at(-1)?.id || "";
    $("result").hidden = !selected;
    if (selected && $("result-image").dataset.job !== selected) {
      $("result-image").src = url(`images/${selected}/preview`);
      $("result-image").dataset.job = selected;
    }
    $("choose").disabled = writing || !open() || !activityAllowed;
    $("choose").firstChild.textContent = closed ? '投稿已截止 ' : phase==='waiting' ? '投稿尚未开始 ' : '用这张参赛 ';
    $('result-note').textContent = closed ? '本期投稿已截止，仍可保存自己的图片。' : '先看看喜不喜欢，再决定是否公开参赛。';
    $("empty-preview").hidden = Boolean(selected || job);
    $("result-panel").classList.toggle("is-empty", !selected && !job);
    $("job-status").hidden = !job || job.state === "completed";
    $("job-status").textContent = generationStatus(job, now, state.activity);
    $("job-status").dataset.active = String(["queued", "running"].includes(job?.state));
    if (followGeneration && job && !["queued", "running"].includes(job.state)) {
      followGeneration = false;
      notice(job.state === "completed" ? "图片已生成，喜欢就用这张参赛。" : "");
      if (job.state === "completed" && window.matchMedia("(max-width: 800px)").matches && !document.activeElement?.matches("input, textarea, select")) {
        requestAnimationFrame(() => {
          $("result").focus({ preventScroll: true });
          $("result").scrollIntoView({ block: "start", behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth" });
        });
      }
    }
    const nextHistoryKey = completed.map(job => job.id).join(':');
    if (historyKey !== nextHistoryKey) $("history").replaceChildren(...completed.map((job2) => {
      const button = node("button");
      button.type = "button";
      button.setAttribute("aria-label", `查看第 ${completed.indexOf(job2) + 1} 张生成图片`);
      button.setAttribute("aria-pressed", String(job2.id === selected));
      const img = node("img");
      img.src = url(`images/${job2.id}/thumb`);
      img.loading = 'lazy';
      img.decoding = 'async';
      img.alt = "";
      button.append(img);
      button.dataset.job = job2.id;
      button.onclick = () => {
        selected = job2.id;
        saveDraft();
        render(state);
      };
      return button;
    }));
    historyKey = nextHistoryKey;
    $("history").querySelectorAll("button").forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.job === selected)));
    const entry = [...state.entries || []].reverse().find((e) => e.state !== "superseded");
    $("my-entry").hidden = !entry;
    $("my-entry").replaceChildren();
    if (entry) {
      const info = node("div", `${entryLabels[entry.state] || entry.state} · ${entry.title}`);
      if (entry.reason) info.append(node("small", entry.reason));
      $("my-entry").append(info);
      if (entry.state === 'rejected') {
        const revise = node('button', '修改后重新投稿', 'secondary');
        revise.type = 'button';
        revise.disabled = writing || !open();
        revise.onclick = () => openSubmission(entry);
        $("my-entry").append(revise);
      }
      if (["pending", "approved"].includes(entry.state)) {
        const withdraw = node("button", "撤回投稿", "text-button");
        withdraw.type = "button";
        withdraw.onclick = () => perform("withdraw", { entry_id: entry.id });
        $("my-entry").append(withdraw);
      }
    }
    const gallery = state.gallery || [];
    if ($("artwork-dialog").open && ![...gallery.map(e => e.generation_id), ...jobs.map(j => j.id), ...(state.review_queue || []).map(item => item.generation.id)].includes($("artwork-image").dataset.job)) {
      $("artwork-dialog").close();
      $("artwork-image").removeAttribute("src");
    }
    $("gallery-empty").hidden = gallery.length > 0;
    $("vote-note").hidden = !gallery.length && !state.voting_url;
    if (galleryChanged) $("gallery-grid").replaceChildren(...gallery.map((entry2) => {
      const card = node("article", void 0, "gallery-card");
      card.dataset.entryId=entry2.id;card.tabIndex=-1;
      card.append(image(entry2.generation_id, entry2.title), node("h3", entry2.title), node("p", `${entry2.display_name} · 作品 ${entry2.id.slice(0, 8)}`));
      const cast = node('button', '', 'secondary gallery-vote');
      cast.type = 'button'; cast.dataset.voteEntry = entry2.id; cast.hidden = true;
      cast.onclick = () => perform('vote', {entry_id:entry2.id,intent:crypto.randomUUID()}, 'vote-feedback');
      card.append(cast);
      const share=node('button','分享作品','text-button');share.type='button';share.onclick=()=>sharing.open(entry2.id);card.append(share);
      const remove = node('button','撤下作品','text-button');
      remove.type='button';remove.dataset.disqualifyEntry=entry2.id;remove.hidden=true;
      remove.onclick=()=>{
        disqualifyEntry=entry2.id;$('disqualify-work').textContent=entry2.title;
        $('disqualify-reason').value='';notice('',false,'disqualify-notice');
        $('disqualify-dialog').showModal();fitDialog();$('disqualify-reason').focus();
      };
      card.append(remove);
      return card;
    }));
    const vote = state.voting_url;
    $("vote").hidden = !vote;
    $("vote").textContent=state.voting_preview ? "预览投票页（不计票） ↗" : "为喜欢的作品投一票 ↗";
    if (vote) $("vote").href = vote;
    $("vote-note").textContent = now >= Number(ev.voting_opens_ms) && now < Number(ev.voting_closes_ms) ? vote ? state.voting_preview ? "作品名单已锁定。当前为投票预览，不记录票数；正式投票入口稍后公布。" : "作品名单已锁定。到腾讯文档，为喜欢的灵感加油。" : "投票入口正在准备，主办配置后会出现在这里。" : "过审作品会出现在这里。投票开放后，可以为喜欢的作品加油。";
    renderVoting();
    $("awards").hidden = !state.awards?.length;
    $("awards").replaceChildren(...(state.awards || []).map((award) => {
      const entry2 = gallery.find((e) => e.id === award.entry_id);
      const card=node('article',undefined,`award-card award-${award.prize}`);
      const art=node('i',undefined,`prize-mini prize-${({creative:'figure',popular:'tote',coffee:'coffee'})[award.prize] || 'coffee'}`);art.setAttribute('aria-hidden','true');
      const text=node('div');text.append(node('span',prizeLabels[award.prize],'fine-print'),node('h3',entry2?.title || '作品已撤回'));
      if(entry2)text.append(node('p',entry2.display_name));
      text.append(node('p',award.reason));card.append(art,text);return card;
    }));
    if (changed) renderHost();
    renderHostControls();
    renderOwnWall();
    sharing.update();
    if(sharedTarget && !sharedTargetHandled){
      sharedTargetHandled=true;showWall('public');
      const target=[...$('gallery-grid').children].find(card=>card.dataset.entryId===sharedTarget);
      if(target){target.scrollIntoView({block:'center',behavior:'instant'});target.focus({preventScroll:true});}
      else notice('这件作品暂不可公开展示，可以看看其他作品。',false,'vote-feedback');
    }
  }
  function showWall(value){wall=value;if(state)renderOwnWall();}
  $('wall-public').onclick=()=>showWall('public');
  $('wall-mine').onclick=()=>showWall('mine');
  function renderOwnWall(){
    const mine=wall==='mine' || wall==='auto' && Boolean(state.generations?.length);
    $('wall-public').setAttribute('aria-pressed',String(!mine));$('wall-mine').setAttribute('aria-pressed',String(mine));
    $('gallery-grid').hidden=mine;$('gallery-empty').hidden=mine || Boolean(state.gallery.length);
    $('own-wall').hidden=!mine;
    $('own-wall-tools').hidden=!mine || !actor || !state.entries?.length || !claimGroup(state.event,Date.now()+clockOffset);
    $('vote-note').hidden=mine || !state.gallery.length && !state.voting_url;
    if(mine)$('my-entry').hidden=true;
    const works=personalWorks(state), jobs=works.map(item=>item.job);
    $('own-wall-empty').hidden=!mine || jobs.length>0;
    $('own-wall-empty').textContent='生成或上传的作品会保存在这里，投稿后可以查看审核状态。';
    const key=JSON.stringify([jobs,state.entries,state.gallery,writing,open(),actor]);
    if(key===ownWallKey)return;ownWallKey=key;
    $('own-wall').replaceChildren(...works.map(({job,entry})=>{
      const card=node('article',undefined,'gallery-card own-work');
      const title=entry?.title || (job.source==='upload'?'上传的作品':'我的创作');
      const status=entry?entryLabels[entry.state] || entry.state:'未投稿';
      const preview=image(job.id,title);
      preview.setAttribute('aria-label',`查看${title}原图，状态：${status}`);
      preview.append(node('span',status,`entry-status state-${entry?.state || 'draft'}`));
      card.append(preview);
      card.append(node('h3',entry?.title || (job.source==='upload'?'上传的作品':'未命名作品')));
      if(entry?.reason)card.append(node('p',entry.reason,'review-reason'));
      const controls=node('div',undefined,'own-work-actions');
      if(entry && shareableEntry(state,entry.id)){
        const share=node('button','分享作品','secondary');share.type='button';share.onclick=()=>sharing.open(entry.id);controls.append(share);
      }
      if(!entry || !['pending','approved','disqualified'].includes(entry.state)){
        const submit=node('button',entry?.state==='rejected'?'修改后重新投稿':'用这张参赛','secondary');submit.type='button';submit.disabled=writing || !open();
        submit.onclick=()=>{selected=job.id;saveDraft();if(!actor){afterAuth='submit';auth.open();}else openSubmission(entry || null);};controls.append(submit);
      }
      if(entry && ['pending','approved'].includes(entry.state)){
        const withdraw=node('button','撤回参赛','text-button');withdraw.type='button';withdraw.disabled=writing;
        withdraw.onclick=()=>perform('withdraw',{entry_id:entry.id},'vote-feedback');controls.append(withdraw);
      }
      card.append(controls);return card;
    }));
  }
  function renderVoting() {
    const voting = state.voting, builtin = voting?.mode === 'builtin';
    $('leaderboard').hidden = !builtin || voting.phase === 'waiting';
    $('cancel-vote').hidden = !builtin || !actor || !voting.my_entry_id || voting.phase !== 'open';
    $('cancel-vote').disabled = writing;
    const own = new Set((state.entries || []).map(entry => entry.id));
    const counts = new Map((voting?.counts || []).map(row => [row.entry_id,row]));
    $('gallery-grid').querySelectorAll('[data-vote-entry]').forEach(button => {
      const id = button.dataset.voteEntry, count = counts.get(id), chosen = voting?.my_entry_id === id;
      button.hidden = !builtin || voting.phase === 'waiting';
      button.setAttribute('aria-pressed', String(chosen));
      button.disabled = writing || voting?.phase !== 'open' || own.has(id) || count?.eligible === false || Boolean(actor && !voting.can_vote);
      button.textContent = voting?.phase === 'closed' ? `${count?.votes || 0} 票 · 已封榜` : `${own.has(id) ? '你的作品' : chosen ? '已投这张' : actor ? '投给这张' : '登录后投票'} · ${count?.votes || 0} 票`;
      if (!actor && builtin && voting.phase === 'open') button.disabled = writing;
    });
    if (!builtin) return;
    $('vote').hidden = voting.phase === 'waiting';
    $('vote').href = voting.phase === 'closed' ? '#leaderboard' : '#gallery';
    $('vote').removeAttribute('target');
    $('vote').textContent = voting.phase === 'closed' ? '查看封榜结果' : '为喜欢的作品投票';
    $('vote-note').hidden = voting.phase==='waiting' && !state.gallery.length;
    $('vote-note').textContent = voting.phase === 'waiting' ? '审核通过的作品将在投票开始时锁定名单。' : voting.phase === 'open' ? (voting.rules || '每个账户一张选票，可以改投或撤回，不能投给自己。') : `投票已结束，结果已按截止时的有效选票封榜。${(voting.counts || []).some(row=>!row.eligible)?'已撤回或下架的作品不再展示，封榜总票数保留历史记录。':''}`;
    $('voting-rules').textContent = `${voting.rules || '每个账户一张选票，可以改投或撤回，不能投给自己。'} 活动时间均为北京时间。`;
    $('tally-status').textContent = voting.settled ? `${voting.total_votes} 张截止时有效票 · 已封榜` : `${voting.total_votes} 张有效票 · 每 4 秒更新`;
    $('vote-version').textContent = `名单版本 ${voting.roster_version || 0} · ${voting.roster_digest || '尚未锁定'}${voting.settled ? `\n结算版本 ${voting.settlement_version} · ${voting.settlement_digest}` : ''}`;
    const rows = votingRows(state), key = JSON.stringify(rows);
    if (key !== rankingKey) {
      rankingKey = key;
      $('leaderboard-list').replaceChildren(...rows.map(row => {
        const li=node('li',undefined,'ranking-row'), work=node('button',undefined,'ranking-work'), title=node('span',row.title);
        const entry=state.gallery.find(entry=>entry.id===row.entry_id);
        work.type='button';
        work.dataset.rankingEntry=row.entry_id;
        work.setAttribute('aria-label',`查看榜单作品：${row.title}`);
        if (entry) {
          const thumb=node('img',undefined,'ranking-thumb');
          thumb.src=url(`images/${entry.generation_id}/thumb`);
          thumb.alt=''; thumb.width=48; thumb.height=48; thumb.loading='lazy'; thumb.decoding='async';
          work.append(thumb);
          work.onclick=()=>openArtwork(entry.generation_id,row.title);
        }
        if (row.display_name) title.append(node('small',row.display_name));
        work.append(title);
        li.append(node('strong',String(row.rank)),work,node('strong',`${row.votes} 票`));
        return li;
      }));
    }
  }
  function renderHostControls() {
    const manager = state.viewer.operator && state.activity?.management_allowed !== false;
    $("moderation").hidden = !manager;
    $("host-shortcut").hidden = !manager;
    $('gallery-grid').querySelectorAll('[data-disqualify-entry]').forEach(button=>{button.hidden=!manager;button.disabled=writing;});
    $('confirm-disqualify').disabled=writing;
    $('close-disqualify').disabled=writing;
    if (!manager) { if($('disqualify-dialog').open)$('disqualify-dialog').close(); return; }
    $("host-shortcut").textContent = state.review_queue.length ? `审核投稿 · ${state.review_queue.length} 条待审` : '管理活动';
    const votingLocked = Date.now() + clockOffset >= Number(state.event.voting_opens_ms);
    const builtin = state.voting?.mode === 'builtin';
    $('award-form').hidden = builtin;
    $('ranked-awards').hidden = !builtin;
    $('ranked-awards-note').textContent = state.ranked_awards?.message || '投票截止后，按有效票数确定一、二、三等奖。';
    $('publish-ranked-results').disabled = writing || !state.ranked_awards?.ready;
    $('publish-ranked-results').hidden = Boolean(state.awards?.length);
    $('ranked-awards-list').replaceChildren(...(state.ranked_awards?.candidates || []).map(award=>{
      const entry=state.gallery.find(entry=>entry.id===award.entry_id);
      return node('p',`${prizeLabels[award.prize]}：${entry?.title || '作品状态已变化'} · ${award.reason}`);
    }));
    $('voting-form').hidden = builtin;
    $('settlement-export').hidden = !builtin;
    $('settlement-export').disabled = writing || state.voting?.phase !== 'closed';
    $("voting-url").disabled = votingLocked;
    $("voting-form").querySelector('button[type="submit"]').disabled = votingLocked || writing;
    $("voting-preview").disabled = votingLocked || writing;
    $("voting-config-note").hidden = !votingLocked;
    $('voting-config-note').textContent = builtin ? '投票名单已锁定，投票结束后可导出结算快照。' : '投票已开始，投票入口和批准名单已锁定。';
    $("record-award").disabled = writing || Date.now() + clockOffset < Number(state.event.voting_closes_ms) || !state.gallery.length;
    $("publish-results").disabled = writing || Date.now() + clockOffset < Number(state.event.awards_ms) || state.award_drafts?.length !== 3 || Boolean(state.awards?.length);
    $("review-queue").querySelectorAll('[data-review-action]').forEach(button => {
      button.disabled = writing || button.dataset.reviewAction === 'approve' && (button.dataset.author === actor || votingLocked);
    });
  }
  function renderHost() {
    if (!state.viewer.operator) return;
    if (!votingDirty) $("voting-url").value = state.configured_voting_url === "preview" ? "" : state.configured_voting_url || "";
    const pending = new Set(state.review_queue.map((item) => item.entry.id));
    for (const id of reviewDrafts.keys()) if (!pending.has(id)) reviewDrafts.delete(id);
    for (const id of reviewReturns) if (!pending.has(id)) reviewReturns.delete(id);
    const key=JSON.stringify([state.review_queue,state.reconcile_queue,state.award_drafts,state.gallery]);
    if (key === reviewKey) return;
    reviewKey=key;
    const focused=document.activeElement, focusedCard=focused?.closest('[data-review-entry]');
    const focusedId=focusedCard?.dataset.reviewEntry;
    const focusReason=focused?.tagName==='TEXTAREA', caret=focusReason ? [focused.selectionStart,focused.selectionEnd] : null;
    $("review-queue").replaceChildren(...state.review_queue.map(({ entry, generation }) => {
      const card = node("article", void 0, "review-card");
      card.dataset.reviewEntry=entry.id;
      card.append(image(generation.id, entry.title, 'preview'), node("h3", entry.title), node("p", entry.display_name));
      const details = node("details");
      details.append(node("summary", "查看提示词"), node("p", generation.prompt));
      card.append(details);
      const reason = node("textarea");
      reason.placeholder = "退回时，请写一句可操作的修改建议";
      reason.maxLength = 1e3;
      reason.setAttribute("aria-label", `${entry.title} 的审核意见`);
      reason.value = reviewDrafts.get(entry.id) || "";
      reason.oninput = () => reviewDrafts.set(entry.id, reason.value);
      const returnForm=node('form',undefined,'review-return');
      returnForm.hidden=!reviewReturns.has(entry.id);
      returnForm.id=`review-return-${entry.id}`;
      reason.required=true;
      const reasonLabel=node('label','修改建议');
      reason.id=`review-reason-${entry.id}`;
      reasonLabel.htmlFor=reason.id;
      const localNotice=node('p',undefined,'notice');
      localNotice.id=`review-notice-${entry.id}`;
      localNotice.setAttribute('role','status');
      const controls=node('div',undefined,'review-actions');
      for (const [action, label] of [["approve", "批准展示"], ["reject", "退回修改"]]) {
        const button = node("button", action==='approve' ? '批准参赛' : label, action==='approve' ? 'primary' : 'secondary');
        button.type = "button";
        button.dataset.reviewAction = action;
        button.dataset.author = entry.actor;
        button.disabled = writing || action === "approve" && (entry.actor === actor || Date.now() + clockOffset >= Number(state.event.voting_opens_ms));
        button.onclick = async () => {
          if(action==='reject') {
            reviewReturns.add(entry.id); returnForm.hidden=false;
            button.setAttribute('aria-expanded','true'); reason.focus(); return;
          }
          const next=card.nextElementSibling?.dataset.reviewEntry;
          button.textContent='正在批准…';
          if(await perform(action,{entry_id:entry.id},localNotice.id)) focusNextReview(next);
          else if(button.isConnected) button.textContent='批准参赛';
        };
        if(action==='reject') {
          button.setAttribute('aria-expanded',String(!returnForm.hidden));
          button.setAttribute('aria-controls',returnForm.id);
        }
        controls.append(button);
      }
      const confirm=node('button','确认退回','secondary'), cancel=node('button','取消','text-button');
      confirm.type='submit'; confirm.dataset.reviewAction='reject';
      cancel.type='button'; cancel.onclick=()=>{
        reviewReturns.delete(entry.id); returnForm.hidden=true;
        const toggle=controls.querySelector('[data-review-action="reject"]');
        toggle.setAttribute('aria-expanded','false'); toggle.focus({preventScroll:true});
      };
      returnForm.onsubmit=async event=>{
        event.preventDefault();
        if(!reason.value.trim()) { reason.setCustomValidity('请写一句可操作的修改建议。'); reason.reportValidity(); return; }
        reason.setCustomValidity('');
        const next=card.nextElementSibling?.dataset.reviewEntry;
        confirm.textContent='正在退回…';
        if(await perform('reject',{entry_id:entry.id,reason:reason.value},localNotice.id)) focusNextReview(next);
        else if(confirm.isConnected) confirm.textContent='确认退回';
      };
      reason.addEventListener('input',()=>reason.setCustomValidity(''));
      returnForm.append(reasonLabel,reason,confirm,cancel);
      card.append(controls,returnForm,localNotice);
      return card;
    }));
    if (!state.review_queue.length) $("review-queue").append(node("p", "暂时没有待审投稿。", "fine-print"));
    for (const job of state.reconcile_queue || []) {
      const card = node("article", void 0, "review-card");
      card.append(node("h3", "生成需要核对"), node("p", `任务 ${job.id}`), node("p", job.reason));
      const reason = node("input");
      reason.placeholder = "模型服务核对记录或结果";
      reason.maxLength = 1e3;
      reason.setAttribute("aria-label", "生成核对记录");
      const label = node("label", "已在模型服务核实没有输出，且任务已结束");
      const check = node("input");
      check.type = "checkbox";
      label.prepend(check);
      const button = node("button", "确认未完成，退回次数", "secondary");
      button.type = "button";
      button.disabled = true;
      check.onchange = () => {
        button.disabled = !check.checked;
      };
      button.onclick = () => perform("resolve-failed", { generation_id: job.id, confirmed_no_output: check.checked, reason: reason.value });
      card.append(reason, label, button);
      $("review-queue").append(card);
    }
    for (const award of state.award_drafts || []) {
      const entry = state.gallery.find((e) => e.id === award.entry_id);
      $("review-queue").append(node("p", `已记录 ${prizeLabels[award.prize]}：${entry?.title || "作品已撤回"} · ${award.reason}`, "fine-print"));
    }
    const previous = $("award-entry").value;
    $("award-entry").replaceChildren(...state.gallery.map((entry) => {
      const option = node("option", `${entry.title} / ${entry.display_name}`);
      option.value = entry.id;
      return option;
    }));
    if (state.gallery.some((e) => e.id === previous)) $("award-entry").value = previous;
    if(focusedId) {
      const card=document.querySelector(`[data-review-entry="${focusedId}"]`);
      const target=card?.querySelector(focusReason ? 'textarea' : '[data-review-action="approve"]');
      target?.focus({preventScroll:true});
      if(caret) target?.setSelectionRange(...caret);
    }
  }
  function focusNextReview(id) {
    const card=(id && document.querySelector(`[data-review-entry="${id}"]`)) || $('review-queue').querySelector('[data-review-entry]');
    const next=card?.querySelector('[data-review-action="approve"]') || $('refresh');
    next.focus({preventScroll:true});
    if(card) {
      const rect=card.getBoundingClientRect();
      if(rect.top<0 || rect.top>innerHeight-100) card.scrollIntoView({block:'start',behavior:'instant'});
    }
  }
  async function refresh() {
    if (refreshing || writing) return;
    const epoch = identityEpoch;
    refreshing = true;
    try {
      let value;
      try {
        value = await request("mine");
      } catch (error) {
        if (error.status !== 401) throw error;
        value = await request("guest");
      }
      if (epoch === identityEpoch) {
        render(value);
        if (refreshError) notice('');
      }
    } catch (error) {
      notice(error.message, true);
      refreshError = error.message;
      if(!state)$('phase').textContent='活动暂未载入';
    } finally {
      refreshing = false;
    }
  }
  async function perform(action, payload, target = "notice") {
    if (target === "notice" && ["approve","reject","set-voting-url","award","publish-results","resolve-failed"].includes(action)) target="host-notice";
    if (writing) return false;
    if (!actor && !(action==='generate' && state?.viewer.guest_id && state.event.guest_generation)) {
      saveDraft();
      auth.open();
      return false;
    }
    writing = true;
    $("generate").disabled = true;
    if (action === 'generate') $("generate").textContent = '正在提交灵感…';
    $("generate").setAttribute("aria-busy", "true");
    renderHostControls();
    renderVoting();
    renderOwnWall();
    $('choose').disabled=true;
    $("submit-entry").disabled = true;
    if (dialog.open) $("submit-entry").textContent = "正在提交…";
    try {
      const value = await request("actions", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action, payload, expected_actor_id: actor }) });
      writing = false;
      if (action === "set-voting-url") votingDirty = false;
      render(value);
      notice(action === "generate" ? "灵感已加入队列，可以留在这里等它画好。" : action === "submit" ? "投稿已收到，可在“我的作品”查看审核状态。" : action === 'vote' ? '选票已保存，截止前可以改投。' : action === 'cancel-vote' ? '选票已撤回。' : "已保存。", false, target);
      return true;
    } catch (error) {
      notice(error.message, true, target);
      if (error.code === "identity_changed" || error.status === 401) {
        saveDraft();
        identityEpoch += 1;
        clearPrivate();
        actor = "";
        state = null;
        setTimeout(refresh, 0);
      }
      return false;
    } finally {
      writing = false;
      if (state) render(state);
    }
  }
  $("prompt").addEventListener("input", () => {
    $("prompt-count").textContent = `${$("prompt").value.length} / 2000`;
    document.querySelectorAll("[data-prompt]").forEach(button => button.setAttribute("aria-pressed", String(button.dataset.prompt === $("prompt").value)));
    pendingIntent = null;
    saveDraft();
  });
  document.querySelectorAll("[data-prompt]").forEach((button) => button.onclick = () => {
    $("prompt").value = button.dataset.prompt;
    $("prompt").dispatchEvent(new Event("input"));
  });
  $("create-form").onsubmit = async (event) => {
    event.preventDefault();
    const prompt = generationPrompt($("prompt").value);
    if (!$("prompt").value.trim()) {
      $('prompt').value=prompt;
      $('prompt').dispatchEvent(new Event('input'));
    }
    $("prompt").blur();
    followGeneration = true;
    if (!pendingIntent || pendingIntent.prompt !== prompt) pendingIntent = { prompt, intent: crypto.randomUUID() };
    saveDraft();
    if (await perform("generate", pendingIntent)) pendingIntent = null;
    else followGeneration = false;
    saveDraft();
  };
  function openSubmission(entry = null) {
    if (entry) {
      selected = entry.generation_id;
      render(state);
      $("entry-title").value = entry.title;
      $("display-name").value = entry.display_name;
      titleJob=selected;titleAuto=false;
    }
    if(!$('entry-title').value.trim() || titleAuto && titleJob!==selected){
      $('entry-title').value=suggestedTitle(state.generations.find(job=>job.id===selected)?.prompt || '',0);
      titleAuto=true;
    }
    titleJob=selected;
    const owner=actor,epoch=identityEpoch,before=$('display-name').value;
    if(!before)drafts.readNickname(owner).then(name=>{
      if(owner===actor && epoch===identityEpoch && !$('display-name').value && name){$('display-name').value=name;saveDraft();}
    });
    saveDraft();
    $("consent").checked = false;
    notice("", false, "submit-notice");
    $("submit-dialog").showModal();
    fitDialog();
    $("entry-title").focus();
  }
  $("choose").onclick = () => {saveDraft();if(!actor){afterAuth='submit';auth.open();}else openSubmission();};
  $('entry-title').addEventListener('input',()=>{titleAuto=false;saveDraft();});
  $('display-name').addEventListener('input',()=>{drafts.writeNickname(actor,$('display-name').value);saveDraft();});
  $('suggest-title').onclick=()=>{
    $('entry-title').value=suggestedTitle(state.generations.find(job=>job.id===selected)?.prompt || '',++titleVariant);titleAuto=true;titleJob=selected;saveDraft();
  };
  async function sendUpload(){
    if(!uploadDraft || writing)return;
    if(!actor){afterAuth='upload';auth.open();return;}
    const draft=uploadDraft, owner=draftOwner, epoch=identityEpoch;
    writing=true;$('choose-upload').textContent='正在检查并上传…';$('choose-upload').disabled=true;
    notice('正在上传并检查图片，请稍等。',false,'upload-notice');
    if(state)render(state);
    try{
      const data=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result.split(',')[1]);reader.onerror=()=>reject(new Error('无法读取图片，请重新选择。'));reader.readAsDataURL(draft.file);});
      const value=await request('uploads',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({expected_actor_id:actor,filename:draft.name,content_type:draft.type,intent:draft.intent,data_base64:data})});
      if(owner!==draftOwner || epoch!==identityEpoch)return;
      writing=false;uploadDraft=null;await drafts.writeFile(owner,null);render(value);
      const job=state.generations.find(j=>j.intent===draft.intent) || state.generations.at(-1);
      if(job)selected=job.id;
      saveDraft();render(state);showWall('mine');
      notice('图片已通过文件安全检查并保存。点击“用这张参赛”提交内容审核。',false,'upload-notice');
      $('choose-upload').textContent='上传其他 AI 创作的作品';
      $('replace-upload').hidden=true;
    }catch(error){if(owner===draftOwner && epoch===identityEpoch){notice(error.message || '连接中断，已保留所选图片，可继续上传。',true,'upload-notice');$('choose-upload').textContent='继续上传已选作品';}}
    finally{writing=false;if(state)render(state);}
  }
  $('choose-upload').onclick=()=>{saveDraft();if(!actor){afterAuth='upload';auth.open();}else if(uploadDraft)sendUpload();else $('upload-file').click();};
  $('replace-upload').onclick=()=>{if(actor && !writing)$('upload-file').click();};
  $('upload-file').onchange=async()=>{
    const file=$('upload-file').files?.[0];if(!file)return;
    const match=file.name.toLowerCase().match(/\.(png|jpe?g|webp)$/);
    const type=match?.[1]==='png'?'image/png':match?.[1]==='webp'?'image/webp':'image/jpeg';
    if(!match || file.size<32 || file.size>8*1024*1024 || file.type && file.type!==type){notice('请选择 8 MB 以内的 PNG、JPG 或静态 WebP 图片。',true,'upload-notice');$('upload-file').value='';return;}
    uploadDraft={file,name:file.name,type,intent:crypto.randomUUID()};
    $('replace-upload').hidden=false;
    await drafts.writeFile(draftOwner,uploadDraft);saveDraft();await sendUpload();$('upload-file').value='';
  };
  $("close-dialog").onclick = () => $("submit-dialog").close();
  $("close-artwork").onclick = () => $("artwork-dialog").close();
  $('artwork-dialog').addEventListener('close', () => {
    artworkController?.abort();
    artworkController = null;
    artworkRequest++;
    if (artworkUrl) URL.revokeObjectURL(artworkUrl);
    artworkUrl = '';
    $('artwork-image').removeAttribute('src');
    const target=artworkReturn?.isConnected ? artworkReturn : artworkReturn?.dataset.rankingEntry ? document.querySelector(`[data-ranking-entry="${artworkReturn.dataset.rankingEntry}"]`) : null;
    if(target?.getClientRects().length) target.focus({preventScroll:true});
    artworkReturn=null;
  });
  $('close-disqualify').onclick=()=>$('disqualify-dialog').close();
  $('disqualify-dialog').addEventListener('cancel',event=>{if(writing)event.preventDefault();});
  $('disqualify-form').onsubmit=async event=>{
    event.preventDefault();const reason=$('disqualify-reason').value.trim();
    if(!reason){notice('请填写撤下作品的原因。',true,'disqualify-notice');$('disqualify-reason').focus();return;}
    if(await perform('disqualify',{entry_id:disqualifyEntry,reason},'disqualify-notice')){$('disqualify-dialog').close();notice('作品已撤下。',false,'vote-feedback');}
  };
  $("submit-form").onsubmit = async (event) => {
    event.preventDefault();
    if (await perform("submit", { generation_id: selected, title: $("entry-title").value, display_name: $("display-name").value, consent: $("consent").checked }, "submit-notice")) {
      drafts.writeNickname(actor,$('display-name').value);saveDraft();
      $("submit-dialog").close();
      showWall('mine');
      notice("投稿成功，可在“我的作品”查看审核状态。",false,'vote-feedback');
      $('gallery').scrollIntoView({block:'start',behavior:'instant'});
      claim.open(state.event,true);
    }
  };
  $("voting-form").onsubmit = (event) => {
    event.preventDefault();
    perform("set-voting-url", { url: $("voting-url").value });
  };
  $("voting-url").oninput = () => {
    votingDirty = true;
  };
  $("voting-preview").onclick = () => perform("set-voting-url", { url: "preview" });
  $("award-form").onsubmit = (event) => {
    event.preventDefault();
    perform("award", { entry_id: $("award-entry").value, prize: $("prize").value, reason: $("award-reason").value });
  };
  $("publish-results").onclick = () => perform("publish-results", {});
  $('publish-ranked-results').onclick = () => perform('publish-results',{});
  $('cancel-vote').onclick = () => perform('cancel-vote',{intent:crypto.randomUUID()},'vote-feedback');
  $('settlement-export').onclick = async () => {
    if (writing || !actor) return;
    writing = true; renderHostControls();
    try {
      const value = await request('actions',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'settlement',payload:{},expected_actor_id:actor})});
      if (!value.settlement) throw new Error('结算尚未完成，请刷新后重试。');
      saveBlob(new Blob([JSON.stringify(value.settlement,null,2)],{type:'application/json'}),`活动结算-${value.settlement.version}.json`);
      notice('已导出服务端结算快照。',false,'host-notice');
    } catch(error) { notice(error.message,true,'host-notice'); }
    finally { writing=false; renderHostControls(); }
  };
  $("refresh").onclick = refresh;
  document.querySelector('a[href="#about"]').addEventListener("click", () => { $("about").open = true; });
  function revealDetailsTarget() {
    if (!["#about", "#inspiration"].includes(location.hash)) return;
    $("about").open = true;
    if (location.hash === "#inspiration") $("inspiration").open = true;
    document.querySelector(location.hash)?.scrollIntoView({ block: "start" });
  }
  window.addEventListener("hashchange", revealDetailsTarget);
  revealDetailsTarget();
  function saveBlob(blob, name) {
    const link = node("a");
    link.href = URL.createObjectURL(blob);
    link.download = name;
    link.click();
    setTimeout(() => URL.revokeObjectURL(link.href), 1e3);
  }
  $("export").onclick = () => {
    const rows = [["作品编号", "作品名", "展示昵称", "图片 SHA256", "图片链接"], ...state.gallery.map((e) => [e.id, e.title, e.display_name, e.sha256, url(`images/${e.generation_id}`)])];
    saveBlob(new Blob(["\uFEFF" + rows.map((row) => row.map(csvCell).join(",")).join("\r\n")], { type: "text/csv;charset=utf-8" }), "半醒咖啡-过审作品.csv");
  };
  $("download").onclick = async () => {
    if (!selected || $('download').disabled) return;
    const downloadJob = selected, downloadActor = actor, downloadEpoch = identityEpoch;
    const controller = new AbortController();
    downloadController = controller;
    $('download').disabled = true;
    $('download').textContent = '正在保存…';
    let source;
    try {
      const blob = await originalImage(url(`images/${downloadJob}`), fetch, () => { if (downloadActor === actor && downloadEpoch === identityEpoch) $('download').textContent = '正在重试…'; },controller.signal);
      source = URL.createObjectURL(blob);
      const img = new Image();
      img.src = source;
      await img.decode();
      if (downloadActor !== actor || downloadEpoch !== identityEpoch) return;
      const canvas = document.createElement("canvas");
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight + 60;
      const ctx = canvas.getContext("2d");
      ctx.fillStyle = "#f7f4e9";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, 0, 0);
      ctx.fillStyle = "#243e32";
      ctx.font = "22px sans-serif";
      ctx.fillText("AI 生成 · 半醒咖啡每周创作", 24, canvas.height - 22);
      const labeledBlob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
      if (!labeledBlob) throw new Error("无法保存图片");
      if (downloadActor !== actor || downloadEpoch !== identityEpoch) return;
      saveBlob(new Blob([labelPng(new Uint8Array(await labeledBlob.arrayBuffer()), downloadJob)], { type: "image/png" }), `半醒咖啡-AI生成-${downloadJob.slice(0, 8)}.png`);
    } catch {
      if (downloadActor === actor && downloadEpoch === identityEpoch) notice("原图暂时无法保存，请重试。", true);
    } finally {
      if (source) URL.revokeObjectURL(source);
      if (downloadController === controller) {
        downloadController = null;
        $('download').disabled = false;
        $('download').textContent = '保存图片 ↓';
      }
    }
  };
  async function poll() {
    clearTimeout(timer);
    if (!document.hidden) await refresh();
    timer = setTimeout(poll, (active() || state?.voting?.mode === 'builtin' && state.voting.phase === 'open' ? 4e3 : 15e3) + Math.floor(Math.random() * 1000));
  }
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden) poll();
  });
  window.addEventListener("focus", refresh);
  window.addEventListener('offline',()=>{saveDraft();notice('网络已断开，提示词和已保存的作品会保留。恢复连接后会核对任务进度。',true);});
  window.addEventListener('online',()=>{notice('网络已恢复，正在核对任务和作品…');refresh();});
  window.addEventListener("pagehide", () => {saveDraft();clearTimeout(timer);});
  initialDraft.finally(poll);
}
export {
  creationPhase,
  generationCredits,
  generationStatus,
  originalImage,
  creativeEndpoint,
  votingRows,
  csvCell,
  jobLabels,
  labelPng
};
