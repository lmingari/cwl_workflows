#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Generate summary table
class: CommandLineTool

baseCommand: printf
arguments: 
  - "%s\n"
  - "time,nx,ny,nz"
inputs:
  summary: 
    type: string[]
    inputBinding: {}
outputs:
  table:
    type: stdout
stdout: "summary.csv"
