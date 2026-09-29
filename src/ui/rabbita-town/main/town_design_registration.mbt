///|
/// The design is the target; OSM is immutable input. Cache by all three input
/// identities so an asset arriving late cannot leave a stale identity fit.
extern "js" fn town_design_registration_input() -> String =
  #| () => {
  #|   const source = globalThis.__moontownEnergyValleyOsmBlockGraph;
  #|   const design = globalThis.__wenyuReferenceRoadGraph;
  #|   const terrain = globalThis.__wenyuReferenceLabels;
  #|   if (!source || !Array.isArray(design?.rows) || !Array.isArray(terrain?.rows)) {
  #|     delete globalThis.__moontownDesignRegistration;
  #|     return '';
  #|   }
  #|   const previous = globalThis.__moontownDesignRegistration;
  #|   if (previous?.source === source && previous.design === design && previous.terrain === terrain) return '';
  #|   return JSON.stringify({source, design, terrain});
  #| }

///|
extern "js" fn town_design_registration_publish(
  project : (Double, Double, Int) -> Double,
  segment : (Double, Double, Double, Double) -> String,
  before : Double,
  after : Double,
  area : Double,
  displacement : Double,
  conflicts_before : Int,
  conflicts_after : Int,
) -> Unit =
  #| (project, segment, before, after, area, displacement, conflictsBefore, conflictsAfter) => {
  #|   globalThis.__moontownDesignRegistrationRevision = (globalThis.__moontownDesignRegistrationRevision || 0) + 1;
  #|   globalThis.__moontownDesignRegistration = {
  #|     source: globalThis.__moontownEnergyValleyOsmBlockGraph,
  #|     design: globalThis.__wenyuReferenceRoadGraph,
  #|     terrain: globalThis.__wenyuReferenceLabels,
  #|     project, segment, before, after, area, displacement, conflictsBefore, conflictsAfter,
  #|     status: 'candidate-needs-review',
  #|     revision: globalThis.__moontownDesignRegistrationRevision,
  #|   };
  #|   const root = globalThis.document?.documentElement;
  #|   if (root) {
  #|     root.dataset.townDesignFitStatus = 'candidate-needs-review';
  #|     root.dataset.townDesignFitBeforeRms = before.toFixed(3);
  #|     root.dataset.townDesignFitAfterRms = after.toFixed(3);
  #|     root.dataset.townDesignFitMinArea = area.toFixed(6);
  #|     root.dataset.townDesignFitMaxMovement = displacement.toFixed(3);
  #|     root.dataset.townDesignWaterConflictsBefore = String(conflictsBefore);
  #|     root.dataset.townDesignWaterConflictsAfter = String(conflictsAfter);
  #|   }
  #| }

///|
extern "js" fn town_design_registration_revision() -> Int =
  #| () => globalThis.__moontownDesignRegistration?.revision || 0

///|
/// Read-only road registration review; does not unlock operational Map Lab.
extern "js" fn town_design_registration_review_requested() -> Bool =
  #| () => new URLSearchParams(globalThis.location?.search || '').get('registration-review') === '1'

///|
fn town_design_registration_prepare() -> Unit {
  let input = town_design_registration_input()
  if input == "" {
    return
  }
  let parsed = @json.parse(input) catch { _ => Json::null() }
  match parsed {
    { "source": source, "design": design, "terrain": terrain, .. } => {
      let field = @design_registration.fit(source, design, terrain)
      town_design_registration_publish(
        (x, y, axis) => {
          let p = field.project({ x: x / 1000.0, y: y / 1000.0, })
          (if axis == 0 { p.x } else { p.y }) * 1000.0
        },
        (ax, ay, bx, by) => {
          let path = field.segment({ x: ax / 1000.0, y: ay / 1000.0, }, {
            x: bx / 1000.0,
            y: by / 1000.0,
          })
          Json::array(
            path.map(p => {
              Json::array([
                Json::number(p.x * 1000.0),
                Json::number(p.y * 1000.0),
              ])
            }),
          ).stringify()
        },
        field.before_rms,
        field.after_rms,
        field.minimum_area(),
        field.maximum_displacement(),
        @design_registration.identity().water_conflict_edges(source, terrain),
        field.water_conflict_edges(source, terrain),
      )
    }
    _ => ()
  }
}

///|
extern "js" fn town_design_registration_summary() -> String =
  #| () => {
  #|   const fit = globalThis.__moontownDesignRegistration;
  #|   return fit ? `设计优先 · 水域冲突 ${fit.conflictsBefore} → ${fit.conflictsAfter}（待复核）` : '设计配准未加载';
  #| }
