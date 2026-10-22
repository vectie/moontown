// Presentation only. Model data, scene geometry and lighting stay in each viewer.
const paths = {
  back:'M15 5l-7 7 7 7M8 12h13', cube:'M12 2 2 7v10l10 5 10-5V7zM2 7l10 5 10-5M12 12v10',
  indoor:'M4 22V3h16v19M2 22h20M9 22V9h6v13M12 14h.01', server:'M3 3h18v7H3zM3 14h18v7H3zM6 6h1M6 17h1M11 6h7M11 17h7',
  sliders:'M4 3v6m0 6v6M12 3v12m0 4v2M20 3v2m0 6v10M1 9h6v6H1zM9 15h6v4H9zM17 5h6v6h-6z',
  reset:'M3 11a9 9 0 1 1 2.6 7M3 4v7h7', fit:'M3 8V3h5M16 3h5v5M21 16v5h-5M8 21H3v-5', top:'M3 3h18v18H3zM3 9h18M9 3v18',
  chart:'M4 3v18h17M8 16V9M13 16V5M18 16v-5', close:'M6 6l12 12M18 6 6 18', photo:'M3 3h18v18H3zM3 16l5-5 4 4 3-3 6 6M16 7h.01',
  play:'m8 4 12 8-12 8z', pause:'M8 4v16M16 4v16', network:'M9 3h6v6H9zM2 15h6v6H2zM16 15h6v6h-6zM12 9v3M5 15v-3h14v3',
  power:'m13 2-9 12h7l-1 8 10-12h-7z', cooling:'M12 2v20M3.3 7l17.4 10M3.3 17 20.7 7M9 4l3 3 3-3M9 20l3-3 3 3',
};
export function viewerIcon(name) {
  const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');
  for(const [key,value] of Object.entries({viewBox:'0 0 24 24',fill:'none',stroke:'currentColor','stroke-width':'1.7','stroke-linecap':'round','stroke-linejoin':'round','aria-hidden':'true'}))svg.setAttribute(key,value);
  svg.classList.add('viewer-icon');const path=document.createElementNS('http://www.w3.org/2000/svg','path');path.setAttribute('d',paths[name]||paths.cube);svg.append(path);return svg;
}
export function setViewerButton(button,icon,label) {
  const text=document.createElement('span');text.textContent=label;button.replaceChildren(viewerIcon(icon),text);
}
export function initViewerUI() {
  document.querySelectorAll('[data-icon]').forEach(node=>node.replaceChildren(viewerIcon(node.dataset.icon)));
  document.querySelectorAll('.viewer-advanced > summary').forEach(summary=>summary.prepend(viewerIcon('sliders')));
  document.querySelectorAll('.viewer-advanced').forEach(details=>details.addEventListener('keydown',event=>{
    if(event.key==='Escape'&&details.open){details.open=false;details.querySelector('summary').focus();event.stopPropagation();}
  }));
}
