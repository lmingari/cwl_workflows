#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Set run configuration
class: CommandLineTool

baseCommand: python
arguments:
  - valueFrom: $(inputs.script)

inputs:
  script: File
  template:
    type: File
    inputBinding:
      position: 1
      prefix: --template
  source_type: 
    type: string?
    inputBinding: {prefix: --source}
  meteo_type: 
    type: string?
    inputBinding: {prefix: --meteo}
  meteo_database:
    type: string?
    inputBinding: {prefix: --METEO_DATABASE}
  meteo_file:
    type: string?
    inputBinding: {prefix: --METEO_FILE}
  meteo_dictionary:
    type: string?
    inputBinding: {prefix: --METEO_DICTIONARY}
  date:
    type: string?
    inputBinding: {prefix: --date}

outputs:
  configuration:
    type: File
    outputBinding:
      glob: "final.inp"

requirements:
  InitialWorkDirRequirement:
    listing:
      - $(inputs.template)
