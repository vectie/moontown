///|
extern "js" fn building_public_baseline() -> Bool =
  #| () => typeof process !== 'undefined' && !!process.versions?.node && typeof globalThis.__townBakePublicBaseline === 'function'

///|
extern "js" fn publish_build_baseline(
  world : @energy_valley_contract.CompiledTownWorld,
  issues : Array[@energy_valley_contract.ContractIssue],
) -> Unit =
  #| (world,issues) => globalThis.__townBakePublicBaseline({world,issues})

///|
extern "js" fn packaged_public_world(
  seed : Int32,
) -> @energy_valley_contract.CompiledTownWorld? =
  #| seed => {
  #|   if(globalThis.__townBaselineInput && typeof townRestorePublishedWorld === 'function') townRestorePublishedWorld();
  #|   return globalThis.__townPublicBaseline?.world.layout_seed === seed ? globalThis.__townPublicBaseline.world : undefined;
  #| }

///|
extern "js" fn packaged_public_world_issues() -> Array[
  @energy_valley_contract.ContractIssue,
] =
  #| () => globalThis.__townPublicBaseline.issues
