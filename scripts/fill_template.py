#!/usr/bin/env python

import argparse
import logging
from string import Template
from datetime import datetime 

# Configure basic logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("FILL_TEMPLATE")

def main(args):
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

if __name__ == "__main__":
    #
    # Argument parser
    #
    parser=argparse.ArgumentParser(description="Fill out an input template for miniapp or fullapp")
    parser.add_argument("--template", required=True, metavar='file', help='Template file to be modified')
    parser.add_argument("--MINIAPP_SOURCE", choices=['point', 'linear'], default='point', help='Type of source definition for miniapp')
    parser.add_argument("--MINIAPP_METEO", choices=['uniform', 'rotational'], default='uniform', help='Type of meteorological data for miniapp')
    parser.add_argument("--METEO_DATABASE", choices=['GFS','ERA5','WRF'], default='WRF', help='Type of meteorological dataset')
    parser.add_argument("--METEO_FILE", metavar='file', default='', help='Input meteorological file')
    parser.add_argument("--METEO_DICTIONARY", metavar='file', default='', help='Input dictionary for variable decoding')
    parser.add_argument("--INITIAL", choices=['RESTART','NONE'], default='NONE', help='Initial condition')
    parser.add_argument("--RESTART_FILE", metavar='file', default='', help='Restart file in netCDF format')
    parser.add_argument("--LEVELS_FILE", metavar='file', default='', help='Two-columns file with coefficients for hybrid levels')
    parser.add_argument('--LONMIN', metavar='west_longitude', type=float, help='Domain west longitude')
    parser.add_argument('--LONMAX', metavar='east_longitude', type=float, help='Domain east longitude')
    parser.add_argument('--LATMIN', metavar='south_latitude', type=float, help='Domain south latitude')
    parser.add_argument('--LATMAX', metavar='north_latitude', type=float, help='Domain north latitude')
    parser.add_argument('--DX', metavar='longitude_resolution', type=float, help='Domain resolution for longiudes')
    parser.add_argument('--DY', metavar='latitude_resolution', type=float, help='Domain resolution for latitudes')
    parser.add_argument('--NZ', metavar='vertical_levels', type=int, help='Number of vertical levels')
    parser.add_argument("--date", metavar='YYYYMMDD', help='Reference date in format YYYYMMDD')
    parser.add_argument('--START_TIME', metavar='start_time', type=float, help='Start time in hours since date at 00:00')
    parser.add_argument('--END_TIME', metavar='end_time', type=float, help='End time in hours since date at 00:00')

    args=parser.parse_args()
    #
    # Main program
    #
    logger.info("Filling in template...")
    main(args)
    logger.info("Done!")
