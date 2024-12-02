#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Perform a strong scaling for the miniapp
class: Workflow

inputs:
  script_template: File
  script_plot: File
  template: File
  executable: File
  source_type: string
  meteo_type: string
  nx: int[]
  ny: int[]
  nz: int[]

outputs:
  summary:
    type: string[]
    outputSource: run_scaling/summary
  table:
    type: File
    outputSource: generate_table/table
  figure:
    type: File
    outputSource: plot_time/figure

steps:
  run_scaling:
    run: ../../base/miniapp_workflow.cwl
    scatter: [nx,ny,nz]
    scatterMethod: dotproduct
    in:
      script: script_template
      template: template
      executable: executable
      source_type: source_type
      meteo_type: meteo_type
      nx: nx
      ny: ny
      nz: nz
    out: [summary]

  generate_table:
    run: ../../base/generate_table.cwl
    in:
      summary: run_scaling/summary
    out: [table]

  plot_time:
    run: ../../base/plot_time.cwl
    in:
      table: generate_table/table
      script: script_plot
    out: [figure]

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
