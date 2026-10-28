// A tiny route observer: the outdoor town never imports Three.js or model data.
let pending = false;
const stylesheet = new URL('./town-space.css', import.meta.url).href;
async function scan() {
  if (pending || !document.querySelector('.town-space-host')) return;
  pending = true;
  if (!document.querySelector('link[data-town-space]')) {
    const link = document.createElement('link');
    link.rel = 'stylesheet'; link.href = stylesheet; link.dataset.townSpace = '';
    document.head.append(link);
  }
  try {
    const module = await import('./town-space.js');
    observer.disconnect();
    module.installTownSpaces(event => globalThis.__moonTownSpaceDeliver?.(event));
  } catch (error) {
    pending = false;
    console.error('Town space unavailable', error);
    for (const host of document.querySelectorAll('.town-space-host')) {
      if (host.childElementCount) continue;
      const message = document.createElement('p');
      message.textContent = '3D 暂不可用，右侧工作面板仍可使用。';
      const retry = document.createElement('button'); retry.textContent = '重试';
      retry.onclick = () => { host.replaceChildren(); scan(); };
      host.append(message, retry);
    }
  }
}
const observer = new MutationObserver(scan);
observer.observe(document.getElementById('app') || document.body, {childList:true, subtree:true});
scan();
