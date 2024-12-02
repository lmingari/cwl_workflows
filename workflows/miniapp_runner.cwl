cwlVersion: v1.2
class: CommandLineTool

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.configuration)

baseCommand: mpirun
arguments:
  - prefix: -n
    valueFrom: $(inputs.nx * inputs.ny * inputs.nz)

inputs:
  executable:
    type: File
    inputBinding:
      position: 1
  configuration:
    type: File
    inputBinding:
      position: 2
  nx:
    type: int
    inputBinding:
      position: 3
  ny:
    type: int
    inputBinding:
      position: 4
  nz:
    type: int
    inputBinding:
      position: 5

outputs:
  stdout:
    type: stdout
  logging:
    type: File
    outputBinding:
      glob: final.Fall3d.log
  netcdf:
    type: File
    outputBinding:
      glob: final.res.nc

stdout: final.out
