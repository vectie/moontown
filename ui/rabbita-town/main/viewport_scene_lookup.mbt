///|
fn scene_node_by_key(
  scene : @ui.SceneRenderModel,
  key : String,
) -> @ui.SceneRenderNode {
  for node in scene.nodes {
    if node.key == key {
      return node
    }
  }
  scene.nodes[0]
}
