///|
pub(all) enum MobilityMode {
  Pedestrian
  Bicycle
  ServiceVehicle
  Transit
} derive(Debug, Eq)

///|
pub(all) enum RoadClass {
  Arterial
  Collector
  Local
  Service
  Footpath
  Bridge
} derive(Debug, Eq)

///|
pub(all) struct RoadNode {
  id : StableId
  grid : GridPosition
  position : WorldPoint
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn road_node(
  id : StableId,
  grid : GridPosition,
  position : WorldPoint,
  provenance : Provenance,
) -> RoadNode {
  { id, grid, position, provenance }
}

///|
pub(all) struct RoadSegment {
  id : StableId
  from_node_id : StableId
  to_node_id : StableId
  centerline : ReadOnlyArray[WorldPoint]
  road_class : RoadClass
  width_meters : Double
  mobility : ReadOnlyArray[MobilityMode]
  bidirectional : Bool
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn road_segment(
  id : StableId,
  from_node_id : StableId,
  to_node_id : StableId,
  centerline : ArrayView[WorldPoint],
  road_class : RoadClass,
  width_meters : Double,
  mobility : ArrayView[MobilityMode],
  provenance : Provenance,
  bidirectional? : Bool = true,
) -> RoadSegment {
  {
    id,
    from_node_id,
    to_node_id,
    centerline: freeze(centerline),
    road_class,
    width_meters,
    mobility: freeze(mobility),
    bidirectional,
    provenance,
  }
}

///|
pub fn RoadSegment::supports(self : RoadSegment, mode : MobilityMode) -> Bool {
  self.mobility.contains(mode)
}

///|
pub(all) struct RoadNetwork {
  nodes : ReadOnlyArray[RoadNode]
  segments : ReadOnlyArray[RoadSegment]
  access_anchor_node_ids : ReadOnlyArray[StableId]
} derive(Debug, Eq)

///|
pub fn road_network(
  nodes : ArrayView[RoadNode],
  segments : ArrayView[RoadSegment],
  access_anchor_node_ids : ArrayView[StableId],
) -> RoadNetwork {
  {
    nodes: freeze(nodes),
    segments: freeze(segments),
    access_anchor_node_ids: freeze(access_anchor_node_ids),
  }
}

///|
pub fn RoadNetwork::find_node(self : RoadNetwork, id : StableId) -> RoadNode? {
  self.nodes.search_by(node => node.id == id).map(index => self.nodes[index])
}

///|
pub fn RoadNetwork::find_segment(
  self : RoadNetwork,
  id : StableId,
) -> RoadSegment? {
  self.segments
  .search_by(segment => segment.id == id)
  .map(index => self.segments[index])
}

///|
pub fn RoadNetwork::neighbors(
  self : RoadNetwork,
  node_id : StableId,
  mode? : MobilityMode = Pedestrian,
) -> ReadOnlyArray[StableId] {
  let neighbors : Array[StableId] = []
  let seen : Map[StableId, Bool] = Map([])
  for segment in self.segments {
    if segment.supports(mode) {
      let next = if segment.from_node_id == node_id {
        Some(segment.to_node_id)
      } else if segment.bidirectional && segment.to_node_id == node_id {
        Some(segment.from_node_id)
      } else {
        None
      }
      match next {
        Some(id) if !seen.contains(id) => {
          seen[id] = true
          neighbors.push(id)
        }
        _ => ()
      }
    }
  }
  freeze(neighbors)
}

///|
/// Returns the shortest node path through the typed mobility graph. This is
/// the navigation primitive shared by renderers and simulations; callers must
/// start and finish at semantic portal node IDs rather than inventing nearby
/// screen-space road cells.
pub fn RoadNetwork::shortest_path(
  self : RoadNetwork,
  origin : StableId,
  destination : StableId,
  mode? : MobilityMode = Pedestrian,
) -> ReadOnlyArray[RoadNode]? {
  let origin_node = match self.find_node(origin) {
    Some(node) => node
    None => return None
  }
  if self.find_node(destination) is None {
    return None
  }
  if origin == destination {
    return Some(freeze([origin_node]))
  }
  // Build adjacency once for this query. `neighbors` remains useful for small
  // diagnostics, while navigation avoids rescanning every segment per BFS
  // node on the full Wenyu graph.
  let adjacency : Map[StableId, Array[StableId]] = Map([])
  for node in self.nodes {
    adjacency[node.id] = []
  }
  for segment in self.segments {
    if !segment.supports(mode) {
      continue
    }
    match adjacency.get(segment.from_node_id) {
      Some(items) => items.push(segment.to_node_id)
      None => ()
    }
    if segment.bidirectional {
      match adjacency.get(segment.to_node_id) {
        Some(items) => items.push(segment.from_node_id)
        None => ()
      }
    }
  }
  let visited : Map[StableId, Bool] = Map([])
  let previous : Map[StableId, StableId] = Map([])
  let queue : Array[StableId] = [origin]
  visited[origin] = true
  let mut cursor = 0
  let mut reached = false
  while cursor < queue.length() && !reached {
    let current = queue[cursor]
    cursor += 1
    match adjacency.get(current) {
      None => ()
      Some(next_nodes) =>
        for next in next_nodes {
          if visited.contains(next) {
            continue
          }
          visited[next] = true
          previous[next] = current
          if next == destination {
            reached = true
            break
          }
          queue.push(next)
        }
    }
  }
  if !reached {
    return None
  }
  let reversed : Array[StableId] = [destination]
  let mut path_cursor = destination
  while path_cursor != origin {
    match previous.get(path_cursor) {
      None => return None
      Some(parent) => {
        reversed.push(parent)
        path_cursor = parent
      }
    }
  }
  let path : Array[RoadNode] = []
  let mut index = reversed.length() - 1
  while index >= 0 {
    match self.find_node(reversed[index]) {
      Some(node) => path.push(node)
      None => return None
    }
    index -= 1
  }
  Some(freeze(path))
}

///|
/// Returns whether two nodes are connected through the same typed network used
/// by rendering and navigation. Directionality and mobility are both honored.
pub fn RoadNetwork::is_reachable(
  self : RoadNetwork,
  origin : StableId,
  destination : StableId,
  mode? : MobilityMode = Pedestrian,
) -> Bool {
  if self.find_node(origin) is None || self.find_node(destination) is None {
    return false
  }
  if origin == destination {
    return true
  }
  let visited : Map[StableId, Bool] = Map([])
  visited[origin] = true
  let queue : Array[StableId] = [origin]
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor += 1
    for next in self.neighbors(current, mode~) {
      if next == destination {
        return true
      }
      if !visited.contains(next) {
        visited[next] = true
        queue.push(next)
      }
    }
  }
  false
}

///|
pub fn RoadNetwork::is_reachable_from_anchor(
  self : RoadNetwork,
  destination : StableId,
  mode? : MobilityMode = Pedestrian,
) -> Bool {
  self.access_anchor_node_ids.any(anchor => {
    self.is_reachable(anchor, destination, mode~)
  })
}
