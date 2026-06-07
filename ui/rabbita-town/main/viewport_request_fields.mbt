///|
fn render_request_input_field(
  label : String,
  placeholder : String,
  value : String,
  on_value : (String) -> Cmd,
  wide? : Bool = false,
) -> @rabbita.Html {
  let field_class = if wide {
    "request-field request-field-wide"
  } else {
    "request-field"
  }
  div(class=field_class, [
    p(class="request-label", label),
    input(
      class="request-input",
      placeholder~,
      value~,
      on_input=value => on_value(value),
      "",
    ),
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
  let textarea_class = if compact {
    "request-textarea request-textarea-compact"
  } else {
    "request-textarea"
  }
  div(class="request-field", [
    p(class="request-label", label),
    textarea(
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
    p(class="request-status tone-\{request_status_tone(status)}", status),
  ])
}
