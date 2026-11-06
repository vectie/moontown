const jobLabels = Object.freeze({
  queued: "已经排好队，轮到你就开始画。",
  running: "正在把想象画出来，请稍等。离开页面也不会丢失任务。",
  needs_reconcile: "这次生成需要主办核对。我们会保留记录，不会自动重复生成。",
  failed: "这次没有完成，次数已退回。可以再试一次。"
});
const entryLabels = Object.freeze({ pending: "等待审核", approved: "已进入作品墙", rejected: "需要调整后重新投稿", superseded: "已被新版替换", withdrawn: "已撤回" });
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
  const endpoint = new URL("./api/creative/", location.href);
  const url = (path) => new URL(path, endpoint).href;
  let state = null, selected = "", actor = "", pendingIntent = null, writing = false, refreshing = false, timer, clockOffset = 0;
  const reviewDrafts = /* @__PURE__ */ new Map();
  let votingDirty = false;
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
    $("create-form").reset();
    $("submit-form").reset();
    $("prompt-count").textContent = "0 / 2000";
    $("submit-dialog").close();
    $("result-image").removeAttribute("src");
    $("result-image").removeAttribute("data-job");
    $("result").hidden = true;
    $("empty-preview").hidden = false;
    $("moderation").hidden = true;
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
    const wrap = node("div", void 0, "image-wrap");
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
    const changed = !state || value.revision !== state.revision || nextActor !== actor || value.viewer.operator !== state.viewer.operator || value.awards?.length !== state.awards?.length;
    if (value.server_ms) clockOffset = Number(value.server_ms) - Date.now();
    if (actor && actor !== nextActor) {
      clearPrivate();
      notice("登录账户已变化，已刷新为当前账户。");
    }
    actor = nextActor;
    state = value;
    $("login").textContent = actor ? "我的账户 ↗" : "登录参与 ↗";
    $("generate").disabled = writing || Boolean(actor && (!open() || active() || state.remaining === 0 || state.event_remaining === 0 || !state.event.provider_ready));
    $("generate").firstChild.textContent = actor ? !open() ? "本期投稿已截止 " : active() ? "有一张灵感正在路上 " : state.event_remaining===0 ? "本期生成名额已用完 " : !state.event.provider_ready ? "生成服务准备中 " : "生成一张图 " : "登录，开始创作 ";
    $("credits").textContent = actor ? `本期还可生成 ${state.remaining} 张 · 参赛前仅自己可见` : "登录后生成；图片确认参赛前仅自己可见。";
    const now = Date.now() + clockOffset, ev = state.event;
    if(ev.name)$("event-name").textContent=ev.name;
    if(ev.topic)$("event-topic").textContent=`本期主题：${ev.topic}`;
    if(ev.scope)$("event-scope").textContent=ev.scope;
    if(ev.first_person_solution)$("first-person-solution").textContent=ev.first_person_solution;
    const date = (value,withTime=false) => new Intl.DateTimeFormat('zh-CN',{timeZone:'Asia/Shanghai',month:'2-digit',day:'2-digit',weekday:'short',...(withTime?{hour:'2-digit',minute:'2-digit',hour12:false}:{})}).format(Number(value));
    $("start-time").textContent=date(ev.opens_ms);
    $("deadline-time").textContent=date(ev.deadline_ms,true);
    $("awards-time").textContent=date(ev.awards_ms);
    $("phase").textContent = now < Number(ev.deadline_ms) && !ev.provider_ready ? "创作即将开放" : now < Number(ev.opens_ms) ? "即将开始" : now < Number(ev.deadline_ms) ? "正在征集灵感" : now < Number(ev.voting_opens_ms) ? "投稿结束 · 正在审核" : now < Number(ev.voting_closes_ms) ? "一起为灵感投票" : "本期已结束";
    const jobs = state.generations || [], completed = jobs.filter((j) => j.state === "completed");
    if (!completed.some((j) => j.id === selected)) selected = completed.at(-1)?.id || "";
    $("empty-preview").hidden = Boolean(selected);
    $("result").hidden = !selected;
    if (selected && $("result-image").dataset.job !== selected) {
      $("result-image").src = url(`images/${selected}`);
      $("result-image").dataset.job = selected;
    }
    $("choose").disabled = writing || !open();
    const job = jobs.find((j) => ["queued", "running", "needs_reconcile"].includes(j.state)) || jobs.at(-1);
    $("job-status").hidden = !job || job.state === "completed";
    $("job-status").textContent = jobLabels[job?.state] || "";
    $("job-status").dataset.active = String(["queued", "running"].includes(job?.state));
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
      if (["pending", "approved"].includes(entry.state)) {
        const withdraw = node("button", "撤回投稿", "text-button");
        withdraw.type = "button";
        withdraw.onclick = () => perform("withdraw", { entry_id: entry.id });
        $("my-entry").append(withdraw);
      }
    }
    const gallery = state.gallery || [];
    $("gallery-empty").hidden = gallery.length > 0;
    if (changed) $("gallery-grid").replaceChildren(...gallery.map((entry2) => {
      const card = node("article", void 0, "gallery-card");
      card.append(image(entry2.generation_id, entry2.title), node("h3", entry2.title), node("p", `${entry2.display_name} · 作品 ${entry2.id.slice(0, 8)}`));
      return card;
    }));
    const vote = state.voting_url;
    $("vote").hidden = !vote;
    $("vote").textContent=state.voting_preview ? "预览投票页（不计票） ↗" : "为喜欢的作品投一票 ↗";
    if (vote) $("vote").href = vote;
    $("vote-note").textContent = now >= Number(ev.voting_opens_ms) && now < Number(ev.voting_closes_ms) ? vote ? state.voting_preview ? "作品名单已锁定。当前为投票预览，不记录票数；正式投票入口稍后公布。" : "作品名单已锁定。到腾讯文档，为喜欢的灵感加油。" : "投票入口正在准备，主办配置后会出现在这里。" : "过审作品会出现在这里。投票开放后，可以为喜欢的作品加油。";
    $("awards").hidden = !state.awards?.length;
    $("awards").replaceChildren(...(state.awards || []).map((award) => {
      const entry2 = gallery.find((e) => e.id === award.entry_id);
      return node("p", `${prizeLabels[award.prize]}：${entry2?.title || "作品已撤回"}${entry2 ? ` / ${entry2.display_name}` : ""} · ${award.reason}`);
    }));
    if (changed) renderHost();
  }
  function renderHost() {
    $("moderation").hidden = !state.viewer.operator;
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
    refreshing = true;
    try {
      let value;
      try {
        value = await request("mine");
      } catch (error) {
        if (error.status !== 401) throw error;
        value = await request("public");
      }
      render(value);
    } catch (error) {
      notice(error.message, true);
    } finally {
      refreshing = false;
    }
  }
  async function perform(action, payload, target = "notice") {
    if (target === "notice" && ["approve","reject","set-voting-url","award","publish-results","resolve-failed"].includes(action)) target="host-notice";
    if (writing) return false;
    if (!actor) {
      location.href = $("login").href;
      return false;
    }
    writing = true;
    $("generate").disabled = true;
    try {
      const value = await request("actions", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action, payload, expected_actor_id: actor }) });
      writing = false;
      if (action === "set-voting-url") votingDirty = false;
      render(value);
      notice(action === "generate" ? "灵感已加入队列，可以留在这里等它画好。" : action === "submit" ? "投稿已收到。审核通过后，就能在作品墙见到它。" : "已保存。", false, target);
      return true;
    } catch (error) {
      notice(error.message, true, target);
      if (error.code === "identity_changed" || error.status === 401) {
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
    pendingIntent = null;
  });
  document.querySelectorAll("[data-prompt]").forEach((button) => button.onclick = () => {
    $("prompt").value = button.dataset.prompt;
    $("prompt").dispatchEvent(new Event("input"));
    $("prompt").focus();
  });
  $("create-form").onsubmit = async (event) => {
    event.preventDefault();
    if (!actor) {
      location.href = $("login").href;
      return;
    }
    const prompt = $("prompt").value.trim();
    if (!prompt) return;
    if (!pendingIntent || pendingIntent.prompt !== prompt) pendingIntent = { prompt, intent: crypto.randomUUID() };
    if (await perform("generate", pendingIntent)) pendingIntent = null;
  };
  $("choose").onclick = () => {
    notice("", false, "submit-notice");
    $("submit-dialog").showModal();
    $("entry-title").focus();
  };
  $("close-dialog").onclick = () => $("submit-dialog").close();
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
  $("refresh").onclick = refresh;
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
    timer = setTimeout(poll, active() ? 4e3 : 15e3);
  }
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden) poll();
  });
  window.addEventListener("focus", refresh);
  window.addEventListener("pagehide", () => clearTimeout(timer));
  poll();
}
export {
  csvCell,
  jobLabels,
  labelPng
};
