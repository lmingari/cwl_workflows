#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

requirements:
  InitialWorkDirRequirement:
    listing:
      - $(inputs.template)

baseCommand: python

inputs:
  script:
    type: File
    inputBinding:
      position: 1
  template:
    type: File
    inputBinding:
      position: 2
      prefix: --template
  source_type: 
    type: string
    inputBinding:
      position: 2
      prefix: --source
  meteo_type: 
    type: string
    inputBinding:
      position: 2
      prefix: --meteo

outputs:
  configuration:
    type: File
    outputBinding:
      glob: "final.inp"
