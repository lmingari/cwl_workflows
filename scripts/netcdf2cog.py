import argparse
import xarray as xr
import numpy as np
import rasterio
from rasterio.transform import from_origin
from rasterio.enums import Resampling
from rasterio.shutil import copy
import os

def rasterio_save(result_array: np.ndarray, profile, outfile_name, transparency_indexes=None, dtype=rasterio.float32):
    """
    Guarda un array como Cloud-Optimized GeoTIFF (COG) en float32.
    """
    factors = [2, 4, 8, 16, 32, 64]

    if transparency_indexes is not None:
        result_array[:, transparency_indexes[0], transparency_indexes[1]] = np.nan

    with rasterio.Env():
        count = result_array.shape[0] if result_array.ndim == 3 else 1

        profile.update(
            dtype=dtype,
            count=count,
            compress="deflate",
            tiled=True,
            blockxsize=256,
            blockysize=256,
            driver='GTiff',
            BIGTIFF='IF_NEEDED'
        )

        temp_file = outfile_name.replace('.tif', '_temp.tif')

        try:
            with rasterio.open(temp_file, "w", **profile) as dst:
                dst.write(result_array.astype(dtype))
                dst.build_overviews(factors, Resampling.average)
                dst.update_tags(ns='rio_overview', resampling='average')

            copy(temp_file, outfile_name, copy_src_overviews=True, driver='COG', compress="deflate")

        finally:
            if os.path.exists(temp_file):
                os.remove(temp_file)

def main(args):
    # Abrir NetCDF
    ds = xr.open_dataset(args.fname)

    # Information list to build output filename
    info_list = [args.key]

    # Verificar dimensiones presentes
    has_fl = 'fl' in ds[args.key].dims
    has_col_mass = 'intensity_measure_col_mass' in ds[args.key].dims
    has_con = 'intensity_measure_con' in ds[args.key].dims

    # Selección de datos
    da = ds[args.key]
    if has_fl:
        da = da.sel(fl=args.selected_fl)
        info_list.append(f"fl{args.selected_fl}")
    if has_col_mass:
        da = da.sel(intensity_measure_col_mass=args.selected_intensity_measure_col_mass)
        info_list.append(f"cm{args.selected_intensity_measure_col_mass}")
    if has_con:
        da = da.sel(intensity_measure_con=args.selected_intensity_measure_con)
        info_list.append(f"cn{args.selected_intensity_measure_con}")

    # Time indexing
    nt = da.sizes['time']
    if args.time == -1:
        print("Using last time...")
        it = nt - 1
    elif args.time < 0:
        print("Time out of range. Using first time...")
        it = 0
    elif args.time>=nt:
        print("Time out of range. Using last time...")
        it = nt - 1
    else:
        it = args.time
    info_list.append(f"t{it:03}")
    da = da.isel(time=it)

    # Convertir a NumPy
    data = da.values.astype(np.float32)

    # Obtener lat/lon
    lat = ds.lat.values
    lon = ds.lon.values

    # Calcular tamaño de pixel
    pixel_size_y = abs(lat[1] - lat[0])
    pixel_size_x = abs(lon[1] - lon[0])

    # Definir transformación para GeoTIFF
    top_left_x = lon.min()
    top_left_y = lat.max()
    transform = from_origin(top_left_x, top_left_y, pixel_size_x, pixel_size_y)

    profile = {
        "driver": "GTiff",
        "height": data.shape[0],
        "width": data.shape[1],
        "count": 1,
        "dtype": rasterio.float32,
        "crs": "EPSG:4326",
        "transform": transform,
    }

    # Añadir una dimensión a los datos para que sea compatible con rasterio_save (espera 3D)
    data = np.expand_dims(data, axis=0)

    # Guardar como Cloud-Optimized GeoTIFF
    fname_out = '-'.join(info_list) + ".tif"
    print(f"Saving COG GeoTIFF file {fname_out}")
    rasterio_save(data, profile, fname_out)

if __name__ == "__main__":
    # Argument parser
    parser = argparse.ArgumentParser(description="Convert NetCDF to Cloud-Optimized GeoTIFF (COG).")
    parser.add_argument("--fname", type=str, required=True, help="Path to NetCDF file")
    parser.add_argument("--key",   type=str, required=True, help="Variable name in NetCDF")
    parser.add_argument("--time",  type=int, required=True, help="Index time")
    parser.add_argument("--selected_fl", type=int, default=0, help="Selected flight level")
    parser.add_argument("--selected_intensity_measure_con", type=float, default=0, help="Selected intensity concentration measure")
    parser.add_argument("--selected_intensity_measure_col_mass", type=float, default=0, help="Selected intensity measure column mass")
    args = parser.parse_args()

    main(args)
