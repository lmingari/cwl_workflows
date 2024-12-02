#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

inputs:
  script: File
  template: File
  executable: File
  source_type: string[]
  meteo_type: string[]
  nx: int
  ny: int
  nz: int

outputs:
  summary:
    type: string[]
    outputSource: run_physics/summary

steps:
  run_physics:
    run: miniapp_workflow.cwl
    scatter: [meteo_type,source_type]
    scatterMethod: flat_crossproduct
    in:
      script: script
      template: template
      executable: executable
      source_type: source_type
      meteo_type: meteo_type
      nx: nx
      ny: ny
      nz: nz
    out: [summary]

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
