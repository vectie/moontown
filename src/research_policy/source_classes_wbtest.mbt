///|
test "research policy owns source-class vocabulary" {
  assert_true(core_source_classes().contains("research-institution"))
  assert_true(extended_source_classes().contains("primary-paper"))
  assert_true(candidate_source_classes().contains("source-data"))
  assert_true(front_door_source_classes().contains("standards"))
}
