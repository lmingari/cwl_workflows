#!/usr/bin/env python

import argparse
import os
import shutil
import rasterio
import xarray as xr
import pystac
import logging
from pathlib import Path
from datetime import datetime, timezone
from shapely.geometry import Polygon, mapping

# Configure basic logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("CREATE_STAC")

#Obtain bbox/footprint from raster (GeoTIFF)
def get_bbox_and_footprint_from_raster(raster_path):
    with rasterio.open(raster_path) as src:
        bounds = src.bounds
        bbox = [bounds.left, bounds.bottom, bounds.right, bounds.top]
        footprint = Polygon([
            [bounds.left, bounds.bottom],
            [bounds.left, bounds.top],
            [bounds.right, bounds.top],
            [bounds.right, bounds.bottom]
        ])
        return bbox, mapping(footprint)

#Obtain bbox/footprint from NetCDF (use lon/lat)
def get_bbox_and_footprint_from_netcdf(nc_path):
    ds = xr.open_dataset(nc_path)
    lon = ds["lon"].values
    lat = ds["lat"].values
    bbox = [
        ds.lon.minimum, 
        ds.lat.minimum, 
        ds.lon.maximum + ds.lon.cell_measures,
        ds.lat.maximum + ds.lat.cell_measures
    ]
    footprint = Polygon([
        [bbox[0], bbox[1]],
        [bbox[0], bbox[3]],
        [bbox[2], bbox[3]],
        [bbox[2], bbox[1]]
    ])
    return bbox, mapping(footprint)

def get_asset_from_filename(filename):
    if filename.endswith(".tif") or filename.endswith(".tiff"):
        logger.debug(f"Processing TIFF file: {filename}")
        media_type = pystac.MediaType.GEOTIFF
        key = Path(filename).stem
    elif filename.endswith(".nc"):
        logger.debug(f"Processing NetCDF file: {filename}")
        media_type = "application/x-netcdf"
        key = 'netcdf'
    else:
        raise ValueError("tried to add a not allowed asset. Add files with extension tif/tiff/nc")

    asset = pystac.Asset(
            href       = Path(filename).name,
            media_type = media_type,
            roles      = ["data"] 
            )
    return (key,asset)


def main(args):
    #
    # Get geospatial data
    #
    bbox, geometry = get_bbox_and_footprint_from_netcdf(args.netcdf)
    #
    # Create the main item
    #
    item_id = "results"
    item = pystac.Item(
        id         = item_id,
        datetime   = datetime.now(tz=timezone.utc),
        bbox       = bbox,
        geometry   = geometry,
        properties = {} )
    #
    # Create subfolder for this item
    #
    dst = os.path.join(args.path, item_id)
    os.makedirs(dst)
    #
    # Add netcdf file asset
    #
    key, asset = get_asset_from_filename(args.netcdf)
    item.add_asset(key=key, asset=asset)
    shutil.copy(args.netcdf,dst)
    #
    # Add tif file assets in the working folder
    #
    for filename in os.listdir():
        if filename.endswith(".tif") or filename.endswith(".tiff"):
            key, asset = get_asset_from_filename(filename)
            item.add_asset(key=key, asset=asset)
            shutil.copy(filename,dst)
    #
    # Validate item
    #
    item.validate()
    #
    # Create STAC catalog
    #
    catalog = pystac.Catalog(
        id          = "what-if-demo-catalog",
        description = "STAC catalog with GeoTIFF and NetCDF")
    #
    # Add item to catalog
    #
    catalog.add_item(item)
    #
    # Save catalog
    #
    catalog.normalize_hrefs(args.path)
    catalog.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)

if __name__ == "__main__":
    #
    # Argument parser
    #
    parser = argparse.ArgumentParser(description="Create a STAC catalog")
    parser.add_argument("--path",   type=str, required=True, help="STAC Catalog folder path")
    parser.add_argument("--netcdf", type=str, required=True, help="netCDF file")
    args = parser.parse_args()
    #
    # Create catalog folder
    #
    logger.info("Creating STAC catalog...")
    if os.path.exists(args.path):
        logger.warning("Catalog folder already exists and will be removed")
        shutil.rmtree(args.path)
    os.makedirs(args.path)
    #
    # Main program
    #
    main(args)
    logger.info("Done!")
