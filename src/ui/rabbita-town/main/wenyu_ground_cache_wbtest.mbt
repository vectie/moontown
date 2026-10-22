///|
extern "js" fn ground_cache_test_context() -> @dom.CanvasRenderingContext2D =
  #| () => {
  #|   globalThis.__groundTestSaved={document:globalThis.document,location:globalThis.location,cache:globalThis.__wenyuGroundCache,active:globalThis.__wenyuGroundCacheActive};
  #|   const ctx={getTransform:()=>({a:2,b:0}),setTransform(){},drawImage(){}};
  #|   globalThis.document={documentElement:{dataset:{}},createElement:()=>({getContext:()=>ctx})};
  #|   globalThis.location={search:''};delete globalThis.__wenyuGroundCache;
  #|   return ctx;
  #| }

///|
extern "js" fn ground_cache_test_world() -> @energy_valley_contract.CompiledTownWorld =
  #| () => ({})

///|
extern "js" fn ground_cache_test_restore() -> Unit =
  #| () => {
  #|   const saved=globalThis.__groundTestSaved;
  #|   globalThis.document=saved.document;globalThis.location=saved.location;
  #|   globalThis.__wenyuGroundCache=saved.cache;globalThis.__wenyuGroundCacheActive=saved.active;
  #|   delete globalThis.__groundTestSaved;
  #| }

///|
test "ground cache preserves pan overscan and invalidates visual inputs" {
  let context = ground_cache_test_context()
  defer ground_cache_test_restore()
  let world = ground_cache_test_world()
  assert_false(
    wenyu_ground_cache_restore(context, world, "v1", 1000, 800, 0, 0, 0.1),
  )
  assert_eq(wenyu_ground_cache_padding(), 192)
  wenyu_ground_cache_present(context)
  assert_true(
    wenyu_ground_cache_restore(context, world, "v1", 1000, 800, 100, 0, 0.1),
  )
  assert_false(
    wenyu_ground_cache_restore(context, world, "v1", 1000, 800, 2000, 0, 0.1),
  )
  wenyu_ground_cache_present(context)
  assert_false(
    wenyu_ground_cache_restore(context, world, "v2", 1000, 800, 2000, 0, 0.1),
  )
  wenyu_ground_cache_present(context)
  assert_false(
    wenyu_ground_cache_restore(
      context,
      ground_cache_test_world(),
      "v2",
      1000,
      800,
      2000,
      0,
      0.1,
    ),
  )
  wenyu_ground_cache_present(context)
  assert_false(
    wenyu_ground_cache_restore(context, world, "v2", 1200, 800, 2000, 0, 0.1),
  )
  // Preserve the original animated water renderer at close zoom.
  assert_false(
    wenyu_ground_cache_restore(context, world, "v2", 1000, 800, 0, 0, 0.95),
  )
  assert_eq(wenyu_ground_cache_padding(), 0)
  // A second full-size surface must not consume unbounded high-DPI memory.
  assert_false(
    wenyu_ground_cache_restore(context, world, "v2", 8000, 8000, 0, 0, 0.1),
  )
  assert_eq(wenyu_ground_cache_padding(), 0)
}
