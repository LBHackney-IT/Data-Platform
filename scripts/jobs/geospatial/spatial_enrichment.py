import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
import pyspark.sql.functions as F
from pyspark.sql.types import DoubleType
# Import spatial python packages - for this to work you need an extra job parameter --additional-python-modules=rtree,geopandas
import shapely
import pandas
import geopandas
from shapely.geometry import Point,Polygon
# Import local helpers
from helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, table_exists_in_catalog, PARTITION_KEYS


def clear_target_folder(s3_bucket_target):
    """
    clears the target folder in S3
    """
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return


def create_geom_and_extra_coords(pandas_df, target_crs, logger):
    """
    Function that turns a dataframe containing points into a geopandas dataframe. It also generates other coords columns so the resulting table contains both latitude/longitude and eastings/northings.
    """
    logger.info('starting inside method')
    # Check target CRS is supported
    if not (target_crs in ['4326','27700']):
        logger.info(f'Target CRS: {target_crs} not supported')
        return f'Target CRS: {target_crs} not supported'
    # rename cols if necessary
    logger.info(f'Target CRS: {target_crs}')
    if set(['lat','lon']).issubset(pandas_df.columns):
        pandas_df.rename(columns={'lat':'latitude','lon':'longitude'},inplace=True)
        logger.info('lat lon renamed')
    if set(['easting','northing']).issubset(pandas_df.columns):
        pandas_df.rename(columns={'easting':'eastings','northing':'northings'},inplace=True)
        logger.info('easting northing renamed')
    # if all 4 columns are already here and populated, just create geom in the wished target CRS
    if set(['latitude','longitude','eastings','northings']).issubset(pandas_df.columns):
        logger.info('4 cols present')
        if (target_crs == '27700'):
            geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:27700", geometry=geopandas.points_from_xy(pandas_df.eastings, pandas_df.northings))
            logger.info('geodataframe created in 27700')
        elif (target_crs == '4326'):
            geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:4326", geometry=geopandas.points_from_xy(pandas_df.longitude, pandas_df.latitude))
            logger.info('geodataframe created in 4326')
        return geopandas_df
    # otherwise, if we only have lat lon, create geom and generate eastings/northings
    if set(['latitude','longitude']).issubset(pandas_df.columns):
        geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:4326", geometry=geopandas.points_from_xy(pandas_df.longitude, pandas_df.latitude))
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
    if set(['eastings','northings']).issubset(pandas_df.columns):
        geopandas_df = geopandas.GeoDataFrame(point_df, crs="epsg:27700", geometry=geopandas.points_from_xy(pandas_df.eastings, pandas_df.northings))
        geopandas_df = geopandas_df.to_crs("epsg:4326")
        geopandas_df['longitude'] = geopandas_df['geometry'].x
        geopandas_df['latitude'] = geopandas_df['geometry'].y
        logger.info('lat lon columns generated from BNG')
        if (target_crs == '4326'):
            return geopandas_df
        elif (target_crs == '27700'):
            geopandas_df = geopandas_df.to_crs("epsg:27700")
            return geopandas_df
    logger.info('No geodataframe returned')


def deal_with_nan_colums(df,boundary_tables_dict):
    """
    This function replaces nan value with an empty string for specific columns passed in a dictionary
    """
    columns_with_potential_nan_values = []
    for boundary_table_key in boundary_tables_dict:
        for column_key in boundary_tables_dict.get(boundary_table_key,{}).get("columns_to_append",{}):
            columns_with_potential_nan_values.append(boundary_tables_dict.get(boundary_table_key,{}).get("columns_to_append",{}).get(column_key,{}))
    for column_name in columns_with_potential_nan_values:
        df[column_name] = df[column_name].fillna('')
    return df


def convert_coordinate_columns_to_double(spark_point_df):
    """
    This function converts all coordinate columns of a spark dataframe to double
    """
    spark_point_df = spark_point_df.withColumn("latitude",spark_point_df.latitude.cast(DoubleType()))
    spark_point_df = spark_point_df.withColumn("longitude",spark_point_df.longitude.cast(DoubleType()))
    spark_point_df = spark_point_df.withColumn("eastings",spark_point_df.eastings.cast(DoubleType()))
    spark_point_df = spark_point_df.withColumn("northings",spark_point_df.northings.cast(DoubleType()))
    return spark_point_df


# Dictionary of the geography tables we're using for the enrichment     
#  format: {
    # "key1": {"database_name":"", "table_name":"", "columns_to_append":{"column_1_to_append_to_enriched_table":"alias_for_column_1_in_enriched_table","column_2_to_append_to_enriched_table":"alias_for_column_2_in_enriched_table"}},
    # "key2": {"database_name":"", "table_name":"", "columns_to_append":{"column_1_to_append_to_enriched_table":"alias_for_column_1_in_enriched_table","column_2_to_append_to_enriched_table":"alias_for_column_2_in_enriched_table"}}
    # }                
