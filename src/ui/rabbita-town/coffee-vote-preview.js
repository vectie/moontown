const gallery=document.getElementById('preview-gallery')
const status=document.getElementById('vote-status')
const endpoint=new URL('./api/creative/',location.href)
const element=(tag,text)=>{const node=document.createElement(tag);if(text)node.textContent=text;return node}
try{
  const response=await fetch(new URL('public',endpoint),{cache:'no-store',credentials:'same-origin'})
  if(!response.ok)throw new Error('作品暂时无法加载，请稍后刷新。')
  const snapshot=await response.json()
  if(!snapshot.gallery.length)status.textContent='还没有过审作品。主办批准后，会在这里展示。'
  for(const entry of snapshot.gallery){
    const card=element('article');card.className='gallery-card'
    const wrap=element('div');wrap.className='image-wrap'
    const image=element('img');image.src=new URL(`images/${entry.generation_id}`,endpoint).href;image.alt=entry.title;image.loading='lazy'
    const badge=element('span','AI 生成');badge.className='ai-label';wrap.append(image,badge)
    const button=element('button','试选这张（不计票）');button.type='button';button.className='secondary'
    button.onclick=()=>{status.textContent=`你试选了「${entry.title}」。这是预览体验，没有提交或记录选票。`}
    card.append(wrap,element('h3',entry.title),element('p',entry.display_name),button);gallery.append(card)
  }
}catch(error){status.textContent=error.message}
