///|
pub fn Mayor::plan_goal(
  self : Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
  explicit_book_id? : String? = None,
) -> MayorGoalPlan {
  ignore(self)
  let prompt = mayor_goal_decomposition_prompt(catalog, goal, explicit_book_id~)
  match explicit_book_id {
    Some(book_id) =>
      match @moonbook.find_catalog_entry(catalog, book_id) {
        Some(entry) =>
          {
            output_contract: "mayor.goal.decomposition.v1",
            prompt,
            parallelizable: false,
            summary: "Mayor bound the goal to the explicit book \{entry.id}.",
            lanes: [goal_lane(entry, goal, entry.id)],
          }
        None =>
          match
            @moonbook.entry_for_explicit_research_book(catalog, book_id, goal) {
            Some(entry) =>
              {
                output_contract: "mayor.goal.decomposition.v1",
                prompt,
                parallelizable: false,
                summary: "Mayor created dynamic research book \{entry.id} for the explicit standing goal target.",
                lanes: [goal_lane(entry, goal, entry.id)],
              }
            None =>
              {
                output_contract: "mayor.goal.decomposition.v1",
                prompt,
                parallelizable: false,
                summary: "Mayor could not find the explicit book \{book_id}.",
                lanes: [],
              }
          }
      }
    None => {
      if @dispatch.wenyu_valley_goal_text(goal) {
        let lanes = wenyu_valley_goal_lanes(goal)
        return {
          output_contract: "mayor.goal.decomposition.v1",
          prompt,
          parallelizable: true,
          summary: "Mayor split the Wenyu Valley build goal into \{lanes.length()} isolated civic product lanes from docs/WENYU_VALLEY_PRD.md.",
          lanes,
        }
      }
      let topics = mayor_research_lane_topics(goal)
      if mayor_should_parallelize_goal(goal, topics) {
        let lanes = topics.map(fn(topic) {
          let entry = @moonbook.parallel_research_entry(topic)
          goal_lane(entry, goal, topic)
        })
        {
          output_contract: "mayor.goal.decomposition.v1",
          prompt,
          parallelizable: true,
          summary: "Mayor split the goal into \{lanes.length()} isolated research lanes because the request names multiple knowledge subjects.",
          lanes,
        }
      } else {
        let selected = select_default_entry(catalog, goal)
        match selected {
          Some(entry) =>
            {
              output_contract: "mayor.goal.decomposition.v1",
              prompt,
              parallelizable: false,
              summary: "Mayor kept the goal inside one book because the request reads as one domain lane.",
              lanes: [goal_lane(entry, goal, entry.id)],
            }
          None =>
            {
              output_contract: "mayor.goal.decomposition.v1",
              prompt,
              parallelizable: false,
              summary: "Mayor found no available book for the goal.",
              lanes: [],
            }
        }
      }
    }
  }
}
