#!/usr/bin/env cwl-runner
cwlVersion: v1.2

label: Report run information
class: Workflow

inputs:
  logging: File
  info: string?
outputs:
  time:
    type: string
    outputSource: parse_time/time
  summary:
    type: string
    outputSource: run_info/summary

steps:

  parse_time:
    run:
      class: CommandLineTool
      baseCommand: [awk,'/CPU time/ {printf $NF}']
      inputs:
        logging:
          type: File
          inputBinding: {}
      outputs:
        time:
          type: string
          outputBinding:
            glob: time.dat
            loadContents: true
            outputEval: $(self[0].contents)
      stdout: time.dat
    in: 
      logging: logging
    out: [time]

  run_info:
    run:
      class: ExpressionTool
      inputs:
        time: string
        info: string?
      outputs:
        summary: string
      expression: |
        ${ if(inputs.info === null) {
            return {"summary": inputs.time}; 
           } else {
            return {"summary": [inputs.time,inputs.info].join()}; 
           }
        }
    in:
      time: parse_time/time
      info: info
    out: [summary]

requirements:
  InlineJavascriptRequirement: {}
