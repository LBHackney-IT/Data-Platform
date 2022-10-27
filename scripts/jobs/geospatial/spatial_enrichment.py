from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
import pyspark.sql.functions as F
from pyspark.sql.types import DoubleType
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, \
    add_import_time_columns, table_exists_in_catalog, clear_target_folder, PARTITION_KEYS
import boto3
import sys

import json
import shapely
import pandas
import geopandas
from shapely.geometry import Point, Polygon
from shapely.errors import WKTReadingError


def wkt_loads(x):
    try:
        return shapely.wkt.loads(x)
    except Exception:
        return None


'''Function not used at the moment. It assumes the input dataframe has columns named (lat, lon) or (latitude, 
longitude) or (easting, northing) or (eastings, northings). Turns the dataframe containing points into a geopandas 
dataframe and generate other coords columns so we always have latitude/longitude and eastings/northings '''


def create_geom_and_extra_coords(pandas_df, target_crs, logger):
    logger.info('starting inside method')
    # Check target CRS is supported
    if not (target_crs in ['epsg:4326', 'epsg:27700']):
        logger.info(f'Target CRS: {target_crs} not supported')
        return f'Target CRS: {target_crs} not supported'
    # rename cols if necessary
    logger.info(f'Target CRS: {target_crs}')
    if set(['lat', 'lon']).issubset(pandas_df.columns):
        pandas_df.rename(columns={'lat': 'latitude', 'lon': 'longitude'}, inplace=True)
        logger.info('lat lon renamed')
    if set(['easting', 'northing']).issubset(pandas_df.columns):
        pandas_df.rename(columns={'easting': 'eastings', 'northing': 'northings'}, inplace=True)
        logger.info('easting northing renamed')
    # if all 4 columns are already here and populated, just create geom in the wished target CRS
    if set(['latitude', 'longitude', 'eastings', 'northings']).issubset(pandas_df.columns):
        logger.info('4 cols present')
        if (target_crs == '27700'):
            geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:27700",
                                                  geometry=geopandas.points_from_xy(pandas_df.eastings,
                                                                                    pandas_df.northings))
            logger.info('geodataframe created in 27700')
        elif (target_crs == '4326'):
            geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:4326",
                                                  geometry=geopandas.points_from_xy(pandas_df.longitude,
                                                                                    pandas_df.latitude))
            logger.info('geodataframe created in 4326')
        return geopandas_df
    # otherwise, if we only have lat lon, create geom and generate eastings/northings
    if set(['latitude', 'longitude']).issubset(pandas_df.columns):
        geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:4326",
                                              geometry=geopandas.points_from_xy(pandas_df.longitude,
                                                                                pandas_df.latitude))
        geopandas_df = geopandas_df.to_crs("EPSG:27700")
        geopandas_df['eastings'] = geopandas_df['geometry'].x
        geopandas_df['northings'] = geopandas_df['geometry'].y
        logger.info('BNG columns generated from lat lon')
        if (target_crs == '27700'):
            return geopandas_df
        elif (target_crs == '4326'):
            geopandas_df = geopandas_df.to_crs("epsg:4326")
            return geopandas_df
    # otherwise, if we only have eastings northings, create geom and generate lat/lon
    if set(['eastings', 'northings']).issubset(pandas_df.columns):
        geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:27700",
                                              geometry=geopandas.points_from_xy(pandas_df.eastings,
                                                                                pandas_df.northings))
        geopandas_df = geopandas_df.to_crs("epsg:4326")
        geopandas_df['longitude'] = geopandas_df['geometry'].x
        geopandas_df['latitude'] = geopandas_df['geometry'].y
        logger.info('lat lon columns generated from BNG')
        if (target_crs == '4326'):
            return geopandas_df
        elif (target_crs == '27700'):
            geopandas_df = geopandas_df.to_crs("epsg:27700")
            return geopandas_df
    logger.info('returned NOTHING!!!')


'''Same method as above, but with more variables for column names and coordinate reference system, so it doesn't 
assume anything on the input table '''


