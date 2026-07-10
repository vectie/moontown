///|
priv struct ModuleInteriorAction {
  label : String
  href : String
}

///|
fn module_interior_district_label(district : String) -> String {
  match district {
    "civic-core" => "Civic Core"
    "north-innovation" => "North Innovation"
    "west-community" => "West Community"
    "lake-learning" => "Lake Learning"
    "lake-exchange" => "Lake Exchange"
    "south-showcase" => "South Showcase"
    "east-river" => "East River"
    "west-research" => "West Research"
    "north-research" => "North Research"
    "east-research" => "East Research"
    _ => district
  }
}

///|
fn module_interior_team_label(runtime : WenyuModuleRuntimeState) -> String {
  match runtime.visible_agent_count {
    0 => "Team idle"
    1 => "1 active"
    count => "\{count} active"
  }
}

///|
fn module_interior_book_label(projection : BookProjectionFragment?) -> String {
  match projection {
    Some(_) => "Book connected"
    None => "Book pending"
  }
}

///|
fn module_interior_attention_label(runtime : WenyuModuleRuntimeState) -> String {
  if runtime.blocked_count > 0 {
    "Recovery needed"
  } else if runtime.review_count > 0 {
    "Review waiting"
  } else if runtime.issue_count > 0 {
    "Setup incomplete"
  } else {
    "No attention"
  }
}

///|
fn module_interior_signal(
  runtime : WenyuModuleRuntimeState,
  projection : BookProjectionFragment?,
) -> String {
  if runtime.blocked_count > 0 {
    "Blocked work needs recovery before this module can proceed."
  } else if runtime.review_count > 0 {
    "Review work is waiting for an operator decision."
  } else if runtime.running_count > 0 {
    "Active work is running inside this module."
  } else if runtime.waiting_count > 0 {
    "Work is waiting for its next input or dispatch window."
  } else {
    match projection {
      Some(_) => "The module is ready and its latest book output is connected."
      None => "The module is ready, but its book output is not connected yet."
    }
  }
}

///|
fn module_interior_action(
  civic : WenyuTownModule,
  runtime : WenyuModuleRuntimeState,
  projection : BookProjectionFragment?,
) -> ModuleInteriorAction? {
  if !module_validation_issues(civic).is_empty() {
    Some({
      label: "Review setup",
      href: "./viewport.html?assets=generated&mode=editor&v=wenyu",
    })
  } else if runtime.blocked_count > 0 || runtime.review_count > 0 {
    Some({
      label: "Review output",
      href: "./viewport.html?assets=generated&mode=output&v=wenyu",
    })
  } else {
    match projection {
      Some(_) => None
      None =>
        Some({
          label: "Open output status",
          href: "./viewport.html?assets=generated&mode=output&v=wenyu",
        })
    }
  }
}

///|
fn render_module_interior_action(
  action : ModuleInteriorAction?,
) -> @rabbita.Html {
  match action {
    Some(action) =>
      a(
        href=action.href,
        class="control-button module-interior-action",
        action.label,
      )
    None => div(class="module-interior-action-empty", no_children())
  }
}

///|
fn render_module_interior_overview(
  civic : WenyuTownModule,
  runtime : WenyuModuleRuntimeState,
  projection : BookProjectionFragment?,
) -> @rabbita.Html {
  section(class="module-interior-overview \{runtime.status_class}", [
    @html.figure(class="module-interior-visual", [
      img(src=civic.asset_base, alt="\{civic.title} building", decoding="async"),
    ]),
    div(class="module-interior-operation", [
      p(class="eyebrow", "Current operation"),
      h3(runtime.status_label),
      p(class="module-interior-purpose", civic.use_case),
      div(class="module-interior-signals", [
        span(module_interior_team_label(runtime)),
        span(module_interior_book_label(projection)),
        span(module_interior_attention_label(runtime)),
      ]),
      div(class="module-interior-current-signal", [
        span(class="module-detail-label", "Current signal"),
        p(module_interior_signal(runtime, projection)),
      ]),
      render_module_interior_action(
        module_interior_action(civic, runtime, projection),
      ),
    ]),
  ])
}
