#!/usr/bin/env cwl-runner
cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
s:softwareVersion: 0.0.1
schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

$graph:
  - id: config
    class: CommandLineTool
    baseCommand: ["fill_template.py"]
    arguments: []
    inputs:
      template:
        type: string
        inputBinding: {prefix: --template}
      meteo_database:
        type: "#fall3d-what-if/MeteoDatabase"
        inputBinding: {prefix: --METEO_DATABASE}
      meteo:
        type: string
        inputBinding: {prefix: --METEO_FILE}
      initial_condition:
        type: "#fall3d-what-if/InitialCondition"
        inputBinding: {prefix: --INITIAL}
      restart:
        type: string
        inputBinding: {prefix: --RESTART_FILE}
      levels:
        type: string?
        inputBinding: {prefix: --LEVELS_FILE}
      date:
        type: string?
        inputBinding: {prefix: --date}
      start_time:
        type: float
        inputBinding: {prefix: --START_TIME}
      end_time:
        type: float
        inputBinding: {prefix: --END_TIME}
      west_lon:
        type: float
        inputBinding: {prefix: --LONMIN}
      east_lon:
        type: float
        inputBinding: {prefix: --LONMAX}
      north_lat:
        type: float
        inputBinding: {prefix: --LATMAX}
      south_lat:
        type: float
        inputBinding: {prefix: --LATMIN}
      dx:
        type: float
        inputBinding: {prefix: --DX}
      dy:
        type: float
        inputBinding: {prefix: --DY}
      nlevels:
        type: int
        inputBinding: {prefix: --NZ}
      source_type: 
        type: string?
        inputBinding: {prefix: --source}
    outputs:
      inp:
        type: File
        outputBinding:
          glob: "*.inp"

  - id: phases
    class: CommandLineTool
    baseCommand: echo
    arguments: ["Creating phases file"]
    inputs:
      scenario: 
        type: "#fall3d-what-if/ScenarioType"
      start_time: float
      end_time: float
    outputs:
      phases:
        type: File
        outputBinding:
          glob: "phases.dat"
    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - entryname: "phases.dat"
            entry: |
              ${
                if (inputs.scenario == "high") {
                  return [inputs.start_time,inputs.end_time,"5000"].join(' ');
                } else if (inputs.scenario == "low") {
                  return [inputs.start_time,inputs.end_time,"1000"].join(' ');
                } else {
                  return [inputs.start_time,inputs.end_time,"3000"].join(' ');
                }
              }

  - id: runner
    class: CommandLineTool
    label: Run FALL3D model
    baseCommand: mpirun
    arguments:
      - prefix: -n
        valueFrom: $(inputs.nx * inputs.ny * inputs.nz)
      - "Fall3d.GNU.r8.mpi.cpu.x"
    inputs:
      task:
        type: string
        default: all
        inputBinding: {position: 0}
      inp: 
        type: File
        inputBinding: {position: 1}
      nx:
        type: int
        inputBinding: {position: 2}
      ny:
        type: int
        inputBinding: {position: 3}
      nz:
        type: int
        inputBinding: {position: 4}
      phases: File
    outputs:
      stdout:
        type: stdout
      stderr:
        type: stderr
      log:
        type: File
        outputBinding:
          glob: "*.Fall3d.log"
      res:
        type: File
        outputBinding:
          glob: "*.res.nc"
    stdout: fall3d.out
    stderr: fall3d.err
    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - $(inputs.inp)
          - $(inputs.phases)

  - id: figures
    class: CommandLineTool
    label: Generate a tif output from a netcdf
    baseCommand: 'netcdf2cog.py'
    arguments: []
    inputs:
      netcdf:
        type: File
        inputBinding: {prefix: --fname}
      key:
        type: string
        inputBinding: {prefix: --key}
      time:
        type: int
        inputBinding: {prefix: --time}
    outputs:
      tif:
        type: File
        outputBinding:
          glob: "*.tif"

  - id: catalog
    class: CommandLineTool
    label: Generate a STAC catalog
    baseCommand: 'create_stac.py'
    arguments: []
    inputs:
      netcdf: 
        type: File
        inputBinding: {prefix: --netcdf}
      tifs: File[]
      scenario:
        type: "#fall3d-what-if/ScenarioType"
        inputBinding: {prefix: --path}
    outputs:
      stac:
        type: Directory
        outputBinding:
          glob: $(inputs.scenario)
    requirements:
      InitialWorkDirRequirement:
        listing:
          - $(inputs.tifs)

  - id: fall3d-what-if 
    class: Workflow
    label: Workflow for the what-if scenario demo
    inputs:
      meteo_database: 
        type: "#fall3d-what-if/MeteoDatabase"
      initial_condition:
        type: "#fall3d-what-if/InitialCondition"
      scenario: 
        type: "#fall3d-what-if/ScenarioType"
      date: string
      start_time: float
      end_time: float
      west_lon: float
      east_lon: float
      north_lat: float
      south_lat: float
      dx: float
      dy: float
      nlevels: int
      times: int[]
      keys: string[]
      nx_mpi: int
      ny_mpi: int
      nz_mpi: int
    outputs:
      stac:
        type: Directory
        outputSource: create_catalog/stac
    steps:
      configure:
        run: "#config"
        in:
          template: 
            default: "/home/lmingari/Downloads/cwl_workflows/examples/terradue/inputs/template.inp"
          meteo: 
            default: "/home/fall3d-9.1.0/Templates/Example.wrf.nc"
          restart:
            default: "/home/lmingari/Downloads/cwl_workflows/examples/terradue/inputs/Example.2008-04-29-12-02.rst.nc"
          meteo_database: meteo_database
          date: date
          start_time: start_time
          end_time: end_time
          west_lon: west_lon
          east_lon: east_lon
          north_lat: north_lat
          south_lat: south_lat
          dx: dx
          dy: dy
          nlevels: nlevels
          initial_condition: initial_condition
        out: [inp]
      set_scenario:
        run: "#phases"
        in:
          scenario: scenario
          start_time: start_time
          end_time: end_time
        out: [phases]
      run_fall3d:
        run: "#runner"
        in:
          inp: configure/inp
          nx: nx_mpi
          ny: ny_mpi
          nz: nz_mpi
          phases: set_scenario/phases
        out: [log,res]
      create_cogs:
        run: "#figures"
        scatter: [time,key]
        scatterMethod: flat_crossproduct
        in:
          netcdf: run_fall3d/res
          key: keys
          time: times
        out: [tif]
      create_catalog:
        run: "#catalog"
        in:
          netcdf: run_fall3d/res
          tifs: create_cogs/tif
          scenario: scenario
        out: [stac]
    requirements:
      StepInputExpressionRequirement: {}
      ScatterFeatureRequirement: {}
      NetworkAccess:
        networkAccess: true
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get_it_alpine_linux_cpu_whatif_opt:latest
      ResourceRequirement:
        coresMax: 4
        ramMax: 16000
      SchemaDefRequirement:
        types:
          - name: MeteoDatabase
            type: enum
            symbols:
              - GFS
              - WRF
              - ERA5
          - name: InitialCondition
            type: enum
            symbols:
              - NONE
              - RESTART
              - INSERTION
          - name: ScenarioType
            type: enum
            symbols:
              - low
              - medium
              - high
