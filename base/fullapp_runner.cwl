#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Run fullapp
class: CommandLineTool

baseCommand: mpirun
arguments:
  - prefix: -n
    valueFrom: $(inputs.nx * inputs.ny * inputs.nz)
  - valueFrom: $(inputs.executable)

inputs:
  executable: File
  task:
    type: ../types/custom_types.yaml#TaskType
    default: all
    inputBinding:
      position: 0
  configuration:
    type: File
    inputBinding:
      position: 1
  nx:
    type: int
    inputBinding:
      position: 2
  ny:
    type: int
    inputBinding:
      position: 3
  nz:
    type: int
    inputBinding:
      position: 4

outputs:
  stdout:
    type: stdout
  logging:
    type: File
    outputBinding:
      glob: "*.log"
  netcdf:
    type: File
    outputBinding:
      glob: "*.nc"

stdout: stdout.out

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.configuration)
  SchemaDefRequirement:
    types:
      - $import: ../types/custom_types.yaml
