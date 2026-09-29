///|
pub(all) struct Point {
  x : Double
  y : Double
} derive(ToJson, FromJson, Debug)

///|
pub(all) struct Node {
  id : String
  x : Double
  y : Double
} derive(FromJson)

///|
pub(all) struct Edge {
  a : String
  b : String
  bridge : Bool
} derive(FromJson)

///|
pub(all) struct Graph {
  nodes : Array[Node]
  edges : Array[Edge]
} derive(FromJson)

///|
pub fn distance(a : Point, b : Point) -> Double {
  ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).sqrt()
}

///|
pub fn nearest(g : Graph, p : Point, radius : Double) -> String? {
  let mut best = None
  let mut d = radius
  for n in g.nodes {
    let candidate = distance(p, { x: n.x, y: n.y, })
    if candidate < d {
      d = candidate
      best = Some(n.id)
    }
  }
  best
}

///|
/// Adjacency comes ONLY from shared OSM node IDs. A picture intersection is
/// never a junction; bridge edges remain traversable without joining the bank.
pub fn route(g : Graph, start : String, goal : String) -> Array[Point]? {
  let index : Map[String, Int] = Map([])
  for i, n in g.nodes {
    index[n.id] = i
  }
  guard index.get(start) is Some(s) && index.get(goal) is Some(t) else {
    return None
  }
  let adj : Array[Array[Int]] = Array::makei(g.nodes.length(), _ => [])
  for e in g.edges {
    if index.get(e.a) is Some(a) && index.get(e.b) is Some(b) {
      adj[a].push(b)
      adj[b].push(a)
    }
  }
  let ds = Array::make(g.nodes.length(), 1.0e30)
  let prev = Array::make(g.nodes.length(), -1)
  let seen = Array::make(g.nodes.length(), false)
  ds[s] = 0
  for _ in 0..<g.nodes.length() {
    let mut at = -1
    let mut best = 1.0e30
    for i, d in ds {
      if !seen[i] && d < best {
        at = i
        best = d
      }
    }
    if at < 0 {
      return None
    }
    if at == t {
      let result : Array[Point] = []
      let mut i = t
      while i >= 0 {
        let n = g.nodes[i]
        result.push({ x: n.x, y: n.y, })
        i = prev[i]
      }
      return Some(result.rev())
    }
    seen[at] = true
    for next in adj[at] {
      let a = g.nodes[at]
      let b = g.nodes[next]
      let d = best + distance({ x: a.x, y: a.y, }, { x: b.x, y: b.y, })
      if d < ds[next] {
        ds[next] = d
        prev[next] = at
      }
    }
  }
  None
}
