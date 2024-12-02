#!/usr/bin/env python
import argparse
from string import Template
import datetime 

parser=argparse.ArgumentParser(description="Fill out template")

parser.add_argument("--template", required=True)
parser.add_argument("--source", choices=['point', 'linear'], default='point')
parser.add_argument("--meteo",  choices=['uniform', 'rotational'], default='uniform')
args=parser.parse_args()

fname = args.template
fname_out = "final.inp"

today = datetime.datetime.now(datetime.UTC)

data = {
    'METEO':  args.meteo,
    'SOURCE': args.source
}

with open(fname, 'r') as f1, open(fname_out,'w') as f2:
    src = Template(f1.read())
    result = src.safe_substitute(data)
    f2.write(result)
