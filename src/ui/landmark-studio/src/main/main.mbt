///|
extern "js" fn publish(data : String) =
  #| (data) => { globalThis.wenyuLandmarkStudies = JSON.parse(data); }

///|
fn main {
  publish(@models.studies().stringify())
  publish_interior(@models.interior_study().stringify())
  publish_datacenter(
    @models.data_center_study().stringify(),
    load => @models.data_center_report(load).stringify(),
    text => @models.data_center_observation(text).stringify(),
  )
}

///|
extern "js" fn publish_interior(data : String) =
  #| (data) => { globalThis.wenyuInteriorStudy = JSON.parse(data); }

///|
extern "js" fn publish_datacenter(
  data : String,
  report : (Int) -> String,
  observation : (String) -> String,
) =
  #| (data, report, observation) => { globalThis.moonDataCenter = JSON.parse(data); globalThis.moonDataCenterReport = n => JSON.parse(report(n)); globalThis.moonDataCenterObservation = s => JSON.parse(observation(s)); }
