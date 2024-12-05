#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Run fullapp
class: Workflow

inputs:
  script: File
  template: File
  executable: File
  meteo: ../../types/custom_types.yaml#MeteoType
  date: string
  nx: int
  ny: int
  nz: int

outputs:
  stdout:
    type: File
    outputSource: fullapp_runner/stdout
  logging:
    type: File
    outputSource: fullapp_runner/logging
  netcdf:
    type: File
    outputSource: fullapp_runner/netcdf

steps:
  fullapp_configure:
    run: ../../base/configure.cwl
    in:
      template: template
      script: script
      date: date
      meteo_type:
        source: meteo
        valueFrom: $(self.database)
    out: [configuration]
  fullapp_runner:
    run: ../../base/fullapp_runner.cwl
    in:
      executable: executable
      nx: nx
      ny: ny
      nz: nz
      configuration: fullapp_configure/configuration
    out: [stdout,logging,netcdf]

requirements:
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  SubworkflowFeatureRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: ../../types/custom_types.yaml