def create_geom_and_extra_coords(pandas_df, source_crs, target_crs, x_column, y_column, logger):
    logger.info(f'starting coords transformation from {source_crs} to {target_crs}')
    # Check target CRS is supported
    if not (target_crs in ['epsg:4326', 'epsg:27700']):
        logger.info(f'Target CRS: {target_crs} not supported')
        return f'Target CRS: {target_crs} is not supported for spatial enrichment'
    # Create geom column from coordinates
    geopandas_df = geopandas.GeoDataFrame(point_df, crs=source_crs,
                                          geometry=geopandas.points_from_xy(pandas_df[x_column], pandas_df[y_column]))
    # If data is not in lat/lon, create lat/lon columns for use in Qlik
    if source_crs != 'epsg:4326':
        geopandas_df_4326 = geopandas_df.to_crs("epsg:4326")
        geopandas_df['longitude'] = geopandas_df_4326['geometry'].x
        geopandas_df['latitude'] = geopandas_df_4326['geometry'].y
    # If data is not in BNG, create easting/northing columns for use in GIS
    if source_crs != 'epsg:27700':
        geopandas_df_27700 = geopandas_df.to_crs("epsg:27700")
        geopandas_df['eastings'] = geopandas_df_27700['geometry'].x
        geopandas_df['northings'] = geopandas_df_27700['geometry'].y
    # If data is not in its target crs, convert it now
    if source_crs != target_crs:
        geopandas_df = geopandas_df.to_crs(target_crs)
    return geopandas_df
    logger.info('Coordiante transformation step returned NOTHING!!!')


'''Replaces nan values with '' in a pandas dataframe, so it can be converted to spark datafrane later even for non 
'string' columns '''


def deal_with_nan_colums(df, boundary_tables_dict):
    columns_with_potential_nan_values = []
    for boundary_table_key in boundary_tables_dict:
        for column_key in boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}):
            columns_with_potential_nan_values.append(
                boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}).get(column_key, {}))
    for column_name in columns_with_potential_nan_values:
        if column_name in df.columns:
            df[column_name] = df[column_name].fillna('')
    return df


'''Converts all coordinate columns to double, to prepare for writing'''


def convert_coordinate_columns_to_double(spark_point_df, x_column, y_column):
    spark_point_df = spark_point_df.withColumn(x_column, spark_point_df[x_column].cast(DoubleType()))
    spark_point_df = spark_point_df.withColumn(y_column, spark_point_df[y_column].cast(DoubleType()))
    if set(['longitude', 'latitude']).issubset(spark_point_df.columns):
        spark_point_df = spark_point_df.withColumn("longitude", spark_point_df.longitude.cast(DoubleType()))
        spark_point_df = spark_point_df.withColumn("latitude", spark_point_df.latitude.cast(DoubleType()))
    if set(['eastings', 'northings']).issubset(spark_point_df.columns):
        spark_point_df = spark_point_df.withColumn("eastings", spark_point_df.eastings.cast(DoubleType()))
        spark_point_df = spark_point_df.withColumn("northings", spark_point_df.northings.cast(DoubleType()))
    return spark_point_df


# Dictionary of all the geography tables available to enrich datasets
boundary_tables_dict = {
    "ward": {"database_name": "unrestricted-raw-zone", "table_name": "geolive_boundaries_hackney_ward",
             "columns_to_append": {"name": "ward_name", "census_code": "ward_ons_code"}},
    "lsoa": {"database_name": "unrestricted-raw-zone", "table_name": "geolive_boundaries_hackney_lsoa_2011",
             "columns_to_append": {"lsoa_name": "lsoa_name", "code": "lsoa_ons_code"}},
    "msoa": {"database_name": "unrestricted-raw-zone", "table_name": "geolive_boundaries_hackney_msoa_2011",
             "columns_to_append": {"msoa11nm": "msoa_name", "msoa11cd": "msoa_ons_code"}}
}

# Dictionary of the imput tables to enrich.
# Commented out because this is now passed as an argument:

