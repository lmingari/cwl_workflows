import argparse
import os
import shutil
import rasterio
import xarray as xr
import pystac
from datetime import datetime, timezone
from loguru import logger
from shapely.geometry import Polygon, mapping

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
    bbox = [float(lon.min()), float(lat.min()), float(lon.max()), float(lat.max())]
    footprint = Polygon([
        [bbox[0], bbox[1]],
        [bbox[0], bbox[3]],
        [bbox[2], bbox[3]],
        [bbox[2], bbox[1]]
    ])
    return bbox, mapping(footprint)

def main(args):
    #Stac catalog creation
    catalog = pystac.Catalog(
        id="generic-catalog",
        description="STAC catalog with GeoTIFF and NetCDF"
        )

    #search files and add to catalog
    for filename in os.listdir():
        if filename.endswith(".tif") or filename.endswith(".tiff"):
            logger.debug(f"Processing TIFF file: {filename}")
            bbox, footprint = get_bbox_and_footprint_from_raster(filename)
            media_type = pystac.MediaType.GEOTIFF
            asset_key = "geotiff"
        elif filename.endswith(".nc"):
            logger.debug(f"Processing NetCDF file: {filename}")
            bbox, footprint = get_bbox_and_footprint_from_netcdf(filename)
            media_type = "application/x-netcdf"
            asset_key = "netcdf"
        else:
            continue  # skip unsupported formats
    
        # Use current time as placeholder
        datetime_utc = datetime.now(tz=timezone.utc)

        # Create item
        item_id = os.path.splitext(filename)[0]
        item = pystac.Item(
            id=item_id,
            geometry=footprint,
            bbox=bbox,
            datetime=datetime_utc,
            properties={}
        )

        # Crea subcarpeta para este item 
        dst = os.path.join(args.path, item_id)
        os.makedirs(dst)
        shutil.copy(filename,dst)

        # Añade el asset apuntando al archivo copiado
        item.add_asset(
            key=asset_key,
            asset=pystac.Asset(
                href=filename,  # relativo a la carpeta del item
                media_type=media_type,
                roles=["data"]
            )
        )
    
        # Añade el item al catálogo
        catalog.add_item(item)

    # Save catalog
    catalog.normalize_hrefs(args.path)
    catalog.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)

if __name__ == "__main__":
    # Argument parser
    parser = argparse.ArgumentParser(description="Create a STAC catalog")
    parser.add_argument("--path", type=str, required=True, help="STAC Catalog folder path")
    args = parser.parse_args()

    logger.info("Creating STAC catalog...")
    if os.path.exists(args.path):
        logger.warning("Catalog folder already exists and will be removed")
        shutil.rmtree(args.path)
    os.makedirs(args.path)

    main(args)
    logger.info("Done!")
