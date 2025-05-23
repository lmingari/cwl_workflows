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
        type: File
        inputBinding: {prefix: --template}
      meteo_database:
        type: string
        inputBinding: {prefix: --METEO_DATABASE}
      meteo_fname:
        type: string
        inputBinding: {prefix: --METEO_FILE}
      date:
        type: string?
        inputBinding: {prefix: --date}
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
      scenario: string
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
                  return "0 24 5000";
                } else if (inputs.scenario == "low") {
                  return "0 24 1000";
                } else {
                  return "0 24 3000";
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
#      - "/home/fall3d-9.1.0/build/bin/Fall3d.GNU.r8.mpi.cpu.x"
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
      meteo_file: File
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
      netcdf:
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
          - $(inputs.meteo_file)
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
      netcdf: File
      tifs: File[]
      path:
        type: string
        inputBinding: {prefix: --path}
    outputs:
      stac:
        type: Directory
        outputBinding:
          glob: $(inputs.path)
    requirements:
      InitialWorkDirRequirement:
        listing:
          - $(inputs.tifs)
          - $(inputs.netcdf)

  - id: main 
    class: Workflow
    label: Workflow for the what-if scenario demo
    inputs:
      template: File
      meteo_file: File
      meteo_database: string
      date: string
      times: int[]
      keys: string[]
      nx: int
      ny: int
      nz: int
      scenario: string
    outputs:
      stac:
        type: Directory
        outputSource: create_catalog/stac
    steps:
      configure:
        run: "#config"
        in:
          template: template
          meteo_fname: 
            source: meteo_file
            valueFrom: $(self.basename)
          meteo_database: meteo_database
          date: date
        out: [inp]
      set_scenario:
        run: "#phases"
        in:
          scenario: scenario
        out: [phases]
      run_fall3d:
        run: "#runner"
        in:
          inp: configure/inp
          nx: nx
          ny: ny
          nz: nz
          meteo_file: meteo_file
          phases: set_scenario/phases
        out: [stdout,stderr,log,netcdf]
#        requirements:
#          DockerRequirement:
#            dockerPull: docker.io/dtgeo/fall3d_alpine_linux_cpu_v9.1.0:latest
      create_cogs:
        run: "#figures"
        scatter: [time,key]
        scatterMethod: flat_crossproduct
        in:
          netcdf: run_fall3d/netcdf
          key: keys
          time: times
        out: [tif]
      create_catalog:
        run: "#catalog"
        in:
          netcdf: run_fall3d/netcdf
          tifs: create_cogs/tif
          path: scenario
        out: [stac]
    requirements:
      StepInputExpressionRequirement: {}
      ScatterFeatureRequirement: {}
      NetworkAccess:
        networkAccess: true
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get_it_alpine_linux_cpu_demo2:latest
      ResourceRequirement:
        coresMax: 4
        ramMax: 16000
