// Injected by the packaged Lepusa runtime; the website needs no native APIs.
(() => {
  if (window !== window.top || location.origin !== 'https://suanli.kechuangfuwu.com:8443') return;
  let fullscreen = false;
  let pending = false;
  const setFullscreen = async value => {
    if (pending || !window.lepusa?.invoke) return;
    pending = true;
    try {
      await window.lepusa.invoke('window.setFullscreen', {windowLabel:'main', fullscreen:value});
      fullscreen = value;
    } catch (error) {
      console.error('无法切换展屏全屏', error);
    } finally { pending = false; }
  };
  document.addEventListener('keydown', event => {
    if (event.key !== 'F11') return;
    event.preventDefault();
    event.stopPropagation();
    void setFullscreen(!fullscreen);
  }, true);
  const ready = () => {
    void setFullscreen(true);
    if (!/^\/disp\/?$/.test(location.pathname)) return;
    let attempts = 0;
    const followTitle = async () => {
      const topic = document.querySelector('.copy h1')?.textContent.trim();
      const works = document.querySelector('.carousel-cycle')?.querySelectorAll('.slide').length;
      const images = [...document.images].filter(image => {
        const bounds = image.getBoundingClientRect();
        return bounds.width && bounds.height && bounds.right > 0 && bounds.bottom > 0 && bounds.left < innerWidth && bounds.top < innerHeight;
      });
      if (topic && works && images.length && images.every(image => image.complete && image.naturalWidth)) {
        await window.lepusa.invoke('window.setTitle', {windowLabel:'main', title:`未来社区 · ${topic}`}).catch(error => console.error('无法更新展屏标题', error));
      } else if (++attempts < 100) setTimeout(followTitle, 200);
    };
    void followTitle();
    const fingerprint = page => JSON.stringify([
      page.title,
      [...page.querySelectorAll('head link[rel="stylesheet"],head script[src],.hero img')].map(node => node.getAttribute('href') || node.getAttribute('src')),
      page.body.dataset.cover, page.body.dataset.theme, page.body.dataset.opensMs
    ]);
    const initial = fingerprint(document);
    // Keep the loaded poster during network failures; refresh only a complete,
    // newer release, with dialogs closed and operator playback resumed.
    setInterval(async () => {
      if (document.querySelector('dialog[open]') || document.querySelector('.display')?.dataset.paused === 'true') return;
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);
      try {
        const response = await fetch('/disp/', {cache:'no-store', credentials:'omit', signal:controller.signal});
        if (!response.ok) return;
        const latest = new DOMParser().parseFromString(await response.text(), 'text/html');
        if (latest.querySelector('#hero-art') && fingerprint(latest) !== initial) location.reload();
      } catch (_) { /* The existing screen stays usable until connectivity returns. */ }
      finally { clearTimeout(timeout); }
    }, 300000);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', ready, {once:true});
  else ready();
})();
