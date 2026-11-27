import {awardGroups,prizeItems,workCaption,tickerDuration} from './display-awards.js?v=3';
const display=document.querySelector('.display'),track=document.querySelector('#track'),motion=document.querySelector('#motion');
const dialog=document.querySelector('#detail'),detailImage=document.querySelector('#detail-image'),detailPrize=document.querySelector('#detail-prize');
// The installed app is an unattended exhibition, with its own Pause control.
// Ordinary browser visits continue to respect the visitor's reduced-motion preference.
const exhibition=typeof window.lepusa?.invoke==='function';
if(exhibition){
 const root=document.documentElement;let timer,lastPointer;
 const hide=()=>{if(root.dataset.cursorHidden!=='true')root.dataset.cursorHidden='true'};
 const reveal=()=>{if(root.dataset.cursorHidden!=='false')root.dataset.cursorHidden='false';clearTimeout(timer);timer=setTimeout(hide,1800)};
 document.addEventListener('pointermove',event=>{
  if(event.pointerType!=='mouse')return;
  if(lastPointer&&Math.hypot(event.clientX-lastPointer.x,event.clientY-lastPointer.y)<4)return;
  lastPointer={x:event.clientX,y:event.clientY};reveal();
 },{passive:true});
 document.addEventListener('pointerdown',event=>{if(event.pointerType==='mouse')reveal();else hide()},{passive:true});
 document.addEventListener('keydown',hide);
 document.addEventListener('visibilitychange',()=>{if(document.hidden){clearTimeout(timer);hide()}});
 hide();
}
const reduced=matchMedia('(prefers-reduced-motion: reduce)');let manualPaused=!exhibition&&reduced.matches,focused=false,playbackChosen=false,keyboardNavigation=false;
if(document.body.dataset.opensMs){const startsAt=Number(document.body.dataset.opensMs),entry=document.querySelector('.join-direct'),caption=document.querySelector('.entry figcaption');const syncEntry=()=>{const waiting=Date.now()<startsAt;entry.textContent=waiting?'查看赛题 · 11月30日开赛':'创作参赛';caption.textContent=waiting?'扫码查看赛题':'一键参赛有奖'};syncEntry();setInterval(syncEntry,60000);document.addEventListener('visibilitychange',syncEntry)}
const positions={figure:'0% 50%',tote:'50% 50%',coffee:'100% 50%'},items=[];
function sync(){const reason=manualPaused?'manual':dialog.open?'detail':focused?'keyboard':document.hidden?'hidden':'';display.dataset.pauseReason=reason;display.dataset.paused=String(!!reason);motion.querySelector('.motion-play').hidden=!manualPaused;motion.querySelector('.motion-pause').hidden=manualPaused;const label=manualPaused?'继续滚动':'暂停滚动';motion.setAttribute('aria-label',label);motion.title=label}
document.addEventListener('keydown',event=>{if(event.key==='Tab')keyboardNavigation=true},true);
document.addEventListener('pointerdown',()=>{keyboardNavigation=false;focused=false;sync()},true);
function showDetail(item){document.querySelector('#detail-title').textContent=item.title;document.querySelector('#detail-caption').textContent=item.caption;const full=item.full;detailImage.hidden=!full;detailPrize.hidden=!!full;if(full){detailImage.alt=item.title;detailImage.src=full}else{detailImage.removeAttribute('src');detailPrize.style.backgroundPosition=positions[item.sprite];detailPrize.setAttribute('aria-label',`${item.title}示意图`)}dialog.showModal();sync()}
function bindItem(button,item){button.dataset.item=String(items.length);items.push(item)}
function makeCard(group,work){const card=document.createElement('button');card.type='button';card.className='slide';card.setAttribute('aria-label',`放大查看第${group.issue}期${group.rank}：${work.title}，${work.author}`);bindItem(card,{...work,caption:workCaption(group,work)});const img=document.createElement('img');img.className='slide-image';img.src=work.thumb;img.width=384;img.height=384;img.alt='';img.decoding='async';const copy=document.createElement('span');copy.className='slide-copy';for(const [cls,value] of [['slide-kicker','获奖作品'],['slide-title',work.title],['slide-author',work.author]]){const text=document.createElement('span');text.className=cls;text.textContent=value;copy.append(text)}card.append(img,copy);return card}
const cycle=document.createElement('div');cycle.className='carousel-cycle';
for(const group of awardGroups){const section=document.createElement('section');section.className='award-group';section.setAttribute('aria-label',`第${group.issue}期${group.theme} · ${group.rank}`);const lead=document.createElement('div');lead.className='award-lead';const issue=document.createElement('span');issue.className='group-issue';issue.textContent=`第${group.issue}期`;const rank=document.createElement('strong');rank.className='group-rank';rank.textContent=group.rank;const data=prizeItems[group.prize],prize=document.createElement('button');prize.type='button';prize.className=`group-prize ${data.sprite}`;if(data.thumb)prize.style.backgroundImage=`url("${data.thumb}")`;prize.setAttribute('aria-label',`查看第${group.issue}期${group.rank}奖品：${data.title}`);bindItem(prize,{...data,caption:data.caption || (data.full?'实物奖品照片':'咖啡券示意，以主办方兑奖安排为准')});const prizeName=document.createElement('span');prizeName.className='group-prize-name';prizeName.textContent=data.title;lead.append(issue,rank,prize,prizeName);section.append(lead);group.works.forEach(work=>section.append(makeCard(group,work)));cycle.append(section)}
track.append(cycle);
function layout(){const width=cycle.getBoundingClientRect().width,visible=document.querySelector('.carousel-viewport').getBoundingClientRect().width;if(!width)return;track.style.setProperty('--cycle-width',`${width}px`);track.style.setProperty('--duration',`${tickerDuration(width,display.clientWidth)}s`);track.querySelectorAll('[data-clone]').forEach(node=>node.remove());for(let i=1;i<Math.ceil(visible/width)+1;i++){const clone=cycle.cloneNode(true);clone.dataset.clone='true';clone.setAttribute('aria-hidden','true');clone.querySelectorAll('button').forEach(button=>button.tabIndex=-1);track.append(clone)}}
track.addEventListener('click',event=>{const card=event.target.closest('[data-item]');if(card)showDetail(items[Number(card.dataset.item)])});motion.addEventListener('click',()=>{playbackChosen=true;manualPaused=!manualPaused;sync()});track.addEventListener('focusin',()=>{focused=keyboardNavigation;sync()});track.addEventListener('focusout',event=>{focused=keyboardNavigation&&track.contains(event.relatedTarget);sync()});document.querySelector('#close-detail').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',event=>{if(event.target===dialog)dialog.close()});dialog.addEventListener('close',()=>{detailImage.removeAttribute('src');sync()});document.addEventListener('visibilitychange',sync);reduced.addEventListener('change',()=>{if(!exhibition&&!playbackChosen)manualPaused=reduced.matches;sync()});new ResizeObserver(layout).observe(display);document.fonts.ready.then(layout);layout();sync();
