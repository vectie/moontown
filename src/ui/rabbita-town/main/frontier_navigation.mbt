///|
/// Opt-in exterior expansion. The accepted core is always rendered unchanged.
extern "js" fn frontier_requested() -> Bool =
  #| () => new URLSearchParams(globalThis.location?.search || '').get('frontier') === '1'

///|
let frontier_seed = 20261028

///|
let frontier_navigation_chunks : Map[String, @frontier.Chunk] = Map([])

///|
let frontier_graph_cache : Map[String, @landmark_routes.Graph] = Map([])

///|
/// Shared geometry nodes join chunks; entrances split their actual road edge.
/// No proximity-based junction creation or invented cross-water shortcuts.
fn frontier_compile_graph(
  chunks : Array[@frontier.Chunk],
) -> @landmark_routes.Graph {
  let nodes : Map[String, @landmark_routes.Node] = Map([])
  let edges : Array[@landmark_routes.Edge] = []
  let add = fn(p : @frontier.Point) {
    let id = @frontier.node_id(p)
    nodes[id] = { id, x: p.x, y: p.y, }
    id
  }
  for chunk in chunks {
    for road in chunk.roads {
      let splits : Array[@frontier.Point] = [road.a, road.b]
      for lot in chunk.lots {
        if @frontier.distance(
            @frontier.nearest_on(road, lot.frontage),
            lot.frontage,
          ) <
          0.002 {
          splits.push(lot.frontage)
        }
      }
      splits.sort_by((a, b) => {
        @frontier.distance(road.a, a).compare(@frontier.distance(road.a, b))
      })
      for i in 1..<splits.length() {
        let a = add(splits[i - 1])
        let b = add(splits[i])
        if a != b {
          edges.push({ a, b, bridge: road.bridge, })
        }
      }
    }
    for lot in chunk.lots {
      edges.push({ a: add(lot.frontage), b: add(lot.entrance), bridge: false, })
    }
  }
  { nodes: nodes.values().collect(), edges, }
}

///|
fn street_active_graph(position : (Double, Double)?) -> @landmark_routes.Graph? {
  if !frontier_requested() || !frontier_boundary_prepare() {
    return town_landmark_graph.get("active")
  }
  guard town_landmark_graph.get("active") is Some(core) else { return None }
  let p = position.unwrap_or((128, 72))
  let cx = @frontier.coordinate(p.0)
  let cy = @frontier.coordinate(p.1)
  let key = "\{cx}:\{cy}"
  match frontier_graph_cache.get(key) {
    Some(g) => Some(g)
    None => {
      let chunks : Map[String, @frontier.Chunk] = Map([])
      for c in frontier_gate_chunks {
        chunks["\{c.x}:\{c.y}"] = c
      }
      let next : Map[String, @frontier.Chunk] = Map([])
      for y in (cy - 1)..<=(cy + 1) {
        for x in (cx - 1)..<=(cx + 1) {
          let id = "\{x}:\{y}"
          let c = frontier_navigation_chunks
            .get(id)
            .unwrap_or_else(() => frontier_generate(x, y))
          next[id] = c
          chunks[id] = c
        }
      }
      frontier_navigation_chunks.clear()
      for id, c in next {
        frontier_navigation_chunks[id] = c
      }
      let graph = frontier_merge_graph(
        core,
        frontier_compile_graph(chunks.values().collect()),
        frontier_boundaries[0],
      )
      frontier_graph_cache.clear()
      frontier_graph_cache[key] = graph
      Some(graph)
    }
  }
}
