#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Plot simulation times
class: CommandLineTool

baseCommand: python
arguments:
  - valueFrom: $(inputs.script)

inputs:
  script: File
  table:
    type: File
    inputBinding:
      prefix: --input
outputs: 
  figure:
    type: File
    outputBinding:
      glob: "*.png"
