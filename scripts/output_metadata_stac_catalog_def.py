import sys, os
import shutil
import traceback
from loguru import logger
from pystac import Catalog, CatalogType, write_file
from pystac.asset import Asset
from pystac.extensions.raster import RasterBand, RasterExtension, Histogram, Statistics
from pystac.item import Item
from pystac import MediaType

# Import GDAL with fallback to osgeo.gdal if direct import fails
try:
    import gdal
except:
    from osgeo import gdal

# Enable GDAL exceptions
gdal.UseExceptions()

# Function to collect all STAC items from catalog and nested collections
def get_items(catalog_path):
    cat = Catalog.from_file(catalog_path)
    items = []

    # Collect items from children collections
    for collection in cat.get_children():
        for item in collection.get_items():
            items.append(item)

    # If no collections, get items directly from catalog
    if not items:
        for item in cat.get_items():
            items.append(item)

    return items

# Function to add visualization properties (renders) to the item
def add_renders(item_out):
    renders = {}

    # Single band visualization example
    renders["asset_1"] = {
        "title": "Asset_1 overview",
        "assets": ["asset_1"],
        "rescale": [[0, 2]],
        "resampling": "nearest",
        "colormap": {"0": "#808080", "127": "#006400", "255": "#ff0000"},
        "nodata": 255
    }

    # RGB visualization example
    renders["asset_2"] = {
        "title": "Asset_2 overview",
        "assets": ["red", "green", "blue"],
        "nodata": 0,
        "rescale": [[0, 10000], [0, 10000], [0, 10000]],
        "resampling": "nearest",
        "color_formula": "Gamma RGB 1.5 Sigmoidal RGB 10 0.2 Saturation 1"
    }

    # Attach render settings only for matching assets
    item_out.properties["renders"] = {}
    for key in item_out.assets.keys():
        if key in renders:
            item_out.properties["renders"][f"overview-{key}"] = renders[key]

# Function to extract histogram and statistics from a .tif file using GDAL
def get_histogram_data(in_tif):
    if gdal.GetDriverByName("dods"):
        gdal.GetDriverByName("dods").Deregister()

    try:
        gdalinfo = gdal.Info(in_tif, options=["-stats", "-hist", "-json"])
    except Exception as e:
        if "Cannot find proj.db" not in str(e) and "no version information available" not in str(e):
            raise Exception(f"ERROR gdal.Info -hist : {e}")
        return None

    try:
        os.remove(f"{in_tif}.aux.xml")
    except:
        pass

    return gdalinfo

# Function to set the raster extension (statistics + histogram) to an asset
def set_histogram(asset):
#    in_tif = asset.href if os.path.isabs(asset.href) else os.path.join(".", asset.href)
    if os.path.isabs(asset.href):
        in_tif = asset.href
    else:
        in_tif = os.path.join(os.path.dirname(asset.owner.get_self_href()), asset.href)

    if asset.href.startswith('http'):
        in_tif = asset.href

    logger.info(f"Getting gdaljson_data for {in_tif}")
    gdaljson_data = get_histogram_data(in_tif)

    if not gdaljson_data:
        return

    new_histograms = list(
        map(
            lambda band: Histogram.from_dict(band["histogram"]),
            gdaljson_data["bands"],
        )
    )

    new_stats = list(
        map(
            lambda band: Statistics.create(
                minimum=float(band["metadata"][""]["STATISTICS_MINIMUM"]),
                maximum=float(band["metadata"][""]["STATISTICS_MAXIMUM"]),
                mean=float(band["metadata"][""]["STATISTICS_MEAN"]),
                stddev=float(band["metadata"][""]["STATISTICS_STDDEV"]),
                valid_percent=float(band["metadata"][""]["STATISTICS_VALID_PERCENT"]),
            ),
            gdaljson_data["bands"],
        )
    )

    logger.debug(f"stats: {new_stats}")

    new_bands = []
    for i in range(len(new_stats)):
        new_bands.append(
            RasterBand.create(
                spatial_resolution=gdaljson_data["geoTransform"][1],
                statistics=new_stats[i],
                histogram=new_histograms[i],
            )
        )

    logger.info("Setting Raster bands")
    asset.ext.add("raster")
    RasterExtension.ext(asset).bands = new_bands

# Main function to read catalog, process all items, and write updated catalog
def main(input_path):
    items = get_items(os.path.join(input_path, "catalog.json"))
    logger.debug(f"Found {len(items)} items in catalog")

    cat_out = Catalog.from_file(os.path.join(input_path, "catalog.json"))

    for item in items:
        logger.debug(f"Processing item: {item.id}")

        item.stac_extensions.append("https://stac-extensions.github.io/raster/v1.1.0/schema.json")

        for key, asset in item.assets.items():
            if asset.href.endswith(".tif"):
                set_histogram(asset)

        item.properties["title"] = f"Title for {item.id}"
        add_renders(item)

        cat_out.add_item(item)

    cat_out.normalize_and_save(root_href=input_path, catalog_type=CatalogType.SELF_CONTAINED)
    logger.info("Catalog updated")

if __name__ == "__main__":
    input_path = sys.argv[1]
    main(input_path)
