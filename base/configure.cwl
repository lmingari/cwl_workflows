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
    inputBinding:
      position: 2
      prefix: --source
  meteo_type: 
    type: string?
    inputBinding:
      position: 2
      prefix: --meteo
  meteo_database:
    type: string?
    inputBinding: {prefix: --METEO_DATABASE}
  meteo_file:
    type: File?
    inputBinding: 
      prefix: --METEO_PATH
      valueFrom: $(self.basename)
  meteo_dictionary:
    type: File?
    inputBinding:
      prefix: --METEO_DICTIONARY
      valueFrom: $(self.basename)
  date:
    type: string?
    inputBinding:
      position: 2
      prefix: --date

outputs:
  configuration:
    type: File
    outputBinding:
      glob: "final.inp"

requirements:
  InitialWorkDirRequirement:
    listing:
      - $(inputs.template)
