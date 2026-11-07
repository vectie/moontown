import { coffeeAuth } from './coffee-auth.js';
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
  if(value.event_remaining===0)return '本期生成名额已用完 · 已生成图片仍可投稿';
  const personal=signedIn?value.remaining:value.event.participant_quota;
  const remaining=Number.isFinite(value.event_remaining)?Math.min(personal,value.event_remaining):personal;
  return signedIn?`本期还可生成 ${remaining} 张 · 投稿前仅自己可见`:`本期最多可生成 ${remaining} 张 · 投稿前仅自己可见`;
}
const jobLabels = Object.freeze({
  queued: "已经排好队，轮到你就开始画。",
  running: "正在把想象画出来，请稍等。离开页面也不会丢失任务。",
  needs_reconcile: "这次生成需要主办核对。我们会保留记录，不会自动重复生成。",
  failed: "这次没有完成，次数已退回。可以再试一次。"
});
const entryLabels = Object.freeze({ pending: "等待审核", approved: "已进入作品墙", rejected: "需要调整后重新投稿", superseded: "已被新版替换", withdrawn: "已撤回", disqualified:'已下架' });
const prizeLabels = Object.freeze({ creative: "创意惊喜 · 手办", popular: "人气灵感 · 帆布包", coffee: "咖啡共鸣 · 特调" });
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
  let votingDirty = false, followGeneration = false, identityEpoch = 0;
  let rankingKey = '';
  let disqualifyEntry = '';
  const dialog = $("submit-dialog");
  function fitDialog() {
    const viewport = window.visualViewport;
    const height = viewport?.height || window.innerHeight;
    document.querySelectorAll('dialog[open]').forEach(openDialog => {
      openDialog.style.setProperty("--dialog-height", `${height}px`);
      openDialog.style.setProperty("--dialog-center", `${(viewport?.offsetTop || 0) + height / 2}px`);
    });
  }
  const auth = coffeeAuth({ loginUrl: $("login").href, fitDialog, onSignedIn: async () => {
    identityEpoch += 1;
    render(await request('mine'));
    if (!actor) throw new Error('登录状态尚未确认，请重试。');
    notice(state.activity?.generation_allowed===false ? '已登录，请查看活动状态。' : open() ? '已登录，点击生成一张图继续。' : creationPhase(state.event,Date.now()+clockOffset)==='waiting' ? '已登录，征集开始后可以生成作品。' : state.voting?.phase==='open' ? '已登录，可以为喜欢的作品投票。' : '已登录，可以查看自己的投稿。');
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
    $(target).textContent = message;
    $(target).dataset.error = String(error);
  };
  const active = () => state?.generations?.some((job) => ["queued", "running", "needs_reconcile"].includes(job.state));
  const open = () => state && Date.now() + clockOffset >= Number(state.event.opens_ms) && Date.now() + clockOffset < Number(state.event.deadline_ms);
  function clearPrivate() {
    selected = "";
    pendingIntent = null;
    followGeneration = false;
    $("create-form").reset();
    $("submit-form").reset();
    $("prompt-count").textContent = "0 / 2000";
    document.querySelectorAll("[data-prompt]").forEach(button => button.setAttribute("aria-pressed", "false"));
    $("submit-dialog").close();
    $("artwork-dialog").close();
    $('disqualify-dialog').close();disqualifyEntry='';
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
    reviewDrafts.clear();
    votingDirty = false;
    $("voting-form").reset();
    $("award-form").reset();
  }
  async function request(path, options = {}) {
    const response = await fetch(url(path), { credentials: "same-origin", cache: "no-store", ...options });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      const error = new Error(body.message || (response.status === 401 ? "登录后就能开始创作。" : "暂时无法完成，请稍后重试。"));
      error.status = response.status;
      error.code = body.error;
      throw error;
    }
    return body;
  }
  function image(jobId, title) {
    const wrap = node("button", void 0, "image-wrap image-open");
    wrap.type = "button";
    wrap.setAttribute("aria-label", `放大查看：${title}`);
    wrap.onclick = () => {
      $("artwork-title").textContent = title;
      $("artwork-image").src = url(`images/${jobId}`);
      $("artwork-image").dataset.job = jobId;
      $("artwork-image").alt = title;
      $("artwork-dialog").showModal();
    };
    const img = node("img");
    img.src = url(`images/${jobId}`);
    img.alt = title;
    img.loading = "lazy";
    img.addEventListener("error", () => {
      img.alt = "图片暂时无法加载，请刷新重试。";
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
    if (actor && actor !== nextActor) {
      clearPrivate();
      notice("登录账户已变化，已刷新为当前账户。");
    }
    actor = nextActor;
    state = value;
    const now = Date.now() + clockOffset, ev = state.event, phase=creationPhase(ev,now);
    $("login").textContent = actor ? "账户 ↗" : "登录 ↗";
    const activityAllowed = state.activity?.generation_allowed !== false;
    $('activity-message').hidden = !state.activity?.message;
    $('activity-message').textContent = state.activity?.message || '';
    $("generate").disabled = writing || !activityAllowed || Boolean(actor && (!open() || active() || state.remaining === 0 || state.event_remaining === 0 || !state.event.provider_ready));
    $("generate").textContent = !activityAllowed ? '活动暂不可生成' : actor ? phase==='waiting' ? '创作尚未开始' : phase==='closed' ? "本期投稿已截止" : active() ? "正在生成，请稍等…" : state.remaining===0 ? "本期次数已用完" : state.event_remaining===0 ? "本期生成名额已用完" : !state.event.provider_ready ? "生成服务准备中" : "生成一张图" : "登录后生成";
    $("generate").formNoValidate = !actor;
    $("generate").setAttribute("aria-busy", String(writing || active()));
    $("submit-entry").disabled = writing;
    $("submit-entry").textContent = writing && dialog.open ? "正在提交…" : "提交审核";
    $("credits").textContent = generationCredits(state,Boolean(actor));
    const closed = phase==='closed';
    $("create-form").hidden = closed;
    document.querySelector('.create-section').classList.toggle('is-closed', closed);
    if(ev.name){$("event-name").textContent=ev.name;document.title=`${ev.name}｜MoonTown`;}
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
      $("result-image").src = url(`images/${selected}`);
      $("result-image").dataset.job = selected;
    }
    $("choose").disabled = writing || !open() || !activityAllowed;
    $("choose").firstChild.textContent = closed ? '投稿已截止 ' : phase==='waiting' ? '投稿尚未开始 ' : '用这张参赛 ';
    $('result-note').textContent = closed ? '本期投稿已截止，仍可保存自己的图片。' : '先看看喜不喜欢，再决定是否公开参赛。';
    $("empty-preview").hidden = Boolean(selected || job);
    $("result-panel").classList.toggle("is-empty", !selected && !job);
    $("job-status").hidden = !job || job.state === "completed";
    $("job-status").textContent = jobLabels[job?.state] || "";
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
    if (changed) $("history").replaceChildren(...completed.map((job2) => {
      const button = node("button");
      button.type = "button";
      button.setAttribute("aria-label", `查看第 ${completed.indexOf(job2) + 1} 张生成图片`);
      button.setAttribute("aria-pressed", String(job2.id === selected));
      const img = node("img");
      img.src = url(`images/${job2.id}`);
      img.alt = "";
      button.append(img);
      button.dataset.job = job2.id;
      button.onclick = () => {
        selected = job2.id;
        render(state);
      };
      return button;
    }));
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
      card.append(image(entry2.generation_id, entry2.title), node("h3", entry2.title), node("p", `${entry2.display_name} · 作品 ${entry2.id.slice(0, 8)}`));
      const cast = node('button', '', 'secondary gallery-vote');
      cast.type = 'button'; cast.dataset.voteEntry = entry2.id; cast.hidden = true;
      cast.onclick = () => perform('vote', {entry_id:entry2.id,intent:crypto.randomUUID()}, 'vote-feedback');
      card.append(cast);
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
      return node("p", `${prizeLabels[award.prize]}：${entry2?.title || "作品已撤回"}${entry2 ? ` / ${entry2.display_name}` : ""} · ${award.reason}`);
    }));
    if (changed) renderHost();
    renderHostControls();
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
        const li=node('li',undefined,'ranking-row'), title=node('span',row.title);
        if (row.display_name) title.append(node('small',row.display_name));
        li.append(node('strong',String(row.rank)),title,node('strong',`${row.votes} 票`));
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
    $("review-queue").replaceChildren(...state.review_queue.map(({ entry, generation }) => {
      const card = node("article", void 0, "review-card");
      card.append(image(generation.id, entry.title), node("h3", entry.title), node("p", entry.display_name));
      const details = node("details");
      details.append(node("summary", "查看提示词"), node("p", generation.prompt));
      card.append(details);
      const reason = node("textarea");
      reason.placeholder = "退回时，请写一句可操作的修改建议";
      reason.maxLength = 1e3;
      reason.setAttribute("aria-label", `${entry.title} 的审核意见`);
      card.append(reason);
      reason.value = reviewDrafts.get(entry.id) || "";
      reason.oninput = () => reviewDrafts.set(entry.id, reason.value);
      for (const [action, label] of [["approve", "批准展示"], ["reject", "退回修改"]]) {
        const button = node("button", label, "secondary");
        button.type = "button";
        button.dataset.reviewAction = action;
        button.dataset.author = entry.actor;
        button.disabled = writing || action === "approve" && (entry.actor === actor || Date.now() + clockOffset >= Number(state.event.voting_opens_ms));
        button.onclick = () => perform(action, { entry_id: entry.id, reason: reason.value });
        card.append(button);
      }
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
        value = await request("public");
      }
      if (epoch === identityEpoch) render(value);
    } catch (error) {
      notice(error.message, true);
      if(!state)$('phase').textContent='活动暂未载入';
    } finally {
      refreshing = false;
    }
  }
  async function perform(action, payload, target = "notice") {
    if (target === "notice" && ["approve","reject","set-voting-url","award","publish-results","resolve-failed"].includes(action)) target="host-notice";
    if (writing) return false;
    if (!actor) {
      auth.open();
      return false;
    }
    writing = true;
    $("generate").disabled = true;
    if (action === 'generate') $("generate").textContent = '正在提交灵感…';
    $("generate").setAttribute("aria-busy", "true");
    renderHostControls();
    renderVoting();
    $("submit-entry").disabled = true;
    if (dialog.open) $("submit-entry").textContent = "正在提交…";
    try {
      const value = await request("actions", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action, payload, expected_actor_id: actor }) });
      writing = false;
      if (action === "set-voting-url") votingDirty = false;
      render(value);
      notice(action === "generate" ? "灵感已加入队列，可以留在这里等它画好。" : action === "submit" ? "投稿已收到。审核通过后，就能在作品墙见到它。" : action === 'vote' ? '选票已保存，截止前可以改投。' : action === 'cancel-vote' ? '选票已撤回。' : "已保存。", false, target);
      return true;
    } catch (error) {
      notice(error.message, true, target);
      if (error.code === "identity_changed" || error.status === 401) {
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
  });
  document.querySelectorAll("[data-prompt]").forEach((button) => button.onclick = () => {
    $("prompt").value = button.dataset.prompt;
    $("prompt").dispatchEvent(new Event("input"));
  });
  $("create-form").onsubmit = async (event) => {
    event.preventDefault();
    if (!actor) {
      auth.open();
      return;
    }
    const prompt = $("prompt").value.trim();
    if (!prompt) return;
    $("prompt").blur();
    followGeneration = true;
    if (!pendingIntent || pendingIntent.prompt !== prompt) pendingIntent = { prompt, intent: crypto.randomUUID() };
    if (await perform("generate", pendingIntent)) pendingIntent = null;
    else followGeneration = false;
  };
  function openSubmission(entry = null) {
    if (entry) {
      selected = entry.generation_id;
      render(state);
      $("entry-title").value = entry.title;
      $("display-name").value = entry.display_name;
    }
    $("consent").checked = false;
    notice("", false, "submit-notice");
    $("submit-dialog").showModal();
    fitDialog();
    $("entry-title").focus();
  }
  $("choose").onclick = () => openSubmission();
  $("close-dialog").onclick = () => $("submit-dialog").close();
  $("close-artwork").onclick = () => $("artwork-dialog").close();
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
      $("submit-dialog").close();
      notice("投稿已收到，审核通过后会进入作品墙。");
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
    try {
      const img = $("result-image");
      await img.decode();
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
      const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
      if (!blob) throw new Error("无法保存图片");
      saveBlob(new Blob([labelPng(new Uint8Array(await blob.arrayBuffer()), selected)], { type: "image/png" }), `半醒咖啡-AI生成-${selected.slice(0, 8)}.png`);
    } catch {
      notice("图片暂时无法保存，请等图片加载完成后重试。", true);
    }
  };
  async function poll() {
    clearTimeout(timer);
    if (!document.hidden) await refresh();
    timer = setTimeout(poll, active() || state?.voting?.mode === 'builtin' && state.voting.phase === 'open' ? 4e3 : 15e3);
  }
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden) poll();
  });
  window.addEventListener("focus", refresh);
  window.addEventListener("pagehide", () => clearTimeout(timer));
  poll();
}
export {
  creationPhase,
  generationCredits,
  creativeEndpoint,
  votingRows,
  csvCell,
  jobLabels,
  labelPng
};
