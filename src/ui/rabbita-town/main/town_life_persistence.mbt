///|
let town_life_phone_capacity = 80

///|
let town_life_report_capacity = 30

///|
fn town_life_default_save() -> TownLifeSave {
  {
    player: None,
    player_position: None,
    player_stamp: None,
    player_position_stamp: None,
    writer_counters: Some([]),
    spark: 0,
    spark_floor: Some(0),
    spark_awards: Some([]),
    quest_done: [],
    phone_log: [],
    phone_events: Some([]),
    phone_prune_watermarks: Some([]),
    posts: [],
    post_reset_stamp: None,
    post_tombstones: Some([]),
    analytics: [],
    analytics_events: Some([]),
    analytics_prune_watermarks: Some([]),
    ecosystem_attention_receipts: Some([]),
    attention_counters: Some([]),
    attention_prune_watermarks: Some([]),
    ops_reports: Some([]),
    ops_report_events: Some([]),
    ops_report_prune_watermarks: Some([]),
    last_report_tick: 0,
    checkin_day: -1,
    world_states: Some([]),
    post_generation: Some(0),
    deleted_post_ids: Some([]),
  }
}

///|
fn town_life_decode_save(text : String) -> TownLifeSave? {
  if text.is_empty() {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn town_life_stamp_compare(
  left : TownLifeCausalStamp,
  right : TownLifeCausalStamp,
) -> Int {
  if left.lamport < right.lamport {
    -1
  } else if left.lamport > right.lamport {
    1
  } else {
    left.writer_id.compare(right.writer_id)
  }
}

///|
fn town_life_stamp_after(
  left : TownLifeCausalStamp,
  right : TownLifeCausalStamp,
) -> Bool {
  town_life_stamp_compare(left, right) > 0
}

///|
fn town_life_optional_stamp_max(
  left : TownLifeCausalStamp?,
  right : TownLifeCausalStamp?,
) -> TownLifeCausalStamp? {
  match (left, right) {
    (None, value) | (value, None) => value
    (Some(a), Some(b)) =>
      if town_life_stamp_after(a, b) {
        Some(a)
      } else {
        Some(b)
      }
  }
}

///|
fn town_life_optional_stamp_equal(
  left : TownLifeCausalStamp?,
  right : TownLifeCausalStamp?,
) -> Bool {
  match (left, right) {
    (None, None) => true
    (Some(a), Some(b)) => a == b
    _ => false
  }
}

///|
fn town_life_dot_compare(left : TownLifeDot, right : TownLifeDot) -> Int {
  if left.sequence < right.sequence {
    -1
  } else if left.sequence > right.sequence {
    1
  } else {
    left.writer_id.compare(right.writer_id)
  }
}

///|
fn town_life_event_order(
  left_stamp : TownLifeCausalStamp,
  left_dot : TownLifeDot,
  left_id : String,
  right_stamp : TownLifeCausalStamp,
  right_dot : TownLifeDot,
  right_id : String,
) -> Int {
  let by_stamp = town_life_stamp_compare(left_stamp, right_stamp)
  if by_stamp != 0 {
    by_stamp
  } else {
    let by_dot = town_life_dot_compare(left_dot, right_dot)
    if by_dot != 0 {
      by_dot
    } else {
      left_id.compare(right_id)
    }
  }
}

///|
fn town_life_stable_hash(text : String) -> Int {
  let mut hash = 17
  for char in text {
    hash = (hash * 131 + char.to_int()) % 1000000007
  }
  hash
}

///|
fn town_life_legacy_dot(stream : String, sequence : Int) -> TownLifeDot {
  { writer_id: "legacy-\{stream}", sequence: sequence.max(0) }
}

///|
fn town_life_legacy_stamp(
  stream : String,
  lamport : Int,
) -> TownLifeCausalStamp {
  { writer_id: "legacy-\{stream}", lamport: lamport.max(0) }
}

///|
fn town_life_watermark_for(
  watermarks : ArrayView[TownLifePruneWatermark],
  writer_id : String,
) -> Int {
  let mut result = -1
  for watermark in watermarks {
    if watermark.writer_id == writer_id {
      result = result.max(watermark.through_sequence)
    }
  }
  result
}

///|
fn town_life_dot_is_pruned(
  dot : TownLifeDot,
  watermarks : ArrayView[TownLifePruneWatermark],
) -> Bool {
  dot.sequence <= town_life_watermark_for(watermarks, dot.writer_id)
}

///|
fn town_life_advance_watermark(
  watermarks : Array[TownLifePruneWatermark],
  dot : TownLifeDot,
) -> Unit {
  for index, current in watermarks {
    if current.writer_id == dot.writer_id {
      if dot.sequence > current.through_sequence {
        watermarks[index] = {
          writer_id: current.writer_id,
          through_sequence: dot.sequence,
        }
      }
      return
    }
  }
  watermarks.push({ writer_id: dot.writer_id, through_sequence: dot.sequence })
}

///|
fn town_life_merge_watermarks(
  left : ArrayView[TownLifePruneWatermark],
  right : ArrayView[TownLifePruneWatermark],
) -> Array[TownLifePruneWatermark] {
  let merged : Array[TownLifePruneWatermark] = []
  for watermark in left {
    town_life_advance_watermark(merged, {
      writer_id: watermark.writer_id,
      sequence: watermark.through_sequence,
    })
  }
  for watermark in right {
    town_life_advance_watermark(merged, {
      writer_id: watermark.writer_id,
      sequence: watermark.through_sequence,
    })
  }
  merged.sort_by((a, b) => a.writer_id.compare(b.writer_id))
  merged
}

///|
fn town_life_merge_writer_counters(
  left : ArrayView[TownLifeWriterCounter],
  right : ArrayView[TownLifeWriterCounter],
) -> Array[TownLifeWriterCounter] {
  let merged : Array[TownLifeWriterCounter] = []
  for counter in left {
    merged.push({ ..counter, sequence: counter.sequence.max(0) })
  }
  for counter in right {
    let mut found = -1
    for index, current in merged {
      if current.writer_id == counter.writer_id {
        found = index
      }
    }
    if found < 0 {
      merged.push({ ..counter, sequence: counter.sequence.max(0) })
    } else if counter.sequence > merged[found].sequence {
      merged[found] = { ..counter, sequence: counter.sequence.max(0) }
    }
  }
  merged.sort_by((a, b) => a.writer_id.compare(b.writer_id))
  merged
}

///|
fn town_life_observe_dot(
  counters : Array[TownLifeWriterCounter],
  dot : TownLifeDot,
) -> Unit {
  for index, counter in counters {
    if counter.writer_id == dot.writer_id {
      if dot.sequence > counter.sequence {
        counters[index] = {
          writer_id: counter.writer_id,
          sequence: dot.sequence,
        }
      }
      return
    }
  }
  counters.push({ writer_id: dot.writer_id, sequence: dot.sequence })
}

///|
fn town_life_max_observed_sequence(
  counters : ArrayView[TownLifeWriterCounter],
) -> Int {
  let mut result = 0
  for counter in counters {
    result = result.max(counter.sequence)
  }
  result
}

///|
fn town_life_max_observed_lamport(model : Model) -> Int {
  let mut result = town_life_max_observed_sequence(
    model.town_life_writer_counters,
  )
  let observe = fn(stamp : TownLifeCausalStamp) {
    result = result.max(stamp.lamport)
  }
  match model.town_life_player_stamp {
    Some(value) => observe(value)
    None => ()
  }
  match model.town_life_player_position_stamp {
    Some(value) => observe(value)
    None => ()
  }
  match model.town_life_post_reset_stamp {
    Some(value) => observe(value)
    None => ()
  }
  for event in model.town_life_phone_events {
    observe(event.stamp)
  }
  for event in model.town_life_analytics_events {
    observe(event.stamp)
  }
  for event in model.town_life_ops_report_events {
    observe(event.stamp)
  }
  for counter in model.town_life_attention_counters {
    observe(counter.stamp)
  }
  for post in model.posts {
    match post.created_stamp {
      Some(value) => observe(value)
      None => ()
    }
    match post.updated_stamp {
      Some(value) => observe(value)
      None => ()
    }
  }
  for tombstone in model.town_life_post_tombstones {
    observe(tombstone.stamp)
  }
  for state in model.town_life_world_states {
    observe(state.epoch.stamp)
    for event in state.events {
      observe(event.stamp)
    }
  }
  result
}

///|
fn town_life_next_event(
  model : Model,
  kind : String,
) -> (TownLifeDot, TownLifeCausalStamp, String, Model) {
  let writer_id = if model.town_life_writer_id.is_empty() {
    "writer-unavailable"
  } else {
    model.town_life_writer_id
  }
  // A writer allocates above every observed writer counter, not merely its
  // own component. This makes the Lamport happens-after relation explicit.
  let sequence = town_life_max_observed_sequence(
      model.town_life_writer_counters,
    ) +
    1
  let lamport = town_life_max_observed_lamport(model).max(sequence - 1) + 1
  let dot : TownLifeDot = { writer_id, sequence }
  let stamp : TownLifeCausalStamp = { writer_id, lamport }
  let counters = model.town_life_writer_counters.copy()
  town_life_observe_dot(counters, dot)
  (
    dot,
    stamp,
    "\{writer_id}:\{sequence}:\{kind}",
    { ..model, town_life_writer_counters: counters },
  )
}

///|
fn town_life_seed_text_events(
  values : ArrayView[String],
  stream : String,
) -> Array[TownLifeTextEvent] {
  let events : Array[TownLifeTextEvent] = []
  let occurrences : Map[String, Int] = Map([])
  for index, value in values {
    let occurrence = occurrences.get(value).unwrap_or(0) + 1
    occurrences[value] = occurrence
    let payload_hash = town_life_stable_hash(value)
    let dot = town_life_legacy_dot("\{stream}-\{payload_hash}", occurrence)
    events.push({
      id: "legacy:\{stream}:\{payload_hash}:\{occurrence}",
      dot,
      observed_dots: Some([dot]),
      stamp: { writer_id: dot.writer_id, lamport: index + 1 },
      value,
    })
  }
  events
}

///|
fn town_life_seed_phone_events(
  values : ArrayView[PhoneMessage],
) -> Array[TownLifePhoneEvent] {
  let events : Array[TownLifePhoneEvent] = []
  let occurrences : Map[String, Int] = Map([])
  for index, value in values {
    let encoded = ToJson::to_json(value).stringify()
    let occurrence = occurrences.get(encoded).unwrap_or(0) + 1
    occurrences[encoded] = occurrence
    let payload_hash = town_life_stable_hash(encoded)
    let dot = town_life_legacy_dot("phone-\{payload_hash}", occurrence)
    events.push({
      id: "legacy:phone:\{payload_hash}:\{occurrence}",
      dot,
      stamp: { writer_id: dot.writer_id, lamport: index + 1 },
      value,
    })
  }
  events
}

///|
fn town_life_prefer_text_event(
  left : TownLifeTextEvent,
  right : TownLifeTextEvent,
) -> TownLifeTextEvent {
  let order = town_life_event_order(
    left.stamp,
    left.dot,
    left.id,
    right.stamp,
    right.dot,
    right.id,
  )
  let winner = if order > 0 {
    left
  } else if order < 0 {
    right
  } else if left.value.compare(right.value) >= 0 {
    left
  } else {
    right
  }
  { ..winner, observed_dots: Some(town_life_merge_event_dots(left, right)) }
}

///|
fn town_life_text_event_dots(event : TownLifeTextEvent) -> Array[TownLifeDot] {
  let dots = event.observed_dots.unwrap_or([]).copy()
  if !dots.contains(event.dot) {
    dots.push(event.dot)
  }
  dots.sort_by(town_life_dot_compare)
  dots
}

///|
fn town_life_merge_event_dots(
  left : TownLifeTextEvent,
  right : TownLifeTextEvent,
) -> Array[TownLifeDot] {
  let dots = town_life_text_event_dots(left)
  for dot in town_life_text_event_dots(right) {
    if !dots.contains(dot) {
      dots.push(dot)
    }
  }
  dots.sort_by(town_life_dot_compare)
  dots
}

///|
fn town_life_text_event_is_pruned(
  event : TownLifeTextEvent,
  watermarks : ArrayView[TownLifePruneWatermark],
) -> Bool {
  town_life_text_event_dots(event).all(dot => {
    town_life_dot_is_pruned(dot, watermarks)
  })
}

///|
fn town_life_prefer_phone_event(
  left : TownLifePhoneEvent,
  right : TownLifePhoneEvent,
) -> TownLifePhoneEvent {
  let order = town_life_event_order(
    left.stamp,
    left.dot,
    left.id,
    right.stamp,
    right.dot,
    right.id,
  )
  if order > 0 {
    left
  } else if order < 0 {
    right
  } else if ToJson::to_json(left.value)
    .stringify()
    .compare(ToJson::to_json(right.value).stringify()) >=
    0 {
    left
  } else {
    right
  }
}

///|
fn town_life_merge_text_event_state(
  left_events : ArrayView[TownLifeTextEvent],
  left_watermarks : ArrayView[TownLifePruneWatermark],
  right_events : ArrayView[TownLifeTextEvent],
  right_watermarks : ArrayView[TownLifePruneWatermark],
  capacity : Int,
) -> (Array[TownLifeTextEvent], Array[TownLifePruneWatermark]) {
  let watermarks = town_life_merge_watermarks(left_watermarks, right_watermarks)
  let merged : Array[TownLifeTextEvent] = []
  let add = fn(event : TownLifeTextEvent) {
    if town_life_text_event_is_pruned(event, watermarks) {
      return
    }
    for index, current in merged {
      if current.id == event.id {
        merged[index] = town_life_prefer_text_event(current, event)
        return
      }
    }
    merged.push({
      ..event,
      observed_dots: Some(town_life_text_event_dots(event)),
    })
  }
  for event in left_events {
    add(event)
  }
  for event in right_events {
    add(event)
  }
  merged.sort_by((a, b) => {
    town_life_event_order(a.stamp, a.dot, a.id, b.stamp, b.dot, b.id)
  })
  let limit = capacity.max(1)
  while merged.length() > limit {
    let removed = merged.remove(0)
    for dot in town_life_text_event_dots(removed) {
      town_life_advance_watermark(watermarks, dot)
    }
  }
  watermarks.sort_by((a, b) => a.writer_id.compare(b.writer_id))
  (merged, watermarks)
}

///|
fn town_life_merge_phone_event_state(
  left_events : ArrayView[TownLifePhoneEvent],
  left_watermarks : ArrayView[TownLifePruneWatermark],
  right_events : ArrayView[TownLifePhoneEvent],
  right_watermarks : ArrayView[TownLifePruneWatermark],
) -> (Array[TownLifePhoneEvent], Array[TownLifePruneWatermark]) {
  let watermarks = town_life_merge_watermarks(left_watermarks, right_watermarks)
  let merged : Array[TownLifePhoneEvent] = []
  let add = fn(event : TownLifePhoneEvent) {
    if town_life_dot_is_pruned(event.dot, watermarks) {
      return
    }
    for index, current in merged {
      if current.id == event.id {
        merged[index] = town_life_prefer_phone_event(current, event)
        return
      }
    }
    merged.push(event)
  }
  for event in left_events {
    add(event)
  }
  for event in right_events {
    add(event)
  }
  merged.sort_by((a, b) => {
    town_life_event_order(a.stamp, a.dot, a.id, b.stamp, b.dot, b.id)
  })
  while merged.length() > town_life_phone_capacity {
    let removed = merged.remove(0)
    town_life_advance_watermark(watermarks, removed.dot)
  }
  watermarks.sort_by((a, b) => a.writer_id.compare(b.writer_id))
  (merged, watermarks)
}

///|
fn town_life_text_values(
  events : ArrayView[TownLifeTextEvent],
) -> Array[String] {
  events.map(event => event.value)
}

///|
fn town_life_phone_values(
  events : ArrayView[TownLifePhoneEvent],
) -> Array[PhoneMessage] {
  events.map(event => event.value)
}

///|
fn town_life_append_text_event(
  model : Model,
  stream : String,
  semantic_id : String?,
  value : String,
  existing : ArrayView[TownLifeTextEvent],
  watermarks : ArrayView[TownLifePruneWatermark],
  capacity : Int,
) -> (Model, Array[TownLifeTextEvent], Array[TownLifePruneWatermark]) {
  let (dot, stamp, id, stamped) = town_life_next_event(model, stream)
  let event_id = semantic_id.unwrap_or(id)
  let (events, next_watermarks) = town_life_merge_text_event_state(
    existing,
    watermarks,
    [{ id: event_id, dot, observed_dots: Some([dot]), stamp, value }],
    [],
    capacity,
  )
  (stamped, events, next_watermarks)
}

///|
fn town_life_append_phone_message(model : Model, value : PhoneMessage) -> Model {
  let existing = if model.town_life_phone_events.is_empty() &&
    !model.phone_log.is_empty() {
    town_life_seed_phone_events(model.phone_log)
  } else {
    model.town_life_phone_events
  }
  let (dot, stamp, id, stamped) = town_life_next_event(model, "phone")
  let (events, watermarks) = town_life_merge_phone_event_state(
    existing,
    model.town_life_phone_prune_watermarks,
    [{ id, dot, stamp, value }],
    [],
  )
  {
    ..stamped,
    phone_log: town_life_phone_values(events),
    town_life_phone_events: events,
    town_life_phone_prune_watermarks: watermarks,
  }
}

///|
fn town_life_append_analytics_line(model : Model, value : String) -> Model {
  let existing = if model.town_life_analytics_events.is_empty() &&
    !model.analytics.is_empty() {
    town_life_seed_text_events(model.analytics, "analytics")
  } else {
    model.town_life_analytics_events
  }
  let (stamped, events, watermarks) = town_life_append_text_event(
    model,
    "analytics",
    None,
    value,
    existing,
    model.town_life_analytics_prune_watermarks,
    analytics_ring_capacity,
  )
  {
    ..stamped,
    analytics: town_life_text_values(events),
    town_life_analytics_events: events,
    town_life_analytics_prune_watermarks: watermarks,
  }
}

///|
fn town_life_append_ops_report(model : Model, value : String) -> Model {
  let existing = if model.town_life_ops_report_events.is_empty() &&
    !model.ops_reports.is_empty() {
    town_life_seed_text_events(model.ops_reports, "reports")
  } else {
    model.town_life_ops_report_events
  }
  let (stamped, events, watermarks) = town_life_append_text_event(
    model,
    "reports",
    None,
    value,
    existing,
    model.town_life_ops_report_prune_watermarks,
    town_life_report_capacity,
  )
  {
    ..stamped,
    ops_reports: town_life_text_values(events),
    town_life_ops_report_events: events,
    town_life_ops_report_prune_watermarks: watermarks,
  }
}

///|
fn town_life_append_scheduled_ops_report(
  model : Model,
  semantic_id : String,
  value : String,
) -> Model {
  let existing = if model.town_life_ops_report_events.is_empty() &&
    !model.ops_reports.is_empty() {
    town_life_seed_text_events(model.ops_reports, "reports")
  } else {
    model.town_life_ops_report_events
  }
  let (stamped, events, watermarks) = town_life_append_text_event(
    model,
    "reports",
    Some(semantic_id),
    value,
    existing,
    model.town_life_ops_report_prune_watermarks,
    town_life_report_capacity,
  )
  {
    ..stamped,
    ops_reports: town_life_text_values(events),
    town_life_ops_report_events: events,
    town_life_ops_report_prune_watermarks: watermarks,
  }
}

///|
fn town_life_seed_attention_counters(
  receipts : ArrayView[EcosystemAttentionReceipt],
) -> Array[TownLifeAttentionCounter] {
  let counters : Array[TownLifeAttentionCounter] = []
  for index, receipt in receipts {
    let dot = town_life_legacy_dot("attention", index + 1)
    counters.push({
      writer_id: dot.writer_id,
      cooldown_key: receipt.cooldown_key,
      count: receipt.show_count.max(0),
      last_shown_tick: receipt.last_shown_tick.max(0),
      dot,
      stamp: town_life_legacy_stamp("attention", index + 1),
    })
  }
  counters
}

///|
fn town_life_merge_attention_counters(
  left : ArrayView[TownLifeAttentionCounter],
  right : ArrayView[TownLifeAttentionCounter],
) -> Array[TownLifeAttentionCounter] {
  let merged : Array[TownLifeAttentionCounter] = []
  let add = fn(counter : TownLifeAttentionCounter) {
    for index, current in merged {
      if current.writer_id == counter.writer_id &&
        current.cooldown_key == counter.cooldown_key {
        let newer = if town_life_stamp_after(counter.stamp, current.stamp) ||
          (
            counter.stamp == current.stamp &&
            town_life_dot_compare(counter.dot, current.dot) > 0
          ) {
          counter
        } else {
          current
        }
        merged[index] = {
          writer_id: current.writer_id,
          cooldown_key: current.cooldown_key,
          count: current.count.max(counter.count).max(0),
          last_shown_tick: newer.last_shown_tick.max(0),
          dot: newer.dot,
          stamp: newer.stamp,
        }
        return
      }
    }
    merged.push({
      ..counter,
      count: counter.count.max(0),
      last_shown_tick: counter.last_shown_tick.max(0),
    })
  }
  for counter in left {
    add(counter)
  }
  for counter in right {
    add(counter)
  }
  merged.sort_by((a, b) => {
    let by_writer = a.writer_id.compare(b.writer_id)
    if by_writer != 0 {
      by_writer
    } else {
      a.cooldown_key.compare(b.cooldown_key)
    }
  })
  merged
}

///|
fn town_life_attention_receipts(
  counters : ArrayView[TownLifeAttentionCounter],
) -> Array[EcosystemAttentionReceipt] {
  let receipts : Array[EcosystemAttentionReceipt] = []
  let newest_stamps : Array[TownLifeCausalStamp] = []
  for counter in counters {
    let mut found = -1
    for index, receipt in receipts {
      if receipt.cooldown_key == counter.cooldown_key {
        found = index
      }
    }
    if found < 0 {
      receipts.push({
        cooldown_key: counter.cooldown_key,
        last_shown_tick: counter.last_shown_tick,
        show_count: counter.count,
      })
      newest_stamps.push(counter.stamp)
    } else {
      let current = receipts[found]
      let newer = town_life_stamp_after(counter.stamp, newest_stamps[found])
      receipts[found] = {
        cooldown_key: current.cooldown_key,
        last_shown_tick: if newer {
          counter.last_shown_tick
        } else {
          current.last_shown_tick
        },
        show_count: current.show_count + counter.count,
      }
      if newer {
        newest_stamps[found] = counter.stamp
      }
    }
  }
  receipts.sort_by((a, b) => {
    if a.last_shown_tick != b.last_shown_tick {
      if a.last_shown_tick > b.last_shown_tick {
        -1
      } else {
        1
      }
    } else {
      a.cooldown_key.compare(b.cooldown_key)
    }
  })
  if receipts.length() <= 48 {
    receipts
  } else {
    receipts[:48].to_owned()
  }
}

///|
fn town_life_record_attention(
  model : Model,
  cooldown_key : String,
  shown_tick : Int,
) -> Model {
  let existing = if model.town_life_attention_counters.is_empty() &&
    !model.ecosystem_attention_receipts.is_empty() {
    town_life_seed_attention_counters(model.ecosystem_attention_receipts)
  } else {
    model.town_life_attention_counters
  }
  let (dot, stamp, _, stamped) = town_life_next_event(model, "attention")
  let mut previous_count = 0
  for counter in existing {
    if counter.writer_id == dot.writer_id &&
      counter.cooldown_key == cooldown_key {
      previous_count = previous_count.max(counter.count)
    }
  }
  let counters = town_life_merge_attention_counters(existing, [
    {
      writer_id: dot.writer_id,
      cooldown_key,
      count: previous_count + 1,
      last_shown_tick: shown_tick.max(0),
      dot,
      stamp,
    },
  ])
  {
    ..stamped,
    ecosystem_attention_receipts: town_life_attention_receipts(counters),
    town_life_attention_counters: counters,
  }
}

///|
fn town_life_awards_total(awards : ArrayView[TownLifeSparkAward]) -> Int {
  let mut total = 0
  for award in awards {
    total += award.amount.max(0)
  }
  total
}

///|
fn town_life_effective_spark(save : TownLifeSave) -> Int {
  save.spark_floor.unwrap_or(save.spark).max(0) +
  town_life_awards_total(save.spark_awards.unwrap_or([]))
}

///|
fn town_life_merge_spark_awards(
  left : ArrayView[TownLifeSparkAward],
  right : ArrayView[TownLifeSparkAward],
) -> Array[TownLifeSparkAward] {
  let merged : Array[TownLifeSparkAward] = []
  let add = fn(award : TownLifeSparkAward) {
    for index, current in merged {
      if current.id == award.id {
        if award.amount > current.amount {
          merged[index] = { ..award, amount: award.amount.max(0) }
        }
        return
      }
    }
    merged.push({ ..award, amount: award.amount.max(0) })
  }
  for award in left {
    add(award)
  }
  for award in right {
    add(award)
  }
  merged.sort_by((a, b) => a.id.compare(b.id))
  merged
}

///|
fn town_life_add_spark_award(model : Model, id : String, amount : Int) -> Model {
  if model.town_life_spark_awards.any(award => award.id == id) {
    return model
  }
  let awards = model.town_life_spark_awards.copy()
  awards.push({ id, amount: amount.max(0) })
  awards.sort_by((a, b) => a.id.compare(b.id))
  let spark = model.town_life_spark_floor + town_life_awards_total(awards)
  let player = model.player.map(value => {
    ..value,
    title: player_title_for(spark),
  })
  { ..model, spark, player, town_life_spark_awards: awards }
}

///|
fn town_life_merge_quest_done(
  left : ArrayView[String],
  right : ArrayView[String],
) -> Array[String] {
  let merged : Array[String] = []
  for quest in town_quest_chain() {
    if left.contains(quest.id) || right.contains(quest.id) {
      merged.push(quest.id)
    }
  }
  let extras : Array[String] = []
  for id in left {
    if !merged.contains(id) && !extras.contains(id) {
      extras.push(id)
    }
  }
  for id in right {
    if !merged.contains(id) && !extras.contains(id) {
      extras.push(id)
    }
  }
  extras.sort_by((a, b) => a.compare(b))
  merged + extras
}

///|
fn town_life_post_is_map_bound(post : KnowledgePost) -> Bool {
  post.mine || post.collected || post.building_id is Some(_)
}

///|
fn town_life_legacy_reset_stamp(generation : Int) -> TownLifeCausalStamp? {
  if generation <= 0 {
    None
  } else {
    Some({ writer_id: "legacy-post-reset", lamport: generation })
  }
}

///|
fn town_life_normalize_post(
  post : KnowledgePost,
  fallback_reset_epoch : TownLifeCausalStamp?,
) -> KnowledgePost {
  let building_id = match post.building_id {
    Some(value) if !value.trim().is_empty() => Some(value.trim().to_owned())
    _ => None
  }
  let map_bound = post.mine || post.collected || building_id is Some(_)
  let reset_epoch = if map_bound {
    match post.reset_epoch {
      Some(value) => Some(value)
      None => fallback_reset_epoch
    }
  } else {
    None
  }
  // Legacy saves have no incarnation token. Derive it only from stable
  // identity, never mutable topic/publish/collect payload, so divergent stale
  // copies still reconcile as one incarnation.
  let fingerprint = "\{post.id}|\{building_id.unwrap_or("")}|\{post.building_name}"
  let incarnation_id = post.incarnation_id.unwrap_or(
    "legacy-post:\{post.id}:\{town_life_stable_hash(fingerprint)}",
  )
  let created_stamp = match post.created_stamp {
    Some(value) => value
    None =>
      match reset_epoch {
        Some(epoch) =>
          { writer_id: "legacy-post-state", lamport: epoch.lamport + 1 }
        None => town_life_legacy_stamp("post-state", 0)
      }
  }
  {
    ..post,
    building_id,
    incarnation_id: Some(incarnation_id),
    created_stamp: Some(created_stamp),
    updated_stamp: Some(post.updated_stamp.unwrap_or(created_stamp)),
    reset_epoch,
  }
}

///|
fn town_life_canonical_string(left : String, right : String) -> String {
  if left.is_empty() {
    right
  } else if right.is_empty() {
    left
  } else if left.compare(right) >= 0 {
    left
  } else {
    right
  }
}

///|
fn town_life_canonical_optional_string(
  left : String?,
  right : String?,
) -> String? {
  match (left, right) {
    (None, value) | (value, None) => value
    (Some(a), Some(b)) => Some(town_life_canonical_string(a, b))
  }
}

///|
fn town_life_merge_post(
  left : KnowledgePost,
  right : KnowledgePost,
) -> KnowledgePost {
  let left_updated = left.updated_stamp.unwrap_or(
    left.created_stamp.unwrap_or(town_life_legacy_stamp("post-state", 0)),
  )
  let right_updated = right.updated_stamp.unwrap_or(
    right.created_stamp.unwrap_or(town_life_legacy_stamp("post-state", 0)),
  )
  let winner = if town_life_stamp_after(right_updated, left_updated) {
    right
  } else if town_life_stamp_after(left_updated, right_updated) {
    left
  } else if ToJson::to_json(right)
    .stringify()
    .compare(ToJson::to_json(left).stringify()) >
    0 {
    right
  } else {
    left
  }
  let created_stamp = match (left.created_stamp, right.created_stamp) {
    (Some(a), Some(b)) => Some(if town_life_stamp_after(a, b) { b } else { a })
    (value, None) | (None, value) => value
  }
  {
    ..winner
    // Mutable payload is wholly LWW. In particular, editing an older
    // published draft back to unpublished must not be undone by an OR merge.
    ,
    id: town_life_canonical_string(left.id, right.id),
    building_id: town_life_canonical_optional_string(
      left.building_id,
      right.building_id,
    ),
    incarnation_id: town_life_canonical_optional_string(
      left.incarnation_id,
      right.incarnation_id,
    ),
    created_stamp,
    updated_stamp: Some(
      if town_life_stamp_after(left_updated, right_updated) {
        left_updated
      } else {
        right_updated
      },
    ),
    reset_epoch: town_life_optional_stamp_max(
      left.reset_epoch,
      right.reset_epoch,
    ),
  }
}

///|
fn town_life_merge_post_tombstones(
  left : ArrayView[TownLifePostTombstone],
  right : ArrayView[TownLifePostTombstone],
) -> Array[TownLifePostTombstone] {
  let merged : Array[TownLifePostTombstone] = []
  let add = fn(tombstone : TownLifePostTombstone) {
    for index, current in merged {
      if current.incarnation_id == tombstone.incarnation_id &&
        town_life_optional_stamp_equal(
          current.reset_epoch,
          tombstone.reset_epoch,
        ) {
        if town_life_stamp_after(tombstone.stamp, current.stamp) ||
          (
            tombstone.stamp == current.stamp &&
            town_life_dot_compare(tombstone.dot, current.dot) > 0
          ) {
          merged[index] = tombstone
        }
        return
      }
    }
    merged.push(tombstone)
  }
  for tombstone in left {
    add(tombstone)
  }
  for tombstone in right {
    add(tombstone)
  }
  merged.sort_by((a, b) => {
    let by_incarnation = a.incarnation_id.compare(b.incarnation_id)
    if by_incarnation != 0 {
      by_incarnation
    } else {
      town_life_stamp_compare(
        a.reset_epoch.unwrap_or(town_life_legacy_stamp("post-reset", 0)),
        b.reset_epoch.unwrap_or(town_life_legacy_stamp("post-reset", 0)),
      )
    }
  })
  merged
}

///|
fn town_life_tombstone_matches_post(
  tombstone : TownLifePostTombstone,
  post : KnowledgePost,
) -> Bool {
  let incarnation = post.incarnation_id.unwrap_or("")
  if !town_life_optional_stamp_equal(tombstone.reset_epoch, post.reset_epoch) {
    return false
  }
  if tombstone.incarnation_id == incarnation {
    // Exact incarnation ids are immutable and can never be legitimately
    // recreated, so deletion is unconditionally remove-wins.
    return true
  }
  if tombstone.post_id != post.id {
    return false
  }
  // Deleting the current logical post also cuts off every older incarnation
  // observed only in a stale shard. Otherwise removing the newest collection
  // would expose an earlier incarnation again. A genuinely later recollection
  // has a newer creation stamp and remains valid; legacy-any uses the same
  // cutoff because v2 had no exact incarnation token.
  let created = post.created_stamp.unwrap_or(
    town_life_legacy_stamp("post-state", 0),
  )
  town_life_stamp_compare(created, tombstone.stamp) <= 0
}

///|
fn town_life_reconcile_post_state(
  left_posts : ArrayView[KnowledgePost],
  left_reset : TownLifeCausalStamp?,
  left_tombstones : ArrayView[TownLifePostTombstone],
  right_posts : ArrayView[KnowledgePost],
  right_reset : TownLifeCausalStamp?,
  right_tombstones : ArrayView[TownLifePostTombstone],
) -> (Array[KnowledgePost], TownLifeCausalStamp?, Array[TownLifePostTombstone]) {
  let reset_epoch = town_life_optional_stamp_max(left_reset, right_reset)
  let all_tombstones = town_life_merge_post_tombstones(
    left_tombstones, right_tombstones,
  )
  let tombstones = all_tombstones.filter(tombstone => {
    town_life_optional_stamp_equal(tombstone.reset_epoch, reset_epoch)
  })
  let incarnations : Array[KnowledgePost] = []
  let add = fn(raw : KnowledgePost, observed_reset : TownLifeCausalStamp?) {
    let post = town_life_normalize_post(raw, observed_reset)
    if town_life_post_is_map_bound(post) &&
      !town_life_optional_stamp_equal(post.reset_epoch, reset_epoch) {
      return
    }
    if tombstones.any(tombstone => {
        town_life_tombstone_matches_post(tombstone, post)
      }) {
      return
    }
    let incarnation = post.incarnation_id.unwrap_or("")
    for index, current in incarnations {
      if current.incarnation_id.unwrap_or("") == incarnation {
        incarnations[index] = town_life_merge_post(current, post)
        return
      }
    }
    incarnations.push(post)
  }
  for post in left_posts {
    add(post, left_reset)
  }
  for post in right_posts {
    add(post, right_reset)
  }
  let posts : Array[KnowledgePost] = []
  for post in incarnations {
    let mut found = -1
    for index, current in posts {
      if current.id == post.id {
        found = index
      }
    }
    if found < 0 {
      posts.push(post)
    } else {
      let current = posts[found]
      let current_created = current.created_stamp.unwrap_or(
        town_life_legacy_stamp("post-state", 0),
      )
      let candidate_created = post.created_stamp.unwrap_or(
        town_life_legacy_stamp("post-state", 0),
      )
      if town_life_stamp_after(candidate_created, current_created) ||
        (
          candidate_created == current_created &&
          post.incarnation_id
          .unwrap_or("")
          .compare(current.incarnation_id.unwrap_or("")) >
          0
        ) {
        posts[found] = post
      }
    }
  }
  posts.sort_by((a, b) => {
    let by_id = a.id.compare(b.id)
    if by_id != 0 {
      by_id
    } else {
      a.incarnation_id.unwrap_or("").compare(b.incarnation_id.unwrap_or(""))
    }
  })
  (posts, reset_epoch, tombstones)
}

///|
fn town_life_legacy_post_tombstones(
  ids : ArrayView[String],
  reset_epoch : TownLifeCausalStamp?,
) -> Array[TownLifePostTombstone] {
  let tombstones : Array[TownLifePostTombstone] = []
  for id in ids {
    let payload_hash = town_life_stable_hash(id)
    let dot = town_life_legacy_dot("post-delete-\{payload_hash}", 1)
    tombstones.push({
      post_id: id,
      incarnation_id: "legacy-any:\{id}",
      reset_epoch,
      dot,
      stamp: {
        writer_id: dot.writer_id,
        lamport: reset_epoch.map(value => value.lamport + 2).unwrap_or(1),
      },
    })
  }
  tombstones
}

///|
fn town_life_player_json(value : PlayerAvatar?) -> String {
  match value {
    None => "null"
    Some(player) => ToJson::to_json(player).stringify()
  }
}

///|
fn town_life_position_json(value : PlayerPosition?) -> String {
  match value {
    None => "null"
    Some(position) => ToJson::to_json(position).stringify()
  }
}

///|
fn town_life_select_player(
  left : PlayerAvatar?,
  left_stamp : TownLifeCausalStamp?,
  right : PlayerAvatar?,
  right_stamp : TownLifeCausalStamp?,
) -> (PlayerAvatar?, TownLifeCausalStamp?) {
  match (left_stamp, right_stamp) {
    (Some(a), Some(b)) => {
      let order = town_life_stamp_compare(a, b)
      if order > 0 {
        (left, Some(a))
      } else if order < 0 {
        (right, Some(b))
      } else if town_life_player_json(left).compare(
          town_life_player_json(right),
        ) >=
        0 {
        (left, Some(a))
      } else {
        (right, Some(b))
      }
    }
    (Some(stamp), None) => (left, Some(stamp))
    (None, Some(stamp)) => (right, Some(stamp))
    (None, None) =>
      if town_life_player_json(left).compare(town_life_player_json(right)) >= 0 {
        (left, None)
      } else {
        (right, None)
      }
  }
}

///|
fn town_life_select_position(
  left : PlayerPosition?,
  left_stamp : TownLifeCausalStamp?,
  right : PlayerPosition?,
  right_stamp : TownLifeCausalStamp?,
) -> (PlayerPosition?, TownLifeCausalStamp?) {
  match (left_stamp, right_stamp) {
    (Some(a), Some(b)) => {
      let order = town_life_stamp_compare(a, b)
      if order > 0 {
        (left, Some(a))
      } else if order < 0 {
        (right, Some(b))
      } else if town_life_position_json(left).compare(
          town_life_position_json(right),
        ) >=
        0 {
        (left, Some(a))
      } else {
        (right, Some(b))
      }
    }
    (Some(stamp), None) => (left, Some(stamp))
    (None, Some(stamp)) => (right, Some(stamp))
    (None, None) =>
      if town_life_position_json(left).compare(town_life_position_json(right)) >=
        0 {
        (left, None)
      } else {
        (right, None)
      }
  }
}

///|
fn town_life_normalize_save(save : TownLifeSave) -> TownLifeSave {
  let phone_source = match save.phone_events {
    Some(events) if !events.is_empty() || save.phone_log.is_empty() => events
    _ => town_life_seed_phone_events(save.phone_log)
  }
  let (phone_events, phone_watermarks) = town_life_merge_phone_event_state(
    phone_source,
    save.phone_prune_watermarks.unwrap_or([]),
    [],
    [],
  )
  let analytics_source = match save.analytics_events {
    Some(events) if !events.is_empty() || save.analytics.is_empty() => events
    _ => town_life_seed_text_events(save.analytics, "analytics")
  }
  let (analytics_events, analytics_watermarks) = town_life_merge_text_event_state(
    analytics_source,
    save.analytics_prune_watermarks.unwrap_or([]),
    [],
    [],
    analytics_ring_capacity,
  )
  let report_values = save.ops_reports.unwrap_or([])
  let report_source = match save.ops_report_events {
    Some(events) if !events.is_empty() || report_values.is_empty() => events
    _ => town_life_seed_text_events(report_values, "reports")
  }
  let (report_events, report_watermarks) = town_life_merge_text_event_state(
    report_source,
    save.ops_report_prune_watermarks.unwrap_or([]),
    [],
    [],
    town_life_report_capacity,
  )
  let attention_source = match save.attention_counters {
    Some(counters) if !counters.is_empty() ||
      save.ecosystem_attention_receipts.unwrap_or([]).is_empty() => counters
    _ =>
      town_life_seed_attention_counters(
        save.ecosystem_attention_receipts.unwrap_or([]),
      )
  }
  let attention_counters = town_life_merge_attention_counters(
    attention_source,
    [],
  )
  let generation = save.post_generation.unwrap_or(0).max(0)
  let reset_epoch = match save.post_reset_stamp {
    Some(value) => Some(value)
    None => town_life_legacy_reset_stamp(generation)
  }
  let tombstone_source = match save.post_tombstones {
    Some(values) => values
    None =>
      town_life_legacy_post_tombstones(
        save.deleted_post_ids.unwrap_or([]),
        reset_epoch,
      )
  }
  let (posts, post_reset_stamp, post_tombstones) = town_life_reconcile_post_state(
    save.posts,
    reset_epoch,
    tombstone_source,
    [],
    reset_epoch,
    [],
  )
  let awards = town_life_merge_spark_awards(save.spark_awards.unwrap_or([]), [])
  let spark_floor = match save.spark_floor {
    Some(value) => value.max(0)
    None => (save.spark - town_life_awards_total(awards)).max(0)
  }
  let spark = spark_floor + town_life_awards_total(awards)
  let player_stamp = match save.player_stamp {
    Some(value) => Some(value)
    None =>
      if save.player is Some(_) {
        Some(town_life_legacy_stamp("player", 0))
      } else {
        None
      }
  }
  let player_position_stamp = match save.player_position_stamp {
    Some(value) => Some(value)
    None =>
      if save.player_position is Some(_) {
        Some(town_life_legacy_stamp("position", 0))
      } else {
        None
      }
  }
  let player = save.player.map(value => {
    ..value,
    title: player_title_for(spark),
  })
  let writer_counters = save.writer_counters.unwrap_or([]).copy()
  let world_states = town_life_world_merge_states(
    save.world_states.unwrap_or([]),
    [],
  )
  for event in phone_events {
    town_life_observe_dot(writer_counters, event.dot)
  }
  for event in analytics_events {
    for dot in town_life_text_event_dots(event) {
      town_life_observe_dot(writer_counters, dot)
    }
  }
  for event in report_events {
    for dot in town_life_text_event_dots(event) {
      town_life_observe_dot(writer_counters, dot)
    }
  }
  for counter in attention_counters {
    town_life_observe_dot(writer_counters, counter.dot)
  }
  for tombstone in post_tombstones {
    town_life_observe_dot(writer_counters, tombstone.dot)
  }
  for state in world_states {
    town_life_observe_dot(writer_counters, state.epoch.dot)
    for event in state.events {
      town_life_observe_dot(writer_counters, event.dot)
    }
  }
  for watermark in phone_watermarks {
    town_life_observe_dot(writer_counters, {
      writer_id: watermark.writer_id,
      sequence: watermark.through_sequence,
    })
  }
  for watermark in analytics_watermarks {
    town_life_observe_dot(writer_counters, {
      writer_id: watermark.writer_id,
      sequence: watermark.through_sequence,
    })
  }
  for watermark in report_watermarks {
    town_life_observe_dot(writer_counters, {
      writer_id: watermark.writer_id,
      sequence: watermark.through_sequence,
    })
  }
  writer_counters.sort_by((a, b) => a.writer_id.compare(b.writer_id))
  {
    player,
    player_position: save.player_position,
    player_stamp,
    player_position_stamp,
    writer_counters: Some(writer_counters),
    spark,
    spark_floor: Some(spark_floor),
    spark_awards: Some(awards),
    quest_done: town_life_merge_quest_done(save.quest_done, []),
    phone_log: town_life_phone_values(phone_events),
    phone_events: Some(phone_events),
    phone_prune_watermarks: Some(phone_watermarks),
    posts,
    post_reset_stamp,
    post_tombstones: Some(post_tombstones),
    analytics: town_life_text_values(analytics_events),
    analytics_events: Some(analytics_events),
    analytics_prune_watermarks: Some(analytics_watermarks),
    ecosystem_attention_receipts: Some(
      town_life_attention_receipts(attention_counters),
    ),
    attention_counters: Some(attention_counters),
    attention_prune_watermarks: Some([]),
    ops_reports: Some(town_life_text_values(report_events)),
    ops_report_events: Some(report_events),
    ops_report_prune_watermarks: Some(report_watermarks),
    last_report_tick: save.last_report_tick.max(0),
    checkin_day: save.checkin_day,
    world_states: Some(world_states),
    post_generation: Some(0),
    deleted_post_ids: Some([]),
  }
}

///|
fn town_life_reconcile_save(
  left_raw : TownLifeSave,
  right_raw : TownLifeSave,
) -> TownLifeSave {
  let left = town_life_normalize_save(left_raw)
  let right = town_life_normalize_save(right_raw)
  let (phone_events, phone_watermarks) = town_life_merge_phone_event_state(
    left.phone_events.unwrap_or([]),
    left.phone_prune_watermarks.unwrap_or([]),
    right.phone_events.unwrap_or([]),
    right.phone_prune_watermarks.unwrap_or([]),
  )
  let (analytics_events, analytics_watermarks) = town_life_merge_text_event_state(
    left.analytics_events.unwrap_or([]),
    left.analytics_prune_watermarks.unwrap_or([]),
    right.analytics_events.unwrap_or([]),
    right.analytics_prune_watermarks.unwrap_or([]),
    analytics_ring_capacity,
  )
  let (report_events, report_watermarks) = town_life_merge_text_event_state(
    left.ops_report_events.unwrap_or([]),
    left.ops_report_prune_watermarks.unwrap_or([]),
    right.ops_report_events.unwrap_or([]),
    right.ops_report_prune_watermarks.unwrap_or([]),
    town_life_report_capacity,
  )
  let attention_counters = town_life_merge_attention_counters(
    left.attention_counters.unwrap_or([]),
    right.attention_counters.unwrap_or([]),
  )
  let (posts, post_reset_stamp, post_tombstones) = town_life_reconcile_post_state(
    left.posts,
    left.post_reset_stamp,
    left.post_tombstones.unwrap_or([]),
    right.posts,
    right.post_reset_stamp,
    right.post_tombstones.unwrap_or([]),
  )
  let (player, player_stamp) = town_life_select_player(
    left.player,
    left.player_stamp,
    right.player,
    right.player_stamp,
  )
  let (player_position, player_position_stamp) = town_life_select_position(
    left.player_position,
    left.player_position_stamp,
    right.player_position,
    right.player_position_stamp,
  )
  let spark_floor = left.spark_floor
    .unwrap_or(0)
    .max(right.spark_floor.unwrap_or(0))
  let awards = town_life_merge_spark_awards(
    left.spark_awards.unwrap_or([]),
    right.spark_awards.unwrap_or([]),
  )
  let spark = spark_floor + town_life_awards_total(awards)
  let player = player.map(value => { ..value, title: player_title_for(spark) })
  town_life_normalize_save({
    player,
    player_position,
    player_stamp,
    player_position_stamp,
    writer_counters: Some(
      town_life_merge_writer_counters(
        left.writer_counters.unwrap_or([]),
        right.writer_counters.unwrap_or([]),
      ),
    ),
    spark,
    spark_floor: Some(spark_floor),
    spark_awards: Some(awards),
    quest_done: town_life_merge_quest_done(left.quest_done, right.quest_done),
    phone_log: town_life_phone_values(phone_events),
    phone_events: Some(phone_events),
    phone_prune_watermarks: Some(phone_watermarks),
    posts,
    post_reset_stamp,
    post_tombstones: Some(post_tombstones),
    analytics: town_life_text_values(analytics_events),
    analytics_events: Some(analytics_events),
    analytics_prune_watermarks: Some(analytics_watermarks),
    ecosystem_attention_receipts: Some(
      town_life_attention_receipts(attention_counters),
    ),
    attention_counters: Some(attention_counters),
    attention_prune_watermarks: Some([]),
    ops_reports: Some(town_life_text_values(report_events)),
    ops_report_events: Some(report_events),
    ops_report_prune_watermarks: Some(report_watermarks),
    last_report_tick: left.last_report_tick.max(right.last_report_tick),
    checkin_day: left.checkin_day.max(right.checkin_day),
    world_states: Some(
      town_life_world_merge_states(
        left.world_states.unwrap_or([]),
        right.world_states.unwrap_or([]),
      ),
    ),
    post_generation: Some(0),
    deleted_post_ids: Some([]),
  })
}

///|
fn town_life_aggregate_v3_saves(texts : ArrayView[String]) -> TownLifeSave? {
  let mut aggregate : TownLifeSave? = None
  for text in texts {
    match town_life_decode_save(text) {
      None => ()
      Some(save) =>
        aggregate = Some(
          match aggregate {
            None => town_life_normalize_save(save)
            Some(current) => town_life_reconcile_save(current, save)
          },
        )
    }
  }
  aggregate
}

///|
fn town_life_migration_fallback(
  fenced : Bool,
  legacy : TownLifeSave?,
) -> TownLifeSave {
  if fenced {
    town_life_default_save()
  } else {
    match legacy {
      Some(save) => town_life_normalize_save(save)
      None => town_life_default_save()
    }
  }
}

///|
fn town_life_migration_committed_result(
  migrated : TownLifeSave,
  installed_v3_texts : ArrayView[String],
) -> TownLifeSave {
  match town_life_aggregate_v3_saves(installed_v3_texts) {
    Some(committed) => committed
    None => migrated
  }
}

///|
fn initial_town_life_save() -> TownLifeSave {
  match town_life_aggregate_v3_saves(browser_town_life_v3_save_texts()) {
    Some(save) => {
      browser_fence_town_life_v3_migration()
      save
    }
    None => {
      let migrated = if browser_town_life_v3_migration_fenced() {
        town_life_default_save()
      } else {
        match
          town_life_aggregate_v3_saves(
            browser_town_life_v2_migration_save_texts(),
          ) {
          Some(save) => save
          None =>
            town_life_migration_fallback(
              false,
              town_life_decode_save(browser_town_life_v1_migration_save_text()),
            )
        }
      }
      browser_install_town_life_v3_migration_checkpoint(
        ToJson::to_json(migrated).stringify(),
      )
      // Another first-open tab may have fenced V3 between our legacy read and
      // checkpoint install. Re-read the authority and return its joined state
      // instead of rendering an uncommitted migration loser.
      town_life_migration_committed_result(
        migrated,
        browser_town_life_v3_save_texts(),
      )
    }
  }
}

///|
fn town_life_model_with_save(model : Model, raw : TownLifeSave) -> Model {
  let save = town_life_normalize_save(raw)
  let joined = {
    ..model,
    player: save.player,
    player_position: save.player_position,
    town_life_player_stamp: save.player_stamp,
    town_life_player_position_stamp: save.player_position_stamp,
    phone_log: save.phone_log,
    town_life_phone_events: save.phone_events.unwrap_or([]),
    town_life_phone_prune_watermarks: save.phone_prune_watermarks.unwrap_or([]),
    town_life_writer_counters: save.writer_counters.unwrap_or([]),
    spark: save.spark,
    town_life_spark_floor: save.spark_floor.unwrap_or(save.spark),
    town_life_spark_awards: save.spark_awards.unwrap_or([]),
    quest_done: save.quest_done,
    posts: if save.posts.is_empty() {
      community_square_posts()
    } else {
      save.posts
    },
    town_life_post_reset_stamp: save.post_reset_stamp,
    town_life_post_tombstones: save.post_tombstones.unwrap_or([]),
    ops_reports: save.ops_reports.unwrap_or([]),
    town_life_ops_report_events: save.ops_report_events.unwrap_or([]),
    town_life_ops_report_prune_watermarks: save.ops_report_prune_watermarks.unwrap_or([],
    ),
    last_report_tick: save.last_report_tick,
    analytics: save.analytics,
    town_life_analytics_events: save.analytics_events.unwrap_or([]),
    town_life_analytics_prune_watermarks: save.analytics_prune_watermarks.unwrap_or([],
    ),
    ecosystem_attention_receipts: save.ecosystem_attention_receipts.unwrap_or([]),
    town_life_attention_counters: save.attention_counters.unwrap_or([]),
    town_life_attention_prune_watermarks: [],
    town_life_world_states: save.world_states.unwrap_or([]),
    checkin_day: save.checkin_day,
  }
  town_life_world_reproject_model(joined, active_energy_valley_seed())
}

///|
fn town_life_set_player(model : Model, player : PlayerAvatar?) -> Model {
  let (_, stamp, _, stamped) = town_life_next_event(model, "player")
  { ..stamped, player, town_life_player_stamp: Some(stamp) }
}

///|
fn town_life_set_player_position(
  model : Model,
  position : PlayerPosition?,
) -> Model {
  let (_, stamp, _, stamped) = town_life_next_event(model, "position")
  {
    ..stamped,
    player_position: position,
    town_life_player_position_stamp: Some(stamp),
  }
}

///|
fn town_life_reset_map_bound_state(
  model : Model,
  surviving_posts : Array[KnowledgePost],
) -> Model {
  let (_, reset_stamp, _, stamped) = town_life_next_event(model, "post-reset")
  let reset = {
    ..stamped,
    posts: surviving_posts,
    town_life_post_reset_stamp: Some(reset_stamp),
    // The new epoch subsumes tombstones from every older epoch.
    town_life_post_tombstones: [],
  }
  town_life_world_reset(town_life_set_player_position(reset, None))
}

///|
fn town_life_new_post_incarnation(
  model : Model,
  post : KnowledgePost,
  building_id : String,
) -> (Model, KnowledgePost) {
  let (dot, stamp, id, stamped) = town_life_next_event(
    model, "post-incarnation",
  )
  ignore(dot)
  (
    stamped,
    {
      ..post,
      building_id: if building_id.is_empty() {
        None
      } else {
        Some(building_id)
      },
      incarnation_id: Some(id),
      created_stamp: Some(stamp),
      updated_stamp: Some(stamp),
      reset_epoch: stamped.town_life_post_reset_stamp,
    },
  )
}

///|
fn town_life_touch_post(model : Model, incarnation_id : String) -> Model {
  let (_, stamp, _, stamped) = town_life_next_event(model, "post-update")
  {
    ..stamped,
    posts: stamped.posts.map(post => {
      if post.incarnation_id.unwrap_or("") == incarnation_id {
        { ..post, updated_stamp: Some(stamp) }
      } else {
        post
      }
    }),
  }
}

///|
fn town_life_with_post_deletions(
  model : Model,
  before : ArrayView[KnowledgePost],
  after : Array[KnowledgePost],
) -> Model {
  let mut next = { ..model, posts: after }
  let tombstones = model.town_life_post_tombstones.copy()
  for raw in before {
    let post = town_life_normalize_post(raw, model.town_life_post_reset_stamp)
    let incarnation = post.incarnation_id.unwrap_or("")
    if !after.any(candidate => {
        town_life_normalize_post(candidate, model.town_life_post_reset_stamp).incarnation_id.unwrap_or(
          "",
        ) ==
        incarnation
      }) &&
      !tombstones.any(tombstone => {
        tombstone.incarnation_id == incarnation &&
        town_life_optional_stamp_equal(tombstone.reset_epoch, post.reset_epoch)
      }) {
      let (dot, stamp, _, stamped) = town_life_next_event(next, "post-delete")
      next = stamped
      tombstones.push({
        post_id: post.id,
        incarnation_id: incarnation,
        reset_epoch: post.reset_epoch,
        dot,
        stamp,
      })
    }
  }
  {
    ..next,
    posts: after,
    town_life_post_tombstones: town_life_merge_post_tombstones(tombstones, []),
  }
}

///|
fn town_life_save_for_model(model : Model) -> TownLifeSave {
  let phone_events = if model.town_life_phone_events.is_empty() &&
    !model.phone_log.is_empty() {
    town_life_seed_phone_events(model.phone_log)
  } else {
    model.town_life_phone_events
  }
  let analytics_events = if model.town_life_analytics_events.is_empty() &&
    !model.analytics.is_empty() {
    town_life_seed_text_events(model.analytics, "analytics")
  } else {
    model.town_life_analytics_events
  }
  let report_events = if model.town_life_ops_report_events.is_empty() &&
    !model.ops_reports.is_empty() {
    town_life_seed_text_events(model.ops_reports, "reports")
  } else {
    model.town_life_ops_report_events
  }
  let attention_counters = if model.town_life_attention_counters.is_empty() &&
    !model.ecosystem_attention_receipts.is_empty() {
    town_life_seed_attention_counters(model.ecosystem_attention_receipts)
  } else {
    model.town_life_attention_counters
  }
  town_life_normalize_save({
    player: model.player,
    player_position: model.player_position,
    player_stamp: model.town_life_player_stamp,
    player_position_stamp: model.town_life_player_position_stamp,
    writer_counters: Some(model.town_life_writer_counters),
    spark: model.spark,
    spark_floor: Some(model.town_life_spark_floor.max(0)),
    spark_awards: Some(model.town_life_spark_awards),
    quest_done: model.quest_done,
    phone_log: model.phone_log,
    phone_events: Some(phone_events),
    phone_prune_watermarks: Some(model.town_life_phone_prune_watermarks),
    posts: model.posts,
    post_reset_stamp: model.town_life_post_reset_stamp,
    post_tombstones: Some(model.town_life_post_tombstones),
    analytics: model.analytics,
    analytics_events: Some(analytics_events),
    analytics_prune_watermarks: Some(model.town_life_analytics_prune_watermarks),
    ecosystem_attention_receipts: Some(model.ecosystem_attention_receipts),
    attention_counters: Some(attention_counters),
    attention_prune_watermarks: Some([]),
    ops_reports: Some(model.ops_reports),
    ops_report_events: Some(report_events),
    ops_report_prune_watermarks: Some(
      model.town_life_ops_report_prune_watermarks,
    ),
    last_report_tick: model.last_report_tick,
    checkin_day: model.checkin_day,
    world_states: Some(model.town_life_world_states),
    post_generation: Some(0),
    deleted_post_ids: Some([]),
  })
}

///|
fn town_life_cumulative_save(
  model : Model,
  disk_texts : ArrayView[String],
) -> TownLifeSave {
  let local = town_life_save_for_model(model)
  match town_life_aggregate_v3_saves(disk_texts) {
    None => local
    Some(disk) => town_life_reconcile_save(disk, local)
  }
}

///|
/// Join the latest durable V3 authority before allocating a new causal dot.
/// This prevents a stale tab from stamping reset/delete below an unseen epoch.
fn town_life_refresh_model_from_storage(model : Model) -> Model {
  match town_life_aggregate_v3_saves(browser_town_life_v3_save_texts()) {
    None => model
    Some(disk) =>
      town_life_model_with_save(
        model,
        town_life_reconcile_save(disk, town_life_save_for_model(model)),
      )
  }
}

///|
fn persist_town_life_model_result(model : Model) -> (Model, Bool) {
  // Read the exact manifest immediately before constructing the cumulative
  // shard. Transport compaction may delete only members represented here.
  let disk_texts = browser_town_life_v3_save_texts()
  let cumulative = town_life_cumulative_save(model, disk_texts)
  let sequence = browser_town_life_v3_next_writer_sequence()
  let written = browser_write_town_life_v3_writer_shard(
    ToJson::to_json(cumulative).stringify(),
    sequence,
  )
  (town_life_model_with_save(model, cumulative), written)
}

///|
fn persist_town_life_model(model : Model) -> Model {
  persist_town_life_model_result(model).0
}

///|
fn town_life_commit(model : Model) -> (Cmd, Model) {
  model_only_update(persist_town_life_model(model))
}
