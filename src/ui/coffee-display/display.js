const video = document.getElementById('rotation');
const motion = document.getElementById('motion');
const message = document.getElementById('playback-message');
const reduced = matchMedia('(prefers-reduced-motion: reduce)');
let requested = !reduced.matches && !navigator.connection?.saveData;

function reflect() {
  motion.textContent = video.paused ? '播放动画' : '暂停动画';
  motion.setAttribute('aria-label', motion.textContent);
  document.querySelector('.display').classList.toggle('motion-paused', video.paused);
}

async function play() {
  try { await video.play(); }
  catch { /* Keep the poster and a real play button when autoplay is blocked. */ }
  reflect();
}

motion.hidden = false;
video.addEventListener('play', reflect);
video.addEventListener('pause', reflect);
video.addEventListener('error', () => {
  message.hidden = false;
  motion.hidden = true;
});
motion.addEventListener('click', () => {
  requested = video.paused;
  if (requested) play();
  else video.pause();
});
document.addEventListener('visibilitychange', () => {
  if (document.hidden) video.pause();
  else if (requested) play();
});
reduced.addEventListener('change', () => {
  if (reduced.matches) { requested = false; video.pause(); }
});
if (requested) play();
reflect();