# enrich_tables_dict = {
#     "gully_cleanse": {
#         "database_name":"env-services-raw-zone",
#         "table_name":"alloy_api_response_gully_cleanse",
#         "geom_column":"root_attributes_tasksassignabletasks_designs_gullies_attributes_itemsgeometry",
#         "geom_format": "wkt",
#         "source_crs": "epsg:4326",
#         "enrich_with":["ward", "lsoa"],
#         "target_location": "s3://dataplatform-stg-refined-zone/env-services/spatially_enriched/"
#     },
#     "fly_tip_job": {
#         "database_name":"env-services-raw-zone",
#         "table_name":"alloy_api_response_flytipjobs",
#         "geom_column":"attributes_itemsgeometry",
#         "geom_format": "wkt",
#         "source_crs": "epsg:4326",
#         "enrich_with":["ward", "lsoa"],
#         "target_location": "s3://dataplatform-stg-refined-zone/env-services/spatially_enriched/"
#     },
#     "fpn_tickets": {
#         "database_name":"env-enforcement-refined-zone",
#         "table_name":"fpn_tickets",
#         "geom_format": "coords",
#         "x_column": "lon",
#         "y_column": "lat",
#         "source_crs": "epsg:4326",
#         "enrich_with":["lsoa"],
#         "target_location": "s3://dataplatform-stg-refined-zone/env-enforcement/spatially_enriched/"
#     },
#     "noisework": {
#         "database_name":"env-enforcement-refined-zone",
#         "table_name":"noisework_complaints",
#         "geom_format": "coords",
#         "x_column": "lon",
#         "y_column": "lat",
#         "source_crs": "epsg:4326",
#         "enrich_with":["lsoa", "msoa"],
#         "target_location": "s3://dataplatform-stg-refined-zone/env-enforcement/spatially_enriched/"
#     }
# }

