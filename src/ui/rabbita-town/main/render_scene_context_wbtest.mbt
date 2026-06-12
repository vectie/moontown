///|
test "render scene selection helpers expose selected node only" {
  let model = { ..init_model(), selection: Selection::Node("policy-hall") }
  assert_true(selected_node_key(model) is Some("policy-hall"))
  assert_true(selected_worker_id(model) is None)
}

///|
test "render scene selection helpers expose selected worker only" {
  let model = { ..init_model(), selection: Selection::Worker("worker-1") }
  assert_true(selected_node_key(model) is None)
  assert_true(selected_worker_id(model) is Some("worker-1"))
}

///|
test "render scene selection helpers treat overview as no selection" {
  let model = { ..init_model(), selection: Selection::Overview }
  assert_true(selected_node_key(model) is None)
  assert_true(selected_worker_id(model) is None)
}