boundary_tables_dict = {
    "ward": {"database_name":"unrestricted-raw-zone", "table_name":"geolive_boundaries_hackney_ward","columns_to_append":{"name":"ward_name", "census_code":"ward_ons_code"}},
    "lsoa": {"database_name":"unrestricted-raw-zone", "table_name":"geolive_boundaries_hackney_lsoa_2011","columns_to_append":{"code":"lsoa_ons_code", "lsoa_name":"lsoa_name"}},
    "msoa": {"database_name":"unrestricted-raw-zone", "table_name":"geolive_boundaries_hackney_msoa_2011","columns_to_append":{"msoa11cd":"msoa_ons_code", "msoa11nm":"msoa_name"}}
}

if __name__ == "__main__":

    # get args and job parameters
    args = getResolvedOptions(sys.argv, ['TempDir','JOB_NAME'])

    table_list_string = get_glue_env_var('table_list','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    
    # start session
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger = glueContext.get_logger()
    
    # wipe out the target folder
    logger.info(f'clearing target bucket')
    clear_target_folder(s3_bucket_target)
    
    # load all boundary tables, prepare them and keep them in a list of geodataframes for later
    list_boundary_df = []

    for boundary_table_key in boundary_tables_dict:
        #load the table from S3
        boundary_data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space = boundary_tables_dict.get(boundary_table_key, {}).get("database_name"),
            table_name = boundary_tables_dict.get(boundary_table_key, {}).get("table_name")
        )
        boundary_df = boundary_data_source.toDF()
        boundary_df = get_latest_partitions(boundary_df)
        logger.info(f'list of columns to keep in addition to geom: {boundary_tables_dict[boundary_table_key]["columns_to_append"].keys()}')
        #select these columns + geom
        columns_to_keep = boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}).keys()
        boundary_df = boundary_df.select('geom',*columns_to_keep)

        for column_key in boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}):
            # rename these columns
            boundary_df = boundary_df.withColumnRenamed(column_key, boundary_tables_dict.get(boundary_table_key, {}).get("columns_to_append", {}).get(column_key))
        boundary_df = boundary_df.toPandas()
        boundary_geometry = boundary_df['geom'].apply(shapely.wkb.loads, args=(True,)) 
        boundary_df = boundary_df.drop(columns=['geom'])
        boundary_geo_df = geopandas.GeoDataFrame(boundary_df, crs="epsg:27700", geometry=boundary_geometry)
        logger.info(f'wards frame: {boundary_geo_df.head()}')
        #put the geo df in a list
        list_boundary_df.append(boundary_geo_df)

    # load list of tables to enrich. They should all be in the same database, and a version with _to_enrich prefix should exist in the glue catalogue.
    table_list = table_list_string.split(',')
    
    for table in table_list:
        table_name = f'{table}_to_geocode'
        if not table_exists_in_catalog(glueContext, table_name, source_catalog_database):
            logger.info(f"Couldn't find table {table_name} in database {source_catalog_database}, moving onto next table.")
            continue
        logger.info(f"Now enriching {table_name} in database {source_catalog_database}")
        # load points table with lat/lon or eastings/northings
        point_data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=table_name
        )
        
        point_df = point_data_source.toDF()
        point_df = get_latest_partitions(point_df)
        point_df = point_df.toPandas()
        logger.info(f"Points dataset column types:\n{point_df.dtypes}")
        
        # Prepare the spatial dataframe
        point_geo_df = create_geom_and_extra_coords(point_df,'27700',logger)
        
        # Enrich with every table from the list list_boundary_df
        for boundary_df in list_boundary_df:
            logger.info(f"boundary dataset column types:\n{boundary_df.dtypes}")
            logger.info(f"point dataset column types:\n{point_geo_df.dtypes}")
            point_geo_df = geopandas.sjoin(point_geo_df, boundary_df, how='left', predicate='intersects', lsuffix='left', rsuffix='right')
            point_geo_df = point_geo_df.drop(columns=['index_right'])
        
        # back from geopandas to pandas
        point_pd_df = pandas.DataFrame(point_geo_df)
        point_pd_df = point_pd_df.drop(columns=['geometry'])
        logger.info(f'jointframe: {point_pd_df.head()}')
        logger.info(f"column types:\n{point_pd_df.dtypes}")
        
        # deal with nan values in enriched df (if not Spark will consider them as strings)
        point_pd_df = deal_with_nan_colums(point_pd_df,boundary_tables_dict)
        
        # back from pandas to spark
        spark_point_df = spark.createDataFrame(point_pd_df)
        
        # Convert coordinates columns to double (Pandas made them decimal when calculating them)
        spark_point_df = convert_coordinate_columns_to_double(spark_point_df)
        
        # Convert data frame to dynamic frame 
        dynamic_frame = DynamicFrame.fromDF(spark_point_df, glueContext, "target_data_to_write")
        
        # Write the data to S3
        logger.info(f'Now writing  {table_name} enriched records inside {s3_bucket_target}')
        parquet_data = glueContext.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            format="parquet",
            connection_options={"path":s3_bucket_target, "partitionKeys": PARTITION_KEYS},
            transformation_ctx=f'target_data_to_write_{table}')
    
    job.commit()
