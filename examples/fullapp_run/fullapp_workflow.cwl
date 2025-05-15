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
      meteo_database:
        source: meteo
        valueFrom: $(self.database)
      meteo_file:
        source: meteo
        valueFrom: $(self.file.basename)
      meteo_dictionary:
        source: meteo
        valueFrom: $(self.dictionary.basename)
    out: [configuration]
  runner:
    run: ../../base/runner.cwl
    in:
      executable: executable
      meteo: meteo
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
  SchemaDefRequirement:
    types:
      - $import: ../../types/custom_types.yaml
