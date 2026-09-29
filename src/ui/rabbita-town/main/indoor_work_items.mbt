///|
/// Include both ends of a handoff and retained outcomes. A completed work item
/// must not disappear from the room when it moves from tasks to history.
fn indoor_work_items(
  model : Model,
  building : GoldenValleyBuilding,
) -> Array[EnergyValleyRuntimeWorkItem] {
  let result : Array[EnergyValleyRuntimeWorkItem] = []
  let key = golden_valley_building_module_key(building)
  guard !key.is_empty() &&
    model.energy_valley_runtime.projection is Some(projection) else {
    return result
  }
  let all = projection.tasks.copy()
  for task in projection.history.unwrap_or([]) {
    all.push(task)
  }
  for task in all {
    if (
        task.buildingModuleKey == key ||
        task.originBuildingModuleKey == Some(key) ||
        task.destinationBuildingModuleKey == Some(key)
      ) &&
      !result.any(existing => existing.id == task.id) {
      result.push(task)
    }
  }
  result
}
