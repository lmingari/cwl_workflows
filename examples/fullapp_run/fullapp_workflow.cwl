#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Run fullapp
class: Workflow

hints:
  DockerRequirement:
    dockerPull: dtgeo/fall3d_alpine_linux_cpu_v9.1.0:latest
  ResourceRequirement:
    coresMax: 4

inputs:
  script_fill: File
  script_cog: File
  script_stac: File
  template: File
  executable: string
  meteo: ../../types/custom_types.yaml#MeteoType
  date: string
  nx: int
  ny: int
  nz: int
  times: int[]
  keys: string[]
  stac_path: string

outputs:
  stac_catalog:
    type: Directory
    outputSource: stac/catalog

steps:
  configure:
    run: ../../base/configure.cwl
    in:
      template: template
      script: script_fill
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
  figures:
    run: ../../base/generate_cog.cwl
    scatter: [time,key]
    scatterMethod: flat_crossproduct
    in:
      script: script_cog
      netcdf: runner/netcdf
      key: keys
      time: times
    out: [tif]
  stac:
    run: ../../base/generate_stac.cwl
    in:
      script: script_stac
      netcdf: runner/netcdf
      tifs: figures/tif
      path: stac_path
    out: [catalog]

requirements:
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: ../../types/custom_types.yaml
