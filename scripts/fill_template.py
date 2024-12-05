#!/usr/bin/env python
import argparse
from string import Template
from datetime import datetime 

parser=argparse.ArgumentParser(description="Fill out an input template for miniapp or fullapp")

parser.add_argument("--template", 
                    required=True,
                    metavar='file',
                    help='Template file to be modified')
parser.add_argument("--MINIAPP_SOURCE", 
                    choices=['point', 'linear'], 
                    default='point', 
                    help='Type of source definition for miniapp')
parser.add_argument("--MINIAPP_METEO",
                    choices=['uniform', 'rotational'],
                    default='uniform',
                    help='Type of meteorological data for miniapp')
parser.add_argument("--METEO_DATABASE", 
                    choices=['GFS','ERA5','WRF'],
                    help='Type of meteorological dataset')
parser.add_argument("--METEO_FILE",
                    metavar='file',
                    default='',
                    help='Input meteorological file')
parser.add_argument("--METEO_DICTIONARY",
                    metavar='file',
                    default='',
                    help='Input dictionary for variable decoding')
parser.add_argument("--date",
                    metavar='YYYYMMDD',
                    help='Date string in format YYYYMMDD')

args=parser.parse_args()

if args.date is None:
    date = datetime.today()
else:
    date = datetime.strptime(args.date,'%Y%m%d')

data = vars(args)
data['YEAR']  = date.year
data['MONTH'] = date.month
data['DAY']   = date.day

fname = args.template
fname_out = "final.inp"

with open(fname, 'r') as f1, open(fname_out,'w') as f2:
    src = Template(f1.read())
    result = src.safe_substitute(data)
    f2.write(result)
