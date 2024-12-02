#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Run miniapp
class: CommandLineTool

baseCommand: mpirun
arguments:
  - prefix: -n
    valueFrom: $(inputs.nx * inputs.ny * inputs.nz)
  - valueFrom: $(inputs.executable)

inputs:
  executable: File
  configuration:
    type: File
    inputBinding:
      position: 0
  nx:
    type: int
    inputBinding:
      position: 1
  ny:
    type: int
    inputBinding:
      position: 2
  nz:
    type: int
    inputBinding:
      position: 3

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
