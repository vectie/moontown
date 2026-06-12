///|
using @editor_pipeline {type EditorPipelineStageInputs}

///|
fn editor_pipeline_stages(
  inputs : EditorPipelineStageInputs,
) -> Array[EditorPipelineStage] {
  @editor_pipeline.pipeline_stages(inputs)
}

///|
fn editor_pipeline_status(inputs : EditorPipelineStageInputs) -> String {
  @editor_pipeline.pipeline_status(inputs)
}
