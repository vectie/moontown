// Reports retain the exact town selection/work context. Design arithmetic never
// masquerades as a live measurement or a binding between a machine and a rack.
export function showSpaceReport(host, report) {
  host.querySelector('dialog')?.remove();
  const opener = document.activeElement, dialog = document.createElement('dialog'); dialog.className = 'space-report';
  const make = (tag,text) => { const element = document.createElement(tag); if (text !== undefined) element.textContent = text; return element; };
  const header = make('header'), title = make('h2','空间报告'), close = make('button','关闭');
  close.onclick = () => dialog.close(); header.append(title,close); dialog.append(header);
  const context = report.context;
  dialog.append(make('p', `当前对象：${context.selection?.title || '未选择'}`));
  const detail = make('details'), detailTitle = make('summary', '高级 · 报告记录与导出');
  detail.append(detailTitle, make('p', `${context.key} / ${context.view}${context.design_rack ? ' / '+context.design_rack : ''}${context.design_slot ? ' / '+context.design_slot : ''}`));
  detail.append(make('p', `工作：${context.work || '未选择'} · 请求：${context.request || '无'}`));
  dialog.append(make('h3',report.nodes.length ? '接入快照' : '工作空间'));
  if (report.nodes.length) {
    dialog.append(make('p', `快照时间：${report.observed_at || '暂无'} · 物理位置未绑定`));
    const selected = context.selection?.scope === 'runtime' ? report.nodes.find(item => item.id === context.selection.id) : null;
    if (selected) {
      dialog.append(make('p', `${selected.name} · ${selected.state}`));
      if (selected.kind === 'machine') dialog.append(make('p', `显存：${selected.memory || '未上报'} · 工作负载：${selected.workloads ?? '未上报'}`));
    } else dialog.append(make('p', '选择连接对象查看其状态；设计机柜尚未绑定实际机器。'));
    const roster = make('details'), rosterTitle = make('summary', `全部连接对象 · ${report.nodes.length}`);
    const table = make('table'), head = make('tr');
    ['对象','状态','显存','工作负载'].forEach(label => head.append(make('th',label))); table.append(head);
    for (const item of report.nodes) {
      const row = make('tr'); [item.name,item.state,item.memory || '未上报',item.workloads ?? '未上报'].forEach(value => row.append(make('td',String(value)))); table.append(row);
    }
    roster.append(rosterTitle, table);
    dialog.append(make('p','功耗、温度、吞吐率：暂无实测数据。远程服务不对应本地机柜。'),roster);
  } else if (report.slots.length) {
    const list = make('ul');
    for (const slot of report.slots) list.append(make('li',`${slot.name} · 容量 ${slot.capacity} · ${slot.actors.length} 位居民（位置投影，不代表执行）`));
    dialog.append(list);
  } else dialog.append(make('p','图纸设计方案，尚未绑定实际人员或工作。'));
  if (context.key === 'compute') {
    const planning = make('details'), summary = make('summary','高级 · 规划估算'), label = make('label','负载情景 '), input = make('input');
    Object.assign(input,{type:'range',min:0,max:100,value:50}); input.setAttribute('aria-label','规划负载情景'); label.append(input);
    const output = make('p'), notes = make('p','仅含服务器与机柜交换机的假设功率，不含制冷、UPS 损耗或设施总能耗。不是实时利用率。');
    const update = () => {
      const plan = globalThis.moonDataCenterReport(Number(input.value)); report.planning = plan;
      output.textContent = `${plan.load_percent}% 情景 · ${plan.racks} 柜 / ${plan.servers} 台 · IT ${plan.it_kw.toFixed(1)} kW · 余量 ${plan.headroom_kw.toFixed(1)} kW`;
    };
    input.oninput = update; update(); planning.append(summary,label,output,notes); dialog.append(planning);
  }
  const exportButton = make('button','导出 JSON');
  exportButton.onclick = () => {
    const url = URL.createObjectURL(new Blob([JSON.stringify(report,null,2)],{type:'application/json'}));
    const link = make('a'); link.href = url; link.download = 'moontown-space-report.json'; link.click(); setTimeout(() => URL.revokeObjectURL(url),1000);
  };
  detail.append(exportButton); dialog.append(detail); host.append(dialog);
  dialog.addEventListener('close', () => { dialog.remove(); if (opener?.isConnected) opener.focus(); }, {once:true});
  dialog.showModal(); close.focus();
}
