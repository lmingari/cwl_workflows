#!/usr/bin/env cwl-runner
cwlVersion: v1.2

class: CommandLineTool
label: Generate a tif output from a netcdf

baseCommand: python
arguments:
  - valueFrom: $(inputs.script)

inputs:
  script: File
  netcdf: 
    type: File
    inputBinding: {prefix: --fname}
    label: Input netcdf file
  key:
    type: string
    inputBinding: {prefix: --key}
    label: Variable key to be plotted
  time:
    type: int
    inputBinding: {prefix: --time}
    label: Time index to be plotted

outputs:
  tif:
    type: File
    label: Output TIFF file
    outputBinding:
      glob: "*.tif"
