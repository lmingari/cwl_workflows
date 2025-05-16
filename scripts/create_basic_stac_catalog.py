import os
import json
import rasterio
import xarray as xr
import pystac

from datetime import datetime, timezone
from shapely.geometry import Polygon, mapping

#File directory
data_dir = "./"
output_dir = "./stac_catalog"

#Stac catalog creation
catalog = pystac.Catalog(
    id="etna-2018-eruption-catalog",
    description="STAC catalog with GeoTIFF and NetCDF data from Etna 2018 eruption."
)

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

#search files and add to catalog
for filename in os.listdir(data_dir):
    full_path = os.path.join(data_dir, filename)

    if filename.endswith(".tif") or filename.endswith(".tiff"):
        bbox, footprint = get_bbox_and_footprint_from_raster(full_path)
        media_type = pystac.MediaType.GEOTIFF
        asset_key = "geotiff"

    elif filename.endswith(".nc"):
        print(f"Processing NetCDF file: {filename}")
        bbox, footprint = get_bbox_and_footprint_from_netcdf(full_path)
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

    # Crea subcarpeta para este item si no existe
    item_dir = os.path.join(output_dir, item_id)
    os.makedirs(item_dir, exist_ok=True)

    # Copia el archivo a la subcarpeta
    new_asset_path = os.path.join(item_dir, filename)
    if not os.path.exists(new_asset_path):
        os.system(f"cp '{full_path}' '{new_asset_path}'")

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
catalog.normalize_hrefs(output_dir)
catalog.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)

print(f"STAC catalog saved to: {output_dir}")

#with open(catalog.self_href) as f:
#    print(f.read())
