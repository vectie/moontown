// Only public gallery entries may be shared. No prompt or account identifier
// goes into the card or URL. The QR encoder is loaded only when requested.
export function suggestedTitle(prompt='', variant=0) {
  const themes=[[/森林(?!绿)|树|花|植物/,['一口小森林','咖啡长出了一片森林','把春天装进杯子']], [/云|天空|打哈欠/,['云朵还没醒','一杯云的早晨','今天的云有咖啡香']], [/城|街|房子/,['小城还没醒','杯里住着一个早晨','把清晨捧在手心']], [/海|浪|蓝色/,['一杯小小的海','咖啡海岸的早晨','醒在一朵浪花里']], [/猫|狗|动物/,['陪你慢慢醒来','一杯咖啡的好朋友','今天也想赖一会儿']], [/星|月|宇宙/,['星星也喝咖啡','月亮的第一杯美式','宇宙还在打盹']]];
  const names=themes.find(([pattern])=>pattern.test(prompt))?.[1] || ['半醒，刚刚好','让灵感醒一会儿','今天的美式有点奇妙'];
  return names[((variant%names.length)+names.length)%names.length];
}
export function publicShareLink(href, entryId, eventId) {
  if(!/^[a-f0-9]{64}$/.test(entryId))throw new Error('作品链接无效');
  const original=new URL(href),link=new URL(original.pathname,original.origin);
  const activity=original.searchParams.get('activity');
  if(activity && /^[A-Za-z0-9_-]{1,128}$/.test(activity))link.searchParams.set('activity',activity);
  link.searchParams.set('entry',entryId);
  link.searchParams.set('source','work-share');
  if(/^[A-Za-z0-9_-]{1,128}$/.test(eventId || ''))link.searchParams.set('campaign',eventId);
  link.hash='gallery';
  return link.href;
}
export function shareableEntry(state,id) { return state?.gallery?.find(entry=>entry.id===id) || null; }
export function shareCaption(event,now) {
  if(now<Number(event.voting_opens_ms))return '扫码看作品，投票即将开启';
  if(now<Number(event.voting_closes_ms))return '扫码看作品，为喜欢的灵感投票';
  return '扫码看作品与本期结果';
}
function lines(ctx,text,width,max=2) {
  const result=[];let line='';
  for(const char of Array.from(text)) {
    if(ctx.measureText(line+char).width>width && line){result.push(line);line='';}
    line+=char;
  }
  if(line)result.push(line);
  if(result.length>max){result.length=max;let last=result[max-1];while(ctx.measureText(last+'…').width>width)last=Array.from(last).slice(0,-1).join('');result[max-1]=last+'…';}
  return result;
}
export function coffeeShare({getState,imageUrl,loadImage,labelPng,fitDialog,now}) {
  const $=id=>document.getElementById(id),dialog=$('share-dialog');
  let entryId='',controller,objectUrl='',cardFile,serial=0;
  const status=(text,error=false)=>{$('share-status').textContent=text;$('share-status').dataset.error=String(error);};
  function cleanup(){serial++;controller?.abort();controller=null;if(objectUrl)URL.revokeObjectURL(objectUrl);objectUrl='';cardFile=null;$('share-preview').removeAttribute('src');$('share-preview').hidden=true;}
  function close(){dialog.close();cleanup();entryId='';}
  $('close-share').onclick=close;dialog.addEventListener('close',()=>{cleanup();entryId='';});
  async function prepare(){
    cleanup();const request=serial,state=getState(),entry=shareableEntry(state,entryId);
    if(!entry){close();return;}
    const link=publicShareLink(location.href,entry.id,state.event.id);
    $('share-link').value=link;$('share-copy').disabled=false;
    $('share-save').setAttribute('aria-disabled','true');$('share-native').hidden=true;$('share-retry').hidden=true;
    status('正在制作分享卡片…');controller=new AbortController();let source;
    const valid=()=>request===serial && Boolean(shareableEntry(getState(),entry.id));
    try {
      const [blob,{matrix}]=await Promise.all([loadImage(imageUrl(entry.generation_id),controller.signal),import('./coffee-qr.js')]);
      if(!valid())return;
      source=URL.createObjectURL(blob);const img=new Image();img.src=source;await img.decode();
      if(!valid())return;
      const canvas=document.createElement('canvas');canvas.width=1080;canvas.height=1560;
      const ctx=canvas.getContext('2d');if(!ctx)throw new Error('画布不可用');
      ctx.fillStyle='#f7f4e9';ctx.fillRect(0,0,1080,1560);
      ctx.fillStyle='#243e32';ctx.font='500 28px sans-serif';ctx.fillText('未来社区 / 每周创作',64,77);
      ctx.font='600 37px sans-serif';lines(ctx,state.event.name || '半醒咖啡，你的美式！',952,1).forEach(line=>ctx.fillText(line,64,136));
      ctx.save();ctx.beginPath();ctx.roundRect(64,178,952,952,28);ctx.clip();
      ctx.fillStyle='#e6ebda';ctx.fillRect(64,178,952,952);
      const scale=Math.min(952/img.naturalWidth,952/img.naturalHeight);
      const w=img.naturalWidth*scale,h=img.naturalHeight*scale;
      ctx.drawImage(img,64+(952-w)/2,178+(952-h)/2,w,h);ctx.restore();
      ctx.fillStyle='#243e32';ctx.font='600 46px sans-serif';
      lines(ctx,entry.title,670,2).forEach((line,i)=>ctx.fillText(line,64,1210+i*60));
      ctx.font='28px sans-serif';ctx.fillStyle='#5d695b';
      ctx.fillText(lines(ctx,entry.display_name,670,1)[0] || '',64,1324);
      ctx.fillStyle='#f74f29';ctx.fillRect(64,1360,46,5);
      ctx.fillStyle='#243e32';ctx.font='26px sans-serif';
      lines(ctx,shareCaption(state.event,now()),670,2).forEach((line,i)=>ctx.fillText(line,64,1415+i*34));
      const code=matrix(link),size=code[0],unit=Math.floor(228/(size+8)),extent=(size+8)*unit;
      const x=1016-extent,y=1360-extent/2;
      ctx.fillStyle='#fff';ctx.fillRect(x,y,extent,extent);ctx.fillStyle='#243e32';
      for(let row=0;row<size;row++)for(let col=0;col<size;col++)if(code[1+row*size+col])ctx.fillRect(x+(col+4)*unit,y+(row+4)*unit,unit,unit);
      ctx.font='22px sans-serif';ctx.fillStyle='#5d695b';ctx.fillText('AI 生成 · 作品状态与投票以活动页为准',64,1512);
      const png=await new Promise(resolve=>canvas.toBlob(resolve,'image/png'));if(!png)throw new Error('图片制作失败');
      const marked=labelPng(new Uint8Array(await png.arrayBuffer()),entry.generation_id);
      if(!valid())return;
      cardFile=new File([marked],`半醒咖啡-分享-${entry.id.slice(0,8)}.png`,{type:'image/png'});
      objectUrl=URL.createObjectURL(cardFile);$('share-preview').src=objectUrl;$('share-preview').hidden=false;
      $('share-save').href=objectUrl;$('share-save').download=cardFile.name;$('share-save').disabled=false;
      $('share-save').removeAttribute('aria-disabled');
      $('share-native').hidden=!navigator.canShare?.({files:[cardFile]});
      status('保存到相册，或复制链接分享。');
    }catch(error){if(valid() && error.name!=='AbortError'){status('卡片暂未做好，仍可复制作品链接。',true);$('share-retry').hidden=false;}}
    finally{if(source)URL.revokeObjectURL(source);}
  }
  $('share-retry').onclick=prepare;
  $('share-save').onclick=event=>{if(!cardFile){event.preventDefault();return;}status('若图片未自动保存，请长按卡片保存到相册。');};
  $('share-native').onclick=async()=>{const file=cardFile;if(!file)return;try{await navigator.share({files:[file],title:'我的半醒咖啡创作'});}catch(error){if(error.name!=='AbortError')status('可保存卡片或复制链接分享。');}};
  $('share-copy').onclick=async()=>{const link=$('share-link').value;try{await navigator.clipboard.writeText(link);status('作品链接已复制。');}catch{$('share-link-field').hidden=false;$('share-link').focus();$('share-link').select();status('长按选择并复制下面的作品链接。');}};
  return {
    open(id){if(!shareableEntry(getState(),id))return;entryId=id;$('share-link-field').hidden=true;dialog.showModal();fitDialog();prepare();},
    update(){if(entryId && !shareableEntry(getState(),entryId))close();},
    close,
  };
}
