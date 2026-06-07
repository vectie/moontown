///|
fn unique_paths(values : Array[String]) -> Array[String] {
  let next : Array[String] = []
  for value in values {
    if !next.contains(value) {
      next.push(value)
    }
  }
  next
}

///|
fn unique_nonblank_paths(values : Array[String]) -> Array[String] {
  let next : Array[String] = []
  for value in values {
    let path = value.trim().to_owned()
    if !path.is_blank() && !next.contains(path) {
      next.push(path)
    }
  }
  next
}
