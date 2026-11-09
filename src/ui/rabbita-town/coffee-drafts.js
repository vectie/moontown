// Drafts are scoped by event AND creator. Identity changes never delete a draft.
// Keep small text synchronously so closing immediately after typing is safe;
// keep an optional upload Blob in IndexedDB without filling localStorage.
export function draftKey(scope, creator) { return `future-community.draft.v1:${scope}:${creator || 'visitor'}`; }
export function draftStore(scope, report = () => {}) {
  let database;
  function db() {
    if (!database) database = new Promise((resolve, reject) => {
      if (!globalThis.indexedDB) return reject(new Error('本机图片暂存不可用'));
      const request = indexedDB.open('future-community-creative', 1);
      const timeout=setTimeout(()=>reject(new Error('本机存储暂时不可用')),2000);
      request.onupgradeneeded = () => request.result.createObjectStore('drafts');
      request.onsuccess = () => {clearTimeout(timeout);resolve(request.result);};
      request.onerror = () => {clearTimeout(timeout);reject(request.error);};
      request.onblocked = () => {clearTimeout(timeout);reject(new Error('本机存储被其他页面占用'));};
    });
    return database;
  }
  async function image(creator, value, write, kind='file') {
    const database = await db();
    return new Promise((resolve, reject) => {
      const transaction = database.transaction('drafts', write ? 'readwrite' : 'readonly');
      const store = transaction.objectStore('drafts');
      const key=kind==='nickname' ? nicknameKey(creator) : `${draftKey(scope,creator)}:${kind}`;
      const request = write ? store.put(value, key) : store.get(key);
      transaction.oncomplete = () => resolve(write ? value : request.result);
      transaction.onerror = transaction.onabort = () => reject(transaction.error || new Error('草稿未能保存'));
    });
  }
  return {
    async readNickname(creator) {
      if(!creator)return '';
      let backup;
      try { backup=JSON.parse(localStorage.getItem(nicknameKey(creator)) || 'null'); } catch {}
      try { const durable=await image(creator,undefined,false,'nickname');return ((backup?.updated || 0)>(durable?.updated || 0)?backup:durable || backup)?.name || ''; }
      catch { return backup?.name || ''; }
    },
    writeNickname(creator, name) {
      if(!creator)return;
      const record={name:name.trim().slice(0,40),updated:Date.now()};
      image(creator,record,true,'nickname').catch(()=>{});
      try { localStorage.setItem(nicknameKey(creator),JSON.stringify(record)); } catch {}
    },
    async read(creator) {
      let backup;
      try { backup=JSON.parse(localStorage.getItem(draftKey(scope, creator)) || 'null'); } catch {}
      try { const durable=await image(creator,undefined,false,'text');return (backup?.updated || 0)>(durable?.updated || 0)?backup:durable || backup; }
      catch { return backup || null; }
    },
    write(creator, value) {
      const record={...value,updated:Date.now()};
      image(creator,record,true,'text').catch(()=>report('本机草稿暂存失败，请先保存喜欢的图片。'));
      try { localStorage.setItem(draftKey(scope, creator), JSON.stringify(record)); return true; }
      catch { report('本机存储空间不足，草稿暂未保存。请先保存喜欢的图片。'); return false; }
    },
    async readFile(creator) { try { return await image(creator); } catch { return null; } },
    async writeFile(creator, value) {
      try { await image(creator, value, true); return true; }
      catch { report('图片未能暂存，刷新后需要重新选择；提示词仍会保留。'); return false; }
    },
  };
}
export function nicknameKey(creator) { return `future-community.nickname.v1:${creator}`; }
