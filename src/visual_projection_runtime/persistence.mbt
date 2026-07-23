///|
pub async fn persist_visual_projection(
  state : @core.TownState,
  snapshot_path : String,
  tick? : Int = @visual_projection.visual_projection_tick(state),
  decorator_manifest_path? : String = default_visual_decorator_manifest_path(),
) -> Unit {
  let decorator = load_visual_decorator_config(decorator_manifest_path)
  let projection = @visual_projection.build_visual_projection_with_decorator(
    state,
    decorator,
    tick~,
  )
  write_text_file(
    @visual_projection.default_visual_projection_path(snapshot_path),
    projection.to_json().stringify(),
  )
}

///|
pub fn default_visual_decorator_manifest_path() -> String {
  "src/ui/assets/tilemap/modules/wenyu-town-modules.json"
}

///|
async fn load_visual_decorator_config(
  path : String,
) -> @visual_projection.VisualDecoratorConfig {
  if !@fs.exists(path) {
    return @visual_projection.VisualDecoratorConfig::empty()
  }
  let text = @fs.read_file(path).text() catch {
    _ => return @visual_projection.VisualDecoratorConfig::empty()
  }
  let parsed = @json.parse(text) catch {
    _ => return @visual_projection.VisualDecoratorConfig::empty()
  }
  @visual_projection.visual_decorator_config_from_module_manifest(parsed) catch {
    _ => @visual_projection.VisualDecoratorConfig::empty()
  }
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}
