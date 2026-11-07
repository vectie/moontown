///|
#borrow
extern "C" fn preview_fixture() -> Bytes = "moontown_preview_test_png"

///|
async test "backfill preserves originals and settlement state and repairs a missing thumbnail" {
  let root = @fs.tmpdir(prefix="creative-previews-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/config.json"
  let config = fixture_config()
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateNew,
  )
  let state = submitted()
  save(path, state)
  let before = @fs.read_file(path).binary()
  let id = state.generations[0].id
  @fs.mkdir(path + ".images", permission=0o700)
  let original = preview_fixture()
  @fs.write_file(
    preview_path(path, id, Original),
    original,
    create_mode=CreateNew,
  )
  assert_true(process_previews(path, config_path))
  assert_eq(
    @image_preview.dimensions(
      image(id, Some("alice"), path, config_path, variant=Thumbnail),
    ),
    Some((384, 192)),
  )
  assert_eq(
    @image_preview.dimensions(
      image(id, Some("alice"), path, config_path, variant=Preview),
    ),
    Some((768, 384)),
  )
  assert_eq(@fs.read_file(path).binary(), before)
  assert_eq(@fs.read_file(preview_path(path, id, Original)).binary(), original)
  assert_false(process_previews(path, config_path))
  let thumb = preview_path(path, id, Thumbnail)
  @fs.rename(thumb, thumb + ".old")
  assert_true(
    try {
      ignore(image(id, Some("alice"), path, config_path, variant=Thumbnail))
      false
    } catch {
      Unavailable => true
      _ => false
    },
  )
  assert_true(process_previews(path, config_path))
  assert_eq(
    @fs.read_file(thumb).binary(),
    @fs.read_file(thumb + ".old").binary(),
  )
  assert_eq(@fs.read_file(path).binary(), before)
}
