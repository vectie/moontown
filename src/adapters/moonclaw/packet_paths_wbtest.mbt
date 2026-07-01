///|
test "default packet directory uses moontown product home" {
  assert_eq(default_packet_directory(), ".moonsuite/products/moontown/packets")
  assert_eq(
    packet_file_path(default_packet_directory(), "packet-task"),
    ".moonsuite/products/moontown/packets/packet-task.json",
  )
}
