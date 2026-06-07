///|
fn html_list_items(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("<li>")
    builder.write_string(value)
    builder.write_string("</li>")
  }
  builder.to_string()
}