if __name__ == "__main__":

    args = getResolvedOptions(sys.argv, ['TempDir', 'JOB_NAME', 'tables_to_enrich_dict'])

    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger = glueContext.get_logger()

    enrich_tables_dict = json.loads(args["tables_to_enrich_dict"])

    # Step 1: load all boundary tables, prepare them and keep the resulting dataframes in the dict for later

    for boundary_table_key in boundary_tables_dict:
        # load the table from S3
        logger.info(f'Loading geography table: {boundary_tables_dict.get(boundary_table_key, {}).get("table_name")}')
        boundary_data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space=boundary_tables_dict.get(boundary_table_key, {}).get("database_name"),
            table_name=boundary_tables_dict.get(boundary_table_key, {}).get("table_name")
        )
        boundary_df = boundary_data_source.toDF()
        boundary_df = get_latest_partitions(boundary_df)

        # Only keep the columns used for enrichment + the geometry
        columns_to_keep = boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}).keys()
        logger.info(f'list of columns to keep in addition to geom: {columns_to_keep}')
        boundary_df = boundary_df.select('geom', *columns_to_keep)
        # rename the enrichemnt columns as defined in the dict
        for column_key in boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}):
            boundary_df = boundary_df.withColumnRenamed(column_key,
                                                        boundary_tables_dict.get(boundary_table_key, {}).get(
                                                            "columns_to_append", {}).get(column_key))
        # Convert to a geo dataframe, assuming the geometry is encoded in WKB (it is the case in postgis)
        boundary_df = boundary_df.toPandas()
        boundary_geometry = boundary_df['geom'].apply(shapely.wkb.loads, args=(True,))
        boundary_df = boundary_df.drop(columns=['geom'])
        boundary_geo_df = geopandas.GeoDataFrame(boundary_df, crs="epsg:27700", geometry=boundary_geometry)
        logger.info(f'boundary frame: {boundary_geo_df.head()}')
        # store the geo df in the dict for later
        boundary_tables_dict[boundary_table_key]["geodataframe"] = boundary_geo_df

    # Step 2: in a loop, load and enrich the tables to enrich

    for enrich_table_key in enrich_tables_dict:
        table_name = enrich_tables_dict.get(enrich_table_key, {}).get("table_name")
        database_name = enrich_tables_dict.get(enrich_table_key, {}).get("database_name")
        if not table_exists_in_catalog(glueContext, table_name, database_name):
            logger.info(f"Couldn't find table {table_name} in database {database_name}, moving onto next table.")
            continue
        # Load the table
        logger.info(f"Now enriching {table_name} in database {database_name}")
        point_data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space=database_name,
            table_name=table_name
        )
        point_df = point_data_source.toDF()
        if point_df.rdd.isEmpty():
            logger.info(f"No data found for {table_name}, moving onto next table to enrich.")
            continue
        point_df = get_latest_partitions(point_df)
        point_df = point_df.toPandas()
        logger.info(f"Points dataset column types before enrichment:\n{point_df.dtypes}")

        # Prepare the spatial dataframe
        geom_format = enrich_tables_dict.get(enrich_table_key, {}).get("geom_format")
        source_crs = enrich_tables_dict.get(enrich_table_key, {}).get("source_crs")
        # Scenario 1: there is a geom column
        if enrich_tables_dict.get(enrich_table_key, {}).get("geom_column"):
            geom_column_name = enrich_tables_dict.get(enrich_table_key, {}).get("geom_column")
            logger.info(f"geom column name:{geom_column_name}")
            if geom_format == "wkt":
                enrich_geo_df = geopandas.GeoDataFrame(point_df, crs=source_crs,
                                                       geometry=point_df[geom_column_name].apply(wkt_loads))
            elif geom_format == "wkb":
                enrich_geo_df = geopandas.GeoDataFrame(point_df, crs=source_crs,
                                                       geometry=point_df[geom_column_name].apply(shapely.wkb.loads,
                                                                                                 args=(True,)))
            else:
                logger.info(
                    f"Couldn't decode geomatry column {geom_column_name} for {table_name} in database {database_name}, moving onto next table.")
                continue
            if (source_crs != '27700'):
                enrich_geo_df = enrich_geo_df.to_crs("epsg:27700")
        # Scenario 2: there is no geom column but 2 coords columns
        elif geom_format == "coords":
            x_column = enrich_tables_dict.get(enrich_table_key, {}).get("x_column")
            y_column = enrich_tables_dict.get(enrich_table_key, {}).get("y_column")
            enrich_geo_df = create_geom_and_extra_coords(point_df, source_crs, 'epsg:27700', x_column, y_column, logger)
        else:
            logger.info(f"Cannot handle geom format: {geom_format}")
            continue

        # Enrich with every relevant table from the boundary tables dictionary
        for boundary_table_key in boundary_tables_dict:
            if boundary_table_key in enrich_tables_dict.get(enrich_table_key, {}).get("enrich_with"):
                boundary_df = boundary_tables_dict[boundary_table_key]["geodataframe"]
                logger.info(f"boundary dataset column types:\n{boundary_df.dtypes}")
                logger.info(f"point dataset column types:\n{enrich_geo_df.dtypes}")
                enrich_geo_df = geopandas.sjoin(enrich_geo_df, boundary_df, how='left', predicate='intersects',
                                                lsuffix='left', rsuffix='right')
                enrich_geo_df = enrich_geo_df.drop(columns=['index_right'])

        # back from geopandas to pandas
        enrich_pd_df = pandas.DataFrame(enrich_geo_df)
        enrich_pd_df = enrich_pd_df.drop(columns=['geometry'])
        logger.info(f"column types in the joint dataframe:\n{enrich_pd_df.dtypes}")

        # deal with nan
        enrich_pd_df = deal_with_nan_colums(enrich_pd_df, boundary_tables_dict)

        # back from pandas to spark
        spark_point_df = spark.createDataFrame(enrich_pd_df)

        # Convert coordinates columns to double (Pandas make them decimal when calculating them)
        if geom_format == "coords":
            spark_point_df = convert_coordinate_columns_to_double(spark_point_df, x_column, y_column)

        # Convert data frame to dynamic frame
        dynamic_frame = DynamicFrame.fromDF(spark_point_df, glueContext, "target_data_to_write")

        # Write the data to S3
        logger.info(
            f'Now writing  {table_name} enriched records inside {enrich_tables_dict.get(enrich_table_key, {}).get("target_location") + table_name}')
        parquet_data = glueContext.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            format="parquet",
            connection_options={
                "path": enrich_tables_dict.get(enrich_table_key, {}).get("target_location") + table_name,
                "partitionKeys": PARTITION_KEYS},
            transformation_ctx=f'target_data_to_write_{table_name}')

    job.commit()