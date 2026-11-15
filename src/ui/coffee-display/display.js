const theme='crystal'
document.body.dataset.theme=theme
document.querySelector('#portrait-source').srcset='assets/crystal-portrait.webp'
document.querySelector('#hero-art').src=`assets/${theme}-gem.webp`
document.querySelector('#theme-title').hidden=true
document.querySelector('#hero-art').alt='少女仰望天空并看向镜头，举起水晶咖啡杯，阳光穿过杯子，在脸颊、肩膀和发丝上映出彩色折光'
const host='主办方 AI 创作'
const items=[
 {kind:'prize',sprite:'figure',kicker:'本期一等奖奖品',title:'史迪奇公仔',author:'实物奖品'},
 {kind:'work',kicker:'上期精选',title:'深秋半醒，刚刚好',author:'小王',thumb:'assets/work-autumn-thumb.webp',full:'assets/work-autumn.png'},
 {kind:'prize',sprite:'tote',kicker:'本期二等奖奖品',title:'白色帆布包',author:'实物奖品'},
 {kind:'work',kicker:'二等奖展示',title:'一盏未醒',author:host,thumb:'assets/award-second-ink-thumb.webp',full:'assets/award-second-ink.png'},
 {kind:'work',kicker:'二等奖展示',title:'醒来频率',author:host,thumb:'assets/award-second-op-thumb.webp',full:'assets/award-second-op.png'},
 {kind:'prize',sprite:'coffee',kicker:'本期三等奖奖品',title:'半醒咖啡券',author:'奖品示意'},
 {kind:'work',kicker:'上期精选',title:'勺子',author:'勺子',thumb:'assets/work-spoon-thumb.webp',full:'assets/work-spoon.png'},
 {kind:'work',kicker:'上期精选',title:'森林氧吧',author:'草莓奶昔',thumb:'assets/work-forest-thumb.webp',full:'assets/work-forest.png'},
 {kind:'work',kicker:'三等奖展示',title:'早安，半醒',author:host,thumb:'assets/award-third-line-thumb.webp',full:'assets/award-third-line.png'},
]
const display=document.querySelector('.display'),track=document.querySelector('#track'),motion=document.querySelector('#motion')
const dialog=document.querySelector('#detail')
const detailImage=document.querySelector('#detail-image'),detailPrize=document.querySelector('#detail-prize')
const reduced=matchMedia('(prefers-reduced-motion: reduce)'),small=matchMedia('(max-width:700px)')
let manualPaused=reduced.matches,focused=false
const positions={figure:'0% 50%',tote:'50% 50%',coffee:'100% 50%'}
const realPrizes={figure:'assets/prize-figure-real.png',tote:'assets/prize-tote-real.png'}
function sync(){display.dataset.paused=String(manualPaused||focused||dialog.open||document.hidden);motion.textContent=manualPaused?'继续':'暂停';motion.setAttribute('aria-label',manualPaused?'继续滚动':'暂停滚动')}
function showDetail(item){
 document.querySelector('#detail-title').textContent=item.title
 const realPhoto=item.kind==='prize'?realPrizes[item.sprite]:null
 document.querySelector('#detail-caption').textContent=item.kind==='work'?`${item.kicker} · ${item.author}`:realPhoto?`${item.kicker} · 实物照片`:'奖品示意，以实物为准'
 detailImage.hidden=!(item.kind==='work'||realPhoto);detailPrize.hidden=!!(item.kind==='work'||realPhoto)
 if(item.kind==='work'||realPhoto){detailImage.alt=item.title;detailImage.src=realPhoto||item.full}else{detailImage.removeAttribute('src');detailPrize.style.backgroundPosition=positions[item.sprite];detailPrize.setAttribute('aria-label',item.title+'示意图')}
 dialog.showModal();sync()
}
function makeCard(item,index){
 const card=document.createElement('button');card.type='button';card.className='slide';card.dataset.item=String(index)
 card.setAttribute('aria-label',`放大查看${item.title}，${item.author}`)
 const visual=document.createElement(item.kind==='work'?'img':'span')
 if(item.kind==='work'){visual.className='slide-image';visual.src=item.thumb;visual.width=384;visual.height=384;visual.alt='';visual.decoding='async'}else{visual.className=`slide-prize ${item.sprite}`;visual.setAttribute('aria-hidden','true')}
 const copy=document.createElement('span');copy.className='slide-copy'
 for(const [cls,value] of [['slide-kicker',item.kicker],['slide-title',item.title],['slide-author',item.author]]){const text=document.createElement('span');text.className=cls;text.textContent=value;copy.append(text)}
 card.append(visual,copy);return card
}
const cycle=document.createElement('div');cycle.className='carousel-cycle'
for(const group of [{rank:'一等奖',prize:0,works:[1]},{rank:'二等奖',prize:2,works:[3,4]},{rank:'三等奖',prize:5,works:[6,7,8]}]){
 const section=document.createElement('section');section.className='award-group';section.setAttribute('aria-label',group.rank+'奖品与作品')
 const lead=document.createElement('div');lead.className='award-lead'
 const rank=document.createElement('strong');rank.className='group-rank';rank.textContent=group.rank
 const prize=document.createElement('button');prize.type='button';prize.className=`group-prize ${items[group.prize].sprite}`;prize.dataset.item=String(group.prize);prize.setAttribute('aria-label',`放大查看${items[group.prize].title}${realPrizes[items[group.prize].sprite]?'实物照片':'示意图'}`)
 const name=document.createElement('span');name.className='group-prize-name';name.textContent=items[group.prize].title
 lead.append(rank,prize,name);section.append(lead)
 group.works.forEach(index=>section.append(makeCard(items[index],index)));cycle.append(section)
}
track.append(cycle)
function repeat(parent,source,count){
 parent.querySelectorAll('[data-clone]').forEach(node=>node.remove())
 for(let i=1;i<count;i++){const clone=source.cloneNode(true);clone.dataset.clone='true';clone.setAttribute('aria-hidden','true');clone.querySelectorAll('button').forEach(button=>button.tabIndex=-1);parent.append(clone)}
}
function layout(){
 const width=cycle.getBoundingClientRect().width,visible=document.querySelector('.carousel-viewport').getBoundingClientRect().width
 track.style.setProperty('--cycle-width',`${width}px`)
 track.style.setProperty('--duration',`${Math.max(30,width/(display.clientWidth*.011))}s`)
 repeat(track,cycle,Math.ceil(visible/width)+1)
}
track.addEventListener('click',event=>{const card=event.target.closest('[data-item]');if(card)showDetail(items[Number(card.dataset.item)])})
motion.addEventListener('click',()=>{manualPaused=!manualPaused;sync()})
track.addEventListener('focusin',()=>{focused=true;sync()})
track.addEventListener('focusout',event=>{focused=track.contains(event.relatedTarget);sync()})
document.querySelector('#close-detail').addEventListener('click',()=>dialog.close())
dialog.addEventListener('close',()=>{detailImage.removeAttribute('src');sync()})
document.addEventListener('visibilitychange',sync)
reduced.addEventListener('change',()=>{manualPaused=reduced.matches;sync()})
new ResizeObserver(layout).observe(display)
layout();sync()
