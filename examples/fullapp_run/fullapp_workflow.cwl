#!/usr/bin/env cwl-runnerGG
cwlVersion: v1.2

label: Run fullapp
class: Workflow

inputs:
  script: File
  template: File
  executable: File
  meteo_database: string
  meteo_file: File
  date: string
  nx: int
  ny: int
  nz: int

outputs:
  stdout:
    type: File
    outputSource: runner/stdout
  logging:
    type: File
    outputSource: runner/logging
  netcdf:
    type: File
    outputSource: runner/netcdf

steps:
  configure:
    run: ../../base/configure.cwl
    in:
      template: template
      script: script
      date: date
      meteo_database: meteo_database
      meteo_file: meteo_file
    out: [configuration]
  runner:
    run: ../../base/runner.cwl
    in:
      executable: executable
      meteo_file: meteo_file
      nx: nx
      ny: ny
      nz: nz
      configuration: configure/configuration
    out: [stdout,logging,netcdf]

requirements:
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  SubworkflowFeatureRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.meteo_file)
