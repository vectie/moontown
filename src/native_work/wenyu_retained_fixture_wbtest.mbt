///|
// Exact bytes of the existing synthetic baseline, retained in the test so
// normal repository tests need no audit path and create no Git commits.
async fn wenyu_materialize_retained_fixture(destination : String) -> Unit {
  let files : Array[(String, String)] = [
    ("moon.mod", "bmFtZSA9ICJ2ZWN0aWUvbW9vbnRvd24iCg=="),
    ("source.mbt", "YmVmb3JlCg=="),
    ("notes.txt", "b3JpZ2luYWwgbm90ZXMK"),
    (".git/HEAD", "cmVmOiByZWZzL2hlYWRzL21hc3Rlcgo="),
    (
      ".git/index", "RElSQwAAAAIAAAADasBJHA3yLjBqwEkcDfIuMAAAACcABf3SAACBpAAAA+gAAAPoAAAAGW7vmNieIVEn8r6IB+wWjppZF1lFAAhtb29uLm1vZAAAasBJHA4Ed/FqwEkcDgR38QAAACcABf3XAACBpAAAA+gAAAPoAAAAD52NyAfQkad8e7I+ur5cnGDsx7OIAAlub3Rlcy50eHQAasBJHA31TlBqwEkcDfVOUAAAACcABf3UAACBpAAAA+gAAAPoAAAAB5C+HzBWxPRx+XeihJe41LOSxVoCAApzb3VyY2UubWJ0AAAAAAAAAABUUkVFAAAAGQAzIDAKQt6kyx44vCUbWgB5+z9XPBKEwMz59wx+W6JKhSnU8KXL8fJIWO1NBw==",
    ),
    (
      ".git/config", "W2NvcmVdCglyZXBvc2l0b3J5Zm9ybWF0dmVyc2lvbiA9IDAKCWZpbGVtb2RlID0gdHJ1ZQoJYmFyZSA9IGZhbHNlCglsb2dhbGxyZWZ1cGRhdGVzID0gdHJ1ZQo=",
    ),
    (
      ".git/refs/heads/master", "ZmRkNjUwNzA4YmIwNDlkZDIxZjFiNzY3MjUyODdkY2JmOWU0MmFmNAo=",
    ),
    (
      ".git/objects/fd/d650708bb049dd21f1b76725287dcbf9e42af4", "eAGdjUsOwiAUAF1zCi6gefwEEmNceY/H6yOSQNsgNT2+Rm/gbjYzQ0trZUjl3WF0Zmn1xGgpKTYhkXYqOQTwMSeTnTekdLAERAK38Vi6vJd9bJ3lJf/gxju2tfKpzC+sZbp+0hFiODtt5RE8gKDvcvBfskj45FpmFm98qzqN",
    ),
    (
      ".git/objects/42/dea4cb1e38bc251b5a0079fb3f573c1284c0cc", "eAErKUpNVTA0NGQwNDAwMzFRyM3Pz9PLzU9hyHs/48Y8xUD1T/s62N+I9c2KFI90harJyy9JLdYrqShhmNt7gv3CxOU11Zvsdu2LmZPw5vjmDqii4vzSouRUvdykEoYJ++QNwo58KfxZvqhl+o4rmycdjWICAKZDMY0=",
    ),
    (
      ".git/objects/90/be1f3056c4f471f977a28497b8d4b392c55a02", "eAFLyslPUjBnSEpNyy9K5QIAIm8EdA==",
    ),
    (
      ".git/objects/9d/8dc807d091a77c7bb23ebabe5c9c60ecc7b388", "eAFLyslPUjA0ZcgvykzPzEvMUcjLL0kt5gIAXFMHzg==",
    ),
    (
      ".git/objects/6e/ef98d89e215127f2be8807ec168e9a59175945", "eAFLyslPUjAyZchLzE1VsFVQKktNLslM1c/Nz88ryS/PU+ICALGxCsM=",
    ),
  ]
  for (relative, encoded) in files {
    let path = destination + "/" + relative
    @support.ensure_parent_directory(path)
    @fs.write_file(path, @base64.decode(encoded), create_mode=CreateNew)
  }
}
