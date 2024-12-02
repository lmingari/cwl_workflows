#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

inputs:
  script: File
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
    run: miniapp_workflow.cwl
    scatter: [nx,ny,nz]
    scatterMethod: dotproduct
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

  generate_table:
    run:
      label: Generate summary table
      class: CommandLineTool
      baseCommand: printf
      arguments: 
        - "%s\n"
        - "time,nx,ny,nz,source,meteo"
      inputs:
        summary: 
          type: string[]
          inputBinding: {}
      outputs:
        table:
          type: stdout
      stdout: "summary.csv"
    in:
      summary: run_scaling/summary
    out: [table]

  plot_time:
    run:
      label: Plot simulation times
      class: CommandLineTool
      baseCommand: python
      inputs:
        script_plot:
          type: File
          inputBinding:
            position: 1
        table:
          type: File
          inputBinding:
            prefix: --input
            position: 2
      outputs: 
        figure:
          type: File
          outputBinding:
            glob: times.png
    in:
      table: generate_table/table
      script_plot: script_plot
    out: [figure]

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
