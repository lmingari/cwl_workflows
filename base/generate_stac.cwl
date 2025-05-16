#!/usr/bin/env cwl-runner
cwlVersion: v1.2

class: CommandLineTool
label: Generate a STAC catalog

baseCommand: python
arguments:
  - valueFrom: $(inputs.script)

inputs:
  script: File
  netcdf: File
  tifs: File[]
  path:
    type: string
    inputBinding: {prefix: --path}

outputs:
  catalog:
    type: Directory
    outputBinding:
      glob: $(inputs.path)

requirements:
  InitialWorkDirRequirement:
    listing: 
      - $(inputs.tifs)
      - $(inputs.netcdf)
