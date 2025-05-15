#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Run fullapp
class: CommandLineTool
doc: |
  CWL workflow to run FALL3D executable using mpirun.
  This workflow provides a standardized way to execute the MPI program
  with configurable number of processes and other parameters.

baseCommand: mpirun
arguments:
  - prefix: -n
    valueFrom: $(inputs.nx * inputs.ny * inputs.nz)
  - valueFrom: $(inputs.executable)

inputs:

  # Executable provided as a string instead of a file
  # since the executable could be provided by the container 
  executable: 
    type: string
    default: "Fall3d.x"
    doc: "MPI executable of FALL3D"

  # Meteorological data required by task "ALL"
  meteo: ../types/custom_types.yaml#MeteoType

  task:
    type: ../types/custom_types.yaml#TaskType
    default: all
    inputBinding:
      position: 0
  
  # FALL3D configuration file (*.inp)
  configuration:
    type: File
    inputBinding:
      position: 1

  # Domain decomposition configuration
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
      glob: "*.Fall3d.log"
  netcdf:
    type: File
    outputBinding:
      glob: "*.res.nc"

stdout: stdout.out

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.configuration)
      - $(inputs.meteo.file)
      - $(inputs.meteo.dictionary)
  SchemaDefRequirement:
    types:
      - $import: ../types/custom_types.yaml
