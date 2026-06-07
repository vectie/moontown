///|
async test "Wenyu civic pattern manifest covers every civic building as data" {
  let manifest_path = "templates/civic-patterns/wenyu-civic-patterns.json"
  let text = @fs.read_file(manifest_path).text()
  let parsed = @json.parse(text) catch { _ => fail("manifest should parse") }
  let manifest : CivicPatternScenarioManifest = @json.from_json(parsed) catch {
    _ => fail("manifest should match schema")
  }
  let seen : Array[String] = []
  let services = @civic.wenyu_civic_services()
  for template in manifest.templates {
    let path = "templates/civic-patterns/\{template}"
    match load_civic_salon_scenario_file(path) {
      Some(scenario) => {
        assert_true(!seen.contains(scenario.building_id))
        seen.push(scenario.building_id)
        assert_eq(scenario.ideas.length(), 0)
        let matched = services.filter(fn(service) {
          service.id == scenario.building_id
        })
        assert_eq(matched.length(), 1)
        let service = matched[0]
        assert_eq(scenario.building_book_id, service.book_id)
        let pattern_id = match scenario.communication_pattern_id {
          Some(id) => id
          None => ""
        }
        assert_eq(
          pattern_id,
          civic_communication_pattern_id_for_service(service),
        )
        match civic_communication_pattern_for_id(pattern_id) {
          Some(_) => ()
          None => fail("unknown communication pattern id")
        }
        assert_true(scenario.participants.length() >= 3)
      }
      None => fail("expected civic pattern template to load")
    }
  }
  assert_eq(seen.length(), services.length())
  for service in services {
    assert_true(seen.contains(service.id))
  }
}
