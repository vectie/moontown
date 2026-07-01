///|
test "default packet directory uses moontown product home" {
  assert_eq(
    default_packet_directory(),
    @storage.moontown_product_artifact("packets"),
  )
  assert_eq(
    packet_file_path(default_packet_directory(), "packet-task"),
    @storage.moontown_product_artifact("packets/packet-task.json"),
  )
}
