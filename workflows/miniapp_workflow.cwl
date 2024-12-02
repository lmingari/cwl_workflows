#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: Run miniapp

inputs:
  script: File
  template: File
  source_type: string
  meteo_type: string
  executable: File
  nx: int
  ny: int
  nz: int

outputs:
  stdout:
    type: File
    outputSource: miniapp_runner/stdout
  logging:
    type: File
    outputSource: miniapp_runner/logging
  netcdf:
    type: File
    outputSource: miniapp_runner/netcdf
  time:
    type: string
    outputSource: run_info/time
  summary:
    type: string
    outputSource: run_info/summary

steps:
  miniapp_configure:
    run: miniapp_configure.cwl
    in:
      template: template
      script: script
      source_type: source_type
      meteo_type: meteo_type
    out: [configuration]
  miniapp_runner:
    run: miniapp_runner.cwl
    in:
      executable: executable
      nx: nx
      ny: ny
      nz: nz
      configuration: miniapp_configure/configuration
    out: [stdout,logging,netcdf]
  run_info:
    run: run_info.cwl
    in:
      logging: miniapp_runner/logging
      info: 
        source: 
          - nx
          - ny
          - nz
          - source_type
          - meteo_type
        valueFrom: "$(self.join())"
    out: [time,summary]

requirements:
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  SubworkflowFeatureRequirement: {}

