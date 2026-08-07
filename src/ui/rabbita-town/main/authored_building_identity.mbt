///|
let golden_valley_authored_building_prefix = "authored-building-"

///|
fn golden_valley_nonempty_authored_id(
  building : GoldenValleyBuilding,
) -> String? {
  match building.authored_id {
    Some(value) if !value.trim().is_empty() => Some(value.trim().to_owned())
    _ => None
  }
}

///|
fn golden_valley_authored_id_sequence(value : String) -> Int? {
  let suffix = match
    value.strip_prefix(golden_valley_authored_building_prefix) {
    Some(value) if !value.is_empty() => value
    _ => return None
  }
  let mut result = 0
  for char in suffix {
    if char < '0' || char > '9' {
      return None
    }
    result = result * 10 + char.to_int() - '0'.to_int()
  }
  if result > 0 {
    Some(result)
  } else {
    None
  }
}

///|
fn golden_valley_authored_id_for_sequence(sequence : Int) -> String {
  "\{golden_valley_authored_building_prefix}\{sequence}"
}

///|
fn golden_valley_authored_id_in_use(
  buildings : Array[GoldenValleyBuilding],
  authored_id : String,
) -> Bool {
  buildings.any(building => {
    golden_valley_nonempty_authored_id(building) == Some(authored_id)
  })
}

///|
fn golden_valley_next_free_authored_sequence(
  buildings : Array[GoldenValleyBuilding],
  requested : Int,
) -> Int {
  let mut sequence = requested.max(1)
  while golden_valley_authored_id_in_use(
          buildings,
          golden_valley_authored_id_for_sequence(sequence),
        ) {
    sequence = sequence + 1
  }
  sequence
}

///|
fn golden_valley_next_free_authored_sequence_avoiding(
  buildings : Array[GoldenValleyBuilding],
  reserved_ids : Array[String],
  requested : Int,
) -> Int {
  let mut sequence = requested.max(1)
  while golden_valley_authored_id_in_use(
          buildings,
          golden_valley_authored_id_for_sequence(sequence),
        ) ||
        reserved_ids.contains(golden_valley_authored_id_for_sequence(sequence)) {
    sequence = sequence + 1
  }
  sequence
}

///|
fn golden_valley_assign_authored_building_id(
  existing : Array[GoldenValleyBuilding],
  next_sequence : Int,
  building : GoldenValleyBuilding,
) -> (GoldenValleyBuilding, Int) {
  match golden_valley_nonempty_authored_id(building) {
    Some(authored_id) if !golden_valley_authored_id_in_use(
        existing, authored_id,
      ) => {
      let following = match golden_valley_authored_id_sequence(authored_id) {
        Some(sequence) => next_sequence.max(sequence + 1)
        None => next_sequence.max(1)
      }
      ({ ..building, authored_id: Some(authored_id) }, following)
    }
    _ => {
      let sequence = golden_valley_next_free_authored_sequence(
        existing, next_sequence,
      )
      (
        {
          ..building,
          authored_id: Some(golden_valley_authored_id_for_sequence(sequence)),
        },
        sequence + 1,
      )
    }
  }
}

///|
fn golden_valley_migrate_authored_buildings(
  buildings : Array[GoldenValleyBuilding],
  stored_next_sequence : Int?,
) -> (Array[GoldenValleyBuilding], Int) {
  // Reserve every explicit legacy ID before filling gaps. Otherwise an older
  // ID-less row appearing first in the save could accidentally steal the
  // durable identity of a later row.
  let reserved_ids : Array[String] = []
  let mut next_sequence = stored_next_sequence.unwrap_or(1).max(1)
  for building in buildings {
    match golden_valley_nonempty_authored_id(building) {
      Some(authored_id) => {
        if !reserved_ids.contains(authored_id) {
          reserved_ids.push(authored_id)
        }
        match golden_valley_authored_id_sequence(authored_id) {
          Some(sequence) => next_sequence = next_sequence.max(sequence + 1)
          None => ()
        }
      }
      None => ()
    }
  }
  let migrated : Array[GoldenValleyBuilding] = []
  let preserved_ids : Array[String] = []
  for building in buildings {
    match golden_valley_nonempty_authored_id(building) {
      Some(authored_id) if !preserved_ids.contains(authored_id) => {
        migrated.push({ ..building, authored_id: Some(authored_id) })
        preserved_ids.push(authored_id)
      }
      _ => {
        let sequence = golden_valley_next_free_authored_sequence_avoiding(
          migrated, reserved_ids, next_sequence,
        )
        migrated.push({
          ..building,
          authored_id: Some(golden_valley_authored_id_for_sequence(sequence)),
        })
        next_sequence = sequence + 1
      }
    }
  }
  (migrated, next_sequence)
}

///|
fn golden_valley_migrate_energy_save(
  save : EnergyValleySave,
) -> EnergyValleySave {
  let (buildings, next_sequence) = golden_valley_migrate_authored_buildings(
    save.buildings,
    save.next_authored_building_sequence,
  )
  { ..save, buildings, next_authored_building_sequence: Some(next_sequence) }
}
