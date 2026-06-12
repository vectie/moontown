///|
fn render_node(
  dispatch : Dispatch[Msg],
  node : @ui.SceneRenderNode,
  selected : Bool,
) -> @rabbita.Html {
  let style = [
    "left: \{scene_node_left(node)}px",
    "top: \{scene_node_top(node)}px",
    "width: \{scene_node_width(node)}px",
    "height: \{scene_node_height(node)}px",
  ]
  let class_name = "scene-card-button" +
    class_suffix_when(selected, " selected")
  article(class="scene-node \{node.class_name}", style~, [
    div(
      class="asset-stack",
      node.asset_paths.map(path => render_asset(path, node.title)),
    ),
    button(class=class_name, on_click=dispatch(SelectNode(node.key)), [
      h3(node.title),
      p(class="scene-node-key", node.key),
      div(class="scene-lines", node.lines.map(line => p(line))),
    ]),
  ])
}

///|
fn is_mayor_scene_node(node : @ui.SceneRenderNode) -> Bool {
  node.key == "book-town" ||
  node.key == "book-moontown" ||
  node.key == "book-mayor"
}
