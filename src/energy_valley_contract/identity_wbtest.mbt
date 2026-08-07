///|
test "private ID normalization is idempotent and Unicode-safe" {
  let normalized = normalize_id_part(" 未来 科学城 / North_Gate ")
  assert_eq(normalized, "未来-科学城/north-gate")
  assert_eq(normalize_id_part(normalized), normalized)
}

///|
test "attention signal expiry uses a half-open tick interval" {
  let signal = AttentionSignal::{
    id: { value: "attention-signal/test" },
    target_id: { value: "attention-target/test" },
    source_id: None,
    kind: Ambient,
    intensity_per_mille: 1,
    started_tick: 5,
    expires_tick: Some(8),
  }
  assert_false(signal.is_active(4))
  assert_true(signal.is_active(5))
  assert_true(signal.is_active(7))
  assert_false(signal.is_active(8))
}
