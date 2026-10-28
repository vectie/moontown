import * as THREE from 'three';
import {OrbitControls} from './vendor/OrbitControls.js';
import {RoomEnvironment} from './vendor/RoomEnvironment.js';
import {buildStudy, createMaterials} from './scene-adapter.js';
import {buildFlows} from './datacenter-flows.js';
import {viewerIcon} from './viewer-ui.js';
import {showSpaceReport} from './town-space-report.js';

// This is a renderer, not another application. MoonBit owns rooms, machines,
// selection, tasks and navigation. All architectural geometry remains MoonBit.
const memories = new Map();
const names = {site:'园区', hall:'机房', rack:'机柜', server:'服务器', board:'主板', room:'室内', g3:'G 座 · 三层'};
const node = (tag, className, text) => {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
};
function button(label, icon, action, compact = false) {
  const b = node('button'); b.type = 'button'; b.title = label; b.setAttribute('aria-label', label);
  if (icon) b.append(viewerIcon(icon));
  if (!compact) b.append(node('span', '', label));
  b.addEventListener('click', action); return b;
}
function disclosure(label) {
  const details = node('details'), summary = node('summary', '', label);
  details.append(summary); return details;
}

class TownSpace {
  constructor(host, payload, deliver) {
    this.host = host; this.payload = payload; this.deliver = deliver;
    this.key = payload.context.key; this.kind = payload.kind; this.events = new AbortController();
    this.state = memories.get(this.key) || {view:this.kind === 'compute' ? 'hall' : this.kind === 'g3' ? 'g3' : 'room', rack:'', slot:'', cameras:{}, orbit:false};
    this.reduced = matchMedia('(prefers-reduced-motion: reduce)');
    this.labels = new Map(); this.textures = []; this.actorMaterials = [];
    this.family = 'none'; this.playing = false; this.raf = 0; this.dirty = 0;
    this.frameTime = 0; this.time = 0; this.cutaway = true;
    this.buildUI(); this.start().catch(error => this.fail(error));
  }
  buildUI() {
    this.host.replaceChildren(); this.host.dataset.kind = this.kind;
    this.toolbar = node('div', 'space-toolbar');
    this.breadcrumb = node('nav', 'space-breadcrumb'); this.breadcrumb.setAttribute('aria-label', '空间层级');
    const tools = node('div', 'space-tools');
    this.orbit = button('环视', 'cube', () => {
      this.state.orbit = !this.state.orbit; this.syncOrbit(); this.invalidate();
    });
    this.report = button('空间报告', 'chart', () => showSpaceReport(this.host, this.reportContext()));
    tools.append(this.orbit, button('复位', 'reset', () => this.resetCamera(), true));
    this.toolbar.append(this.breadcrumb, tools);
    this.viewport = node('div', 'space-viewport');
    this.canvas = node('canvas', 'space-canvas'); this.canvas.tabIndex = 0;
    this.canvas.setAttribute('aria-label', '空间模型；方向键环视，加减键缩放，Home 复位；也可用下方对象列表选择');
    this.labelLayer = node('div', 'space-labels');
    this.loading = node('p', 'space-loading', '正在载入空间…'); this.loading.setAttribute('role', 'status');
    this.badge = node('span', 'space-badge', this.kind === 'indoor' ? '工作空间 · 示意布局' : '设计模型');
    this.viewport.append(this.canvas, this.labelLayer, this.badge, this.loading);
    this.selectionBar = node('div', 'space-selection-bar');
    this.selectionName = node('span', '', '点击空间对象');
    this.focus = button('定位', 'fit', () => this.focusSelected(), true); this.focus.disabled = true;
    this.enter = button('进入', 'indoor', () => this.enterSelected()); this.enter.hidden = true;
    this.selectionBar.append(this.selectionName, this.focus, this.enter);
    this.runtime = node('div', 'space-runtime');
    this.objectList = disclosure('对象列表'); this.objectList.className = 'space-objects';
    this.objectButtons = node('div', 'space-object-buttons'); this.objectList.append(this.objectButtons);
    this.advanced = disclosure('高级'); this.advanced.className = 'space-advanced';
    this.advanced.querySelector('summary').prepend(viewerIcon('sliders'));
    this.advanced.querySelector('summary').title = '空间报告、显示选项与完整模型审阅';
    const options = node('div', 'space-options');
    options.append(this.report, button('俯视', 'top', () => this.resetCamera(true)));
    this.check(options, '标签', false, value => { this.showLabels = value; this.invalidate(); });
    this.check(options, '剖切', true, value => { this.cutaway = value; this.applyLayers(); });
    this.check(options, '暖光', false, value => {
      if (!this.sun) return;
      this.sun.color.set(value ? '#ffd2a0' : '#fff0d5'); this.invalidate();
    });
    this.explodeLabel = node('label', '', '拆解 '); this.explode = node('input');
    Object.assign(this.explode, {type:'range', min:0, max:100, value:0});
    this.explode.setAttribute('aria-label', '散热器拆解距离');
    this.explode.oninput = () => this.applyLayers(); this.explodeLabel.append(this.explode); options.append(this.explodeLabel);
    this.flowPanel = node('div', 'space-flow-panel');
    const families = node('div', 'space-tools'); this.flowButtons = new Map();
    for (const [id, title, icon] of [['none','关闭','close'],['data','信号','network'],['power','供电','power'],['cooling','冷却','cooling']]) {
      const b = button(title, icon, () => this.setFamily(id)); families.append(b); this.flowButtons.set(id, b);
    }
    this.play = button('播放流动示意', 'play', () => {
      if (this.reduced.matches) return;
      this.playing = !this.playing;
      const label = this.playing ? '暂停流动示意' : '播放流动示意';
      this.play.replaceChildren(viewerIcon(this.playing ? 'pause' : 'play'),node('span','',label));
      this.play.setAttribute('aria-label',label); this.play.title = label;
      this.play.setAttribute('aria-pressed', String(this.playing)); this.invalidate();
    }); families.append(this.play);
    this.flowSelect = node('select'); this.flowSelect.setAttribute('aria-label', '流动路径');
    this.flowSelect.onchange = () => this.selectFlow(); this.flowDetail = node('p');
    this.flowPanel.append(families, this.flowSelect, this.flowDetail, node('small', '', '路径与流动为原理示意，不是实时任务或传感器数据。'));
    const review = node('a', '', '完整模型审阅 ↗');
    review.href = new URL(this.kind === 'compute' ? 'datacenter.html' : 'interior.html', import.meta.url).href;
    review.target = '_blank'; review.rel = 'noopener'; review.hidden = this.kind === 'indoor';
    this.advanced.append(options, this.flowPanel, review);
    this.host.append(this.toolbar, this.viewport, this.selectionBar, this.runtime, this.objectList, this.advanced);
    this.advanced.addEventListener('keydown', event => {
      if (event.key === 'Escape') { this.advanced.open = false; this.advanced.querySelector('summary').focus(); }
    });
    this.updateRuntime();
  }
  check(parent, label, checked, action) {
    const field = node('label'), input = node('input'); input.type = 'checkbox'; input.checked = checked;
    input.onchange = () => action(input.checked); field.append(input, node('span', '', label)); parent.append(field);
  }
  async start() {
    await import('./models.js'); if (this.disposed) return;
    this.renderer = new THREE.WebGLRenderer({canvas:this.canvas, antialias:true});
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
    this.renderer.shadowMap.enabled = true; this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping; this.renderer.toneMappingExposure = 1.02;
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.scene = new THREE.Scene(); this.scene.background = new THREE.Color('#e2e8dd');
    this.materials = createMaterials();
    const pmrem = new THREE.PMREMGenerator(this.renderer), room = new RoomEnvironment();
    this.environment = pmrem.fromScene(room, .04); this.scene.environment = this.environment.texture;
    this.scene.environmentIntensity = .38; pmrem.dispose(); room.dispose();
    this.scene.add(new THREE.HemisphereLight('#e7f2fc', '#adac8e', 2));
    this.sun = new THREE.DirectionalLight('#fff0d5', 3); this.sun.castShadow = true; this.sun.shadow.mapSize.set(1024,1024);
    this.scene.add(this.sun, this.sun.target);
    const fill = new THREE.DirectionalLight('#d9eaf4', 1.1); fill.position.set(1,1,-1); this.scene.add(fill);
    this.camera = new THREE.OrthographicCamera(-20,20,20,-20,.001,10000);
    this.controls = new OrbitControls(this.camera, this.canvas);
    this.controls.enableDamping = false; this.controls.minZoom = .4; this.controls.maxZoom = 12;
    this.controls.minPolarAngle = .01; this.controls.maxPolarAngle = Math.PI - .01;
    this.controls.addEventListener('change', () => this.invalidate()); this.syncOrbit();
    this.bindPicking();
    this.resizeObserver = new ResizeObserver(() => this.resize()); this.resizeObserver.observe(this.viewport);
    document.addEventListener('visibilitychange', () => {
      this.frameTime = 0; if (!document.hidden) this.invalidate();
    }, {signal:this.events.signal});
    this.reduced.addEventListener('change', () => {
      if (this.reduced.matches) { this.playing = false; this.play.setAttribute('aria-pressed','false'); }
      this.play.disabled = this.family === 'none' || this.reduced.matches;
    }, {signal:this.events.signal});
    this.canvas.addEventListener('webglcontextlost', event => {
      event.preventDefault(); this.playing = false; this.fail(new Error('图形上下文丢失，请重试'));
    }, {signal:this.events.signal});
    this.showView(this.state.view, true); this.loading.hidden = true;
  }
  dataFor(id) {
    if (this.kind === 'compute') return globalThis.moonDataCenter.views.find(v => v.study.id === id) || globalThis.moonDataCenter.views.find(v => v.study.id === 'hall');
    if (this.kind === 'indoor') return globalThis.moonTownInteriorStudy(this.payload);
    const data = globalThis.wenyuInteriorStudy;
    return {study:data.study, flows:[], entities:data.zones.map(z => ({
      id:z.id, name:z.name, kind:'房间', position:[((z.bounds[0]+z.bounds[2])/2-840)*.06,.3,((z.bounds[1]+z.bounds[3])/2-710)*.06],
      bounds:z.bounds, detail:`${z.area} · ${z.evidence} ${z.proposal}`, visit:'',
    }))};
  }
  saveCamera() {
    if (!this.current || !this.camera) return;
    this.state.cameras[this.state.view] = {position:this.camera.position.toArray(), target:this.controls.target.toArray(), zoom:this.camera.zoom};
  }
  showView(id, restore = false) {
    if (!this.scene) return;
    this.saveCamera(); this.clearModel();
    this.current = this.dataFor(id); if (!this.current) throw new Error('空间模型未构建');
    this.state.view = this.kind === 'g3' ? 'g3' : this.current.study.id;
    this.host.dataset.view = this.state.view;
    this.model = buildStudy(this.current.study, this.materials); this.scene.add(this.model.root);
    this.flows = buildFlows(this.current.flows, this.current.study.span); this.scene.add(this.flows.root);
    this.geometryKey = JSON.stringify([this.payload.title, this.payload.slots?.map(({actors,...slot}) => slot)]);
    this.entity = null; this.clearHighlight(); this.buildObjects(); this.buildBreadcrumb(); this.addActors();
    const span = this.current.study.span;
    this.sun.position.set(-span*.45,span*.85,span*.6); this.sun.target.position.fromArray(this.current.study.focus);
    Object.assign(this.sun.shadow.camera, {left:-span*.65,right:span*.65,top:span*.65,bottom:-span*.65,near:span*.001,far:span*3});
    this.sun.shadow.camera.updateProjectionMatrix(); this.sun.shadow.normalBias = span*.0002; this.sun.shadow.bias = -.00006;
    this.explode.value = 0; this.explodeLabel.hidden = !['server','board'].includes(this.state.view);
    this.flowPanel.hidden = this.kind !== 'compute'; this.applyLayers(); this.setFamily(this.family);
    this.resetCamera();
    const saved = this.state.cameras[this.state.view];
    if (restore && saved) {
      this.camera.position.fromArray(saved.position); this.controls.target.fromArray(saved.target); this.camera.zoom = saved.zoom;
      this.controls.update(); this.camera.updateProjectionMatrix();
    }
    this.syncSelection(); this.resize();
  }
  buildBreadcrumb() {
    this.breadcrumb.replaceChildren();
    if (this.kind !== 'compute') { this.breadcrumb.append(node('span', '', names[this.state.view])); return; }
    const path = [['site','园区'],['hall','机房'],['rack',this.state.rack || '机柜'],['server',this.state.slot || '服务器'],['board','主板']];
    const depth = path.findIndex(([id]) => id === this.state.view);
    for (const [i,[id,title]] of path.entries()) {
      if (i > depth) break;
      const b = button(title, '', () => { this.showView(id, true); this.emitView(); });
      if (i === depth) b.setAttribute('aria-current', 'location');
      this.breadcrumb.append(b);
    }
  }
  buildObjects() {
    this.objectButtons.replaceChildren(); this.labelLayer.replaceChildren(); this.labels.clear();
    this.objectList.querySelector('summary').textContent = `对象 · ${this.current.entities.length}`;
    for (const entity of this.current.entities) {
      const select = () => this.selectEntity(entity.id, true);
      const b = button(entity.name, '', select); b.dataset.entity = entity.id; this.objectButtons.append(b);
      const label = button(entity.name, '', select); label.className = 'space-label'; label.hidden = true;
      this.labelLayer.append(label); this.labels.set(entity.id, label);
    }
  }
  updateRuntime() {
    if (this.kind !== 'compute') { this.runtime.hidden = true; return; }
    const signature = JSON.stringify((this.payload.nodes || []).map(item => [item.id,item.kind]));
    if (signature !== this.runtimeKey) {
      this.runtimeKey = signature; this.runtimeButtons = new Map();
      this.runtime.replaceChildren(node('p', 'space-runtime-title', '连接对象 · 位置未绑定'));
      const group = node('div', 'space-runtime-nodes');
      for (const item of this.payload.nodes || []) {
        const b = button(item.name, item.kind === 'machine' ? 'server' : 'network', () => {
          const current = this.payload.nodes.find(n => n.id === item.id); if (!current) return;
          this.entity = null; this.clearHighlight(); this.emit({id:current.id,name:current.name,detail:current.state,visit:''}, 'runtime');
        });
        const status = node('small'); b.append(status); b.dataset.runtime = item.id;
        this.runtimeButtons.set(item.id,{button:b,status}); group.append(b);
      }
      this.runtime.append(group);
    }
    // Polling or selecting an endpoint must not remove the focused button.
    for (const item of this.payload.nodes || []) {
      const {button:b,status} = this.runtimeButtons.get(item.id);
      b.querySelector('span').textContent = item.name; b.title = item.name; b.setAttribute('aria-label',item.name);
      status.textContent = item.kind === 'route' ? '外部服务 · '+item.state : item.state;
      b.setAttribute('aria-pressed', String(this.payload.context.selection?.scope !== 'design' && item.id === this.payload.selected));
    }
  }
  update(payload) {
    const previous = this.payload;
    this.payload = payload; this.updateRuntime();
    if (!this.current) return;
    const key = JSON.stringify([payload.title, payload.slots?.map(({actors,...slot}) => slot)]);
    if (this.kind === 'indoor' && key !== this.geometryKey) this.showView('room', true);
    else {
      this.addActors();
      if (previous.selected !== payload.selected || JSON.stringify(previous.context.selection) !== JSON.stringify(payload.context.selection)) this.syncSelection();
    }
  }
  syncSelection() {
    const selection = this.payload.context.selection;
    const id = this.kind === 'indoor' ? this.payload.selected : selection?.scope === 'design' && selection.view === this.state.view ? selection.id : '';
    this.entity = this.current.entities.find(e => e.id === id) || null;
    this.paintSelection();
  }
  selectEntity(id, announce = false) {
    const entity = this.current.entities.find(e => e.id === id); if (!entity) return;
    this.entity = entity; this.paintSelection();
    if (announce) this.emit(entity, this.kind === 'indoor' ? 'runtime' : 'design');
  }
  emit(entity, scope) {
    this.deliver(JSON.stringify({key:this.key, view:this.state.view, id:entity.id, title:entity.name, detail:entity.detail || '', scope, visit:entity.visit || ''}));
  }
  emitView() {
    this.emit({id:'view:'+this.state.view, name:names[this.state.view], detail:'选择模型对象继续查看。'}, 'design');
  }
  clearHighlight() {
    if (!this.highlight) return;
    this.scene.remove(this.highlight); this.highlight.geometry.dispose(); this.highlight.material.dispose(); this.highlight = null;
  }
  paintSelection() {
    this.clearHighlight();
    this.host.dataset.selected = this.entity?.id || '';
    const hint = {site:'选择设施查看详情', hall:'点选机柜可逐层进入', rack:'选择服务器或配电设备', server:'选择部件查看详情', board:'选择部件查看详情'};
    this.selectionName.textContent = this.entity?.name || hint[this.state.view] || '点击房间或工作位';
    this.focus.disabled = !this.entity || !this.camera; this.enter.hidden = !this.entity?.visit || !this.model;
    if (this.entity?.visit) {
      const label = '进入'+names[this.entity.visit];
      this.enter.lastElementChild.textContent = label; this.enter.title = label; this.enter.setAttribute('aria-label',label);
    }
    this.objectButtons.querySelectorAll('button').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.entity === this.entity?.id)));
    for (const [id,label] of this.labels) label.classList.toggle('selected', id === this.entity?.id);
    if (this.entity && this.model) {
      const group = this.model.layers.get(this.entity.id);
      let bounds = group ? new THREE.Box3().setFromObject(group) : null;
      if (this.entity.bounds) {
        const [x0,z0,x1,z1] = this.entity.bounds;
        bounds = new THREE.Box3(new THREE.Vector3((x0-840)*.06,.05,(z0-710)*.06), new THREE.Vector3((x1-840)*.06,.12,(z1-710)*.06));
      }
      if (bounds && !bounds.isEmpty()) {
        this.highlight = new THREE.Box3Helper(bounds, 0x497358); this.highlight.material.depthTest = false;
        this.highlight.renderOrder = 30; this.scene.add(this.highlight);
      }
    }
    this.invalidate();
  }
  enterSelected() {
    if (!this.entity?.visit) return;
    const {id,visit} = this.entity;
    if (this.state.view === 'hall') this.state.rack = id;
    if (this.state.view === 'rack') this.state.slot = id;
    this.showView(visit); this.emitView();
    this.canvas.focus({preventScroll:true}); this.toolbar.scrollIntoView({block:'start',behavior:'instant'});
  }
  focusSelected() {
    if (!this.entity) return;
    const direction = this.camera.position.clone().sub(this.controls.target);
    this.controls.target.fromArray(this.entity.position); this.camera.position.copy(this.controls.target).add(direction);
    this.camera.zoom = this.kind === 'g3' ? 2.5 : 1.8; this.camera.updateProjectionMatrix(); this.controls.update(); this.invalidate();
  }
  syncOrbit() {
    if (this.controls) this.controls.enableRotate = this.state.orbit;
    this.orbit.setAttribute('aria-pressed', String(this.state.orbit));
    this.orbit.title = this.state.orbit ? '关闭自由环视' : '开启自由环视';
  }
  resetCamera(top = false) {
    if (!this.current) return;
    const span = this.current.study.span;
    this.controls.target.fromArray(this.kind === 'g3' ? [0,0,0] : this.current.study.focus);
    const offset = top ? new THREE.Vector3(0,span*1.5,.001) : this.kind === 'g3' ? new THREE.Vector3(25,76,83) : new THREE.Vector3().fromArray(this.current.study.detail_offset);
    this.camera.position.copy(this.controls.target).add(offset); this.camera.zoom = 1;
    this.camera.near = span/10000; this.camera.far = span*50; this.camera.updateProjectionMatrix(); this.controls.update(); this.invalidate();
  }
  resize() {
    if (!this.renderer || !this.current || this.disposed) return;
    const w = Math.max(this.viewport.clientWidth,1), h = Math.max(this.viewport.clientHeight,1), aspect = w/h;
    const span = this.current.study.span * (this.kind === 'g3' ? .36 : this.state.view === 'room' ? .4 : .56);
    const vertical = span * Math.max(1,1.3/aspect);
    Object.assign(this.camera, {left:-vertical*aspect,right:vertical*aspect,top:vertical,bottom:-vertical});
    this.camera.updateProjectionMatrix(); this.renderer.setSize(w,h,false); this.invalidate();
  }
  applyLayers() {
    if (!this.model) return;
    for (const id of ['shell','walls','lid']) {
      const layer = this.model.layers.get(id); if (!layer) continue;
      if (id === 'walls' && this.kind !== 'compute') layer.scale.y = this.cutaway ? .4 : 1;
      else layer.visible = !this.cutaway;
    }
    const ceiling = this.model.layers.get('ceiling'); if (ceiling) ceiling.visible = !this.cutaway;
    const sink = this.model.layers.get('heatsink'); if (sink) sink.position.y = Number(this.explode.value)/100*.12;
    this.paintSelection();
  }
  setFamily(id) {
    if (!this.flows) return;
    this.family = id; this.flowSelect.replaceChildren();
    for (const flow of this.current.flows.filter(f => f.family === id || id === 'cooling' && f.family === 'heat')) {
      const option = node('option', '', flow.title); option.value = flow.id; this.flowSelect.append(option);
    }
    this.flowButtons.forEach((b,key) => b.setAttribute('aria-pressed', String(key === id)));
    this.flowSelect.hidden = id === 'none'; this.play.disabled = id === 'none' || this.reduced.matches;
    if (id === 'none') {
      this.playing = false; this.play.setAttribute('aria-pressed','false');
      this.play.replaceChildren(viewerIcon('play'),node('span','','播放流动示意'));
      this.play.setAttribute('aria-label','播放流动示意'); this.play.title = '播放流动示意';
    }
    this.selectFlow();
  }
  selectFlow() {
    const flow = this.current.flows.find(f => f.id === this.flowSelect.value);
    this.flowDetail.textContent = flow?.detail || ''; this.flows.set(this.family, flow?.id || ''); this.invalidate();
  }
  addActors() {
    if (this.kind !== 'indoor' || !this.model) return;
    const key = JSON.stringify(this.payload.slots?.map(s => [s.id,s.actors]));
    if (key === this.actorKey) return; this.actorKey = key; this.clearActors();
    this.actors = new THREE.Group(); this.scene.add(this.actors);
    for (const slot of this.payload.slots || []) {
      const entity = this.current.entities.find(e => e.id === slot.id); if (!entity) continue;
      for (const [i,actor] of (slot.actors || []).slice(0,8).entries()) {
        const texture = new THREE.TextureLoader().load(actor.sprite, () => { if (!this.disposed) this.invalidate(); });
        texture.colorSpace = THREE.SRGBColorSpace; this.textures.push(texture);
        const material = new THREE.SpriteMaterial({map:texture, transparent:true, depthTest:true}); this.actorMaterials.push(material);
        const sprite = new THREE.Sprite(material); sprite.scale.set(1.3,1.65,1);
        sprite.position.set(entity.position[0]+(i%4-1.5)*.65,.85,entity.position[2]+1.2+Math.floor(i/4)*.55);
        sprite.userData.slot = slot.id; this.actors.add(sprite);
      }
    }
  }
  clearActors() {
    if (this.actors) this.scene.remove(this.actors);
    this.textures.forEach(t => t.dispose()); this.actorMaterials.forEach(m => m.dispose()); this.textures = []; this.actorMaterials = [];
  }
  bindPicking() {
    const signal = this.events.signal; let start;
    this.canvas.addEventListener('pointerdown', event => { start = [event.clientX,event.clientY]; }, {signal});
    this.canvas.addEventListener('pointerup', event => {
      if (!start || event.button !== 0 || Math.hypot(event.clientX-start[0],event.clientY-start[1]) > 5) return;
      const bounds = this.canvas.getBoundingClientRect(), ray = new THREE.Raycaster();
      ray.setFromCamera(new THREE.Vector2((event.clientX-bounds.left)/bounds.width*2-1,-(event.clientY-bounds.top)/bounds.height*2+1),this.camera);
      if (this.kind === 'g3') {
        const point = ray.ray.intersectPlane(new THREE.Plane(new THREE.Vector3(0,1,0),0),new THREE.Vector3());
        if (!point) return;
        const entity = this.current.entities.find(e => {
          const [x0,z0,x1,z1] = e.bounds, x = point.x/.06+840, z = point.z/.06+710;
          return x >= x0 && x <= x1 && z >= z0 && z <= z1;
        }); if (entity) this.selectEntity(entity.id,true); return;
      }
      for (const hit of ray.intersectObject(this.model.root,true)) {
        let id = hit.object.userData.entities?.[hit.instanceId], visible = true;
        for (let object = hit.object; object; object = object.parent) {
          if (!object.visible) visible = false;
          if (this.current.entities.some(e => e.id === object.name)) id = object.name;
        }
        if (visible && this.current.entities.some(e => e.id === id)) { this.selectEntity(id,true); break; }
      }
    }, {signal});
    this.canvas.addEventListener('keydown', event => {
      if (event.key === 'Home') { event.preventDefault(); this.resetCamera(); return; }
      if (event.key === 'Enter') { event.preventDefault(); this.enterSelected(); return; }
      const directions = {ArrowLeft:[-.12,0],ArrowRight:[.12,0],ArrowUp:[0,-.1],ArrowDown:[0,.1]};
      if (directions[event.key]) {
        event.preventDefault(); const spherical = new THREE.Spherical().setFromVector3(this.camera.position.clone().sub(this.controls.target));
        spherical.theta += directions[event.key][0]; spherical.phi = THREE.MathUtils.clamp(spherical.phi+directions[event.key][1],.02,Math.PI-.02);
        this.camera.position.copy(this.controls.target).add(new THREE.Vector3().setFromSpherical(spherical));
      }
      if (['+','=','-'].includes(event.key)) {
        event.preventDefault(); this.camera.zoom = THREE.MathUtils.clamp(this.camera.zoom*(event.key === '-' ? .87 : 1.15),.4,12); this.camera.updateProjectionMatrix();
      }
      this.controls.update(); this.invalidate();
    }, {signal});
  }
  invalidate() {
    if (this.disposed || !this.renderer || !this.current) return;
    this.dirty = 2; if (!this.raf && !document.hidden) this.raf = requestAnimationFrame(time => this.render(time));
  }
  render(time) {
    this.raf = 0; if (this.disposed || document.hidden) return;
    if (this.playing && !this.reduced.matches) this.time += this.frameTime ? Math.min((time-this.frameTime)/1000,.05) : 0;
    this.frameTime = time; this.controls.update(); this.flows.tick(this.time); this.renderer.render(this.scene,this.camera);
    const w = this.viewport.clientWidth, h = this.viewport.clientHeight, boxes = [];
    const entities = [...this.current.entities].sort((a,b) => Number(b.id === this.entity?.id)-Number(a.id === this.entity?.id));
    for (const entity of entities) {
      const label = this.labels.get(entity.id), point = new THREE.Vector3().fromArray(entity.position).project(this.camera);
      const x = (point.x*.5+.5)*w, y = (-point.y*.5+.5)*h, box = {x,y};
      const overlaps = boxes.some(b => Math.abs(b.x-x)<125 && Math.abs(b.y-y)<40);
      label.hidden = !(this.showLabels || entity.id === this.entity?.id) || point.z > 1 || point.z < -1 || x<65 || x>w-65 || y<60 || y>h-30 || overlaps;
      if (!label.hidden) boxes.push(box); label.style.left = x+'px'; label.style.top = y+'px';
    }
    this.host.dataset.drawCalls = this.renderer.info.render.calls;
    this.host.dataset.parts = this.current.study.parts.length;
    this.host.dataset.camera = this.camera.position.toArray().map(n => n.toFixed(3)).join(',');
    if (--this.dirty > 0 || this.playing && this.family !== 'none' && !this.reduced.matches) this.raf = requestAnimationFrame(t => this.render(t));
  }
  reportContext() {
    const runtimeSelection = this.payload.nodes?.find(item => item.id === this.payload.selected);
    const slotSelection = this.payload.slots?.find(item => item.id === this.payload.selected);
    const selected = this.payload.context.selection || (runtimeSelection || slotSelection ? {id:(runtimeSelection || slotSelection).id, title:(runtimeSelection || slotSelection).name, scope:'runtime'} : null);
    return {schema:'moontown.space-report.v1', scope:this.kind === 'indoor' ? 'semantic-layout' : 'design',
      context:{...this.payload.context, selection:selected, view:this.state.view, design_rack:this.state.rack || null, design_slot:this.state.slot || null},
      observed_at:this.payload.observed_at || null, nodes:this.payload.nodes || [],
      slots:this.payload.slots || [], physical_mapping:'unassigned'};
  }
  fail(error) {
    if (this.disposed) return;
    console.error('Town space', error); this.loading.hidden = false;
    this.loading.replaceChildren(node('span', '', '3D 暂不可用；对象列表与右侧工作仍可使用。'), button('重试', '', () => {
      const {host,payload,deliver} = this; this.dispose(); host.__townSpace = new TownSpace(host,payload,deliver);
    }));
    // The model contract can still supply a keyboard-accessible object list.
    if (!this.current && globalThis.moonDataCenter) { this.current = this.dataFor(this.state.view); this.buildObjects(); }
    this.objectList.open = true;
  }
  clearModel() {
    this.clearHighlight(); this.clearActors(); this.actorKey = null;
    if (this.model) { this.scene.remove(this.model.root); this.model.dispose(); }
    if (this.flows) { this.scene.remove(this.flows.root); this.flows.dispose(); }
  }
  dispose() {
    if (this.disposed) return; this.saveCamera(); memories.set(this.key, this.state);
    if (memories.size > 16) memories.delete(memories.keys().next().value);
    this.disposed = true; cancelAnimationFrame(this.raf); this.events.abort(); this.resizeObserver?.disconnect();
    this.clearModel(); this.controls?.dispose(); this.environment?.dispose();
    this.sun?.shadow.map?.dispose(); Object.values(this.materials || {}).forEach(m => m.dispose());
    this.renderer?.dispose(); this.renderer?.forceContextLoss();
    this.host.querySelectorAll('dialog').forEach(dialog => dialog.close());
  }
}

export function installTownSpaces(deliver) {
  const active = new Set();
  function scan() {
    for (const host of active) {
      if (!host.isConnected) { host.__townSpace?.dispose(); active.delete(host); }
    }
    for (const host of document.querySelectorAll('.town-space-host')) {
      const raw = host.dataset.space; if (host.__spaceRaw === raw) continue;
      let payload; try { payload = JSON.parse(raw); } catch { continue; }
      if (host.__townSpace?.key !== payload.context.key) {
        host.__townSpace?.dispose(); host.__townSpace = new TownSpace(host,payload,deliver); active.add(host);
      } else host.__townSpace.update(payload);
      host.__spaceRaw = raw;
    }
  }
  const observer = new MutationObserver(scan);
  observer.observe(document.getElementById('app') || document.body, {childList:true,subtree:true,attributes:true,attributeFilter:['data-space']});
  scan();
}
