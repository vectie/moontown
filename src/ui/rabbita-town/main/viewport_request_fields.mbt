///|
fn render_request_input_field(
  label : String,
  placeholder : String,
  value : String,
  on_value : (String) -> Cmd,
  wide? : Bool = false,
) -> @rabbita.Html {
  let field_id = request_field_id(label)
  let field_class = if wide {
    "request-field request-field-wide"
  } else {
    "request-field"
  }
  div(class=field_class, [
    @html.label(class="request-label", for_=field_id, label),
    input(id=field_id, class="request-input", placeholder~, value~, on_input=value => {
      on_value(value)
    }),
  ])
}

///|
fn render_request_textarea_field(
  label : String,
  placeholder : String,
  value : String,
  on_value : (String) -> Cmd,
  compact? : Bool = false,
) -> @rabbita.Html {
  let field_id = request_field_id(label)
  let textarea_class = if compact {
    "request-textarea request-textarea-compact"
  } else {
    "request-textarea"
  }
  div(class="request-field", [
    @html.label(class="request-label", for_=field_id, label),
    textarea(
      id=field_id,
      class=textarea_class,
      placeholder~,
      value~,
      on_input=value => on_value(value),
      no_children(),
    ),
  ])
}

///|
fn render_request_status_line(status : String) -> @rabbita.Html {
  div(class="request-actions", [
    p(
      class="request-status tone-\{request_status_tone(status)}",
      attrs=@html.Attrs::build().role("status").aria_live("polite"),
      status,
    ),
  ])
}

///|
fn request_field_id(label : String) -> String {
  match label {
    "Title" => "watch-title"
    "Target book" => "watch-target-book"
    "Check frequency" => "request-check-frequency"
    "Quality threshold" => "watch-quality-threshold"
    "Request" => "watch-request"
    "Book title" => "book-request-title"
    "Book id" => "book-request-id"
    "Websites" => "book-request-websites"
    "Purpose" => "book-request-purpose"
    "Special analysis rules" => "book-request-analysis"
    _ => "request-field"
  }
}
