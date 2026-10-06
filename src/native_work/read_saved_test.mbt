///|
async test "saved native observation preserves bytes and never initializes locks or missing roots" {
  let root = @fs.tmpdir(prefix="native-read-saved-")
  let path = root + "/native.json"
  let bytes = "{\"schema\":\"moontown.native-work.v1\",\"revision\":0,\"work\":[]}\n"
  @fs.write_file(path, bytes, create_mode=CreateNew)
  let state = @native_work.read_saved(path~)
  assert_eq(state.revision, 0)
  assert_eq(@fs.read_file(path).text(), bytes)
  assert_false(@fs.exists(path + ".lock"))
  let missing = root + "/missing/state.json"
  try @native_work.read_saved(path=missing) catch {
    error => assert_true(error.to_string().contains("saved_state_missing"))
  } noraise {
    _ => fail("missing state must not be initialized")
  }
  assert_false(@fs.exists(root + "/missing"))
}
