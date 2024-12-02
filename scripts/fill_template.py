#!/usr/bin/env python
import argparse
from string import Template
from datetime import datetime 

parser=argparse.ArgumentParser(description="Fill out an input template for miniapp or fullapp")

parser.add_argument("--template", 
                    required=True,
                    metavar='file',
                    help='Template file to be modified')
parser.add_argument("--source", 
                    choices=['point', 'linear'], 
                    default='point', 
                    help='Type of source definition for miniapp')
parser.add_argument("--meteo",
                    choices=['uniform', 'rotational'],
                    default='uniform',
                    help='Type of meteorological data for miniapp')
parser.add_argument("--date",
                    metavar='YYYYMMDD',
                    help='Date string in format YYYYMMDD')

args=parser.parse_args()

fname = args.template
fname_out = "final.inp"

if args.date is None:
    date = datetime.today()
else:
    date = datetime.strptime(args.date,'%Y%m%d')

data = {
    'METEO':  args.meteo,
    'SOURCE': args.source,
    'YEAR':   date.year,
    'MONTH':  date.month,
    'DAY':    date.day,
}

with open(fname, 'r') as f1, open(fname_out,'w') as f2:
    src = Template(f1.read())
    result = src.safe_substitute(data)
    f2.write(result)
