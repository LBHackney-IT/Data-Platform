from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

from pyspark.sql.types import DoubleType
from scripts.helpers.helpers import table_exists_in_catalog, create_pushdown_predicate_for_max_date_partition_value

import sys

import json
import shapely
import pandas
import geopandas


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
    if {'lat', 'lon'}.issubset(pandas_df.columns):
        pandas_df.rename(columns={'lat': 'latitude', 'lon': 'longitude'}, inplace=True)
        logger.info('lat lon renamed')
    if {'easting', 'northing'}.issubset(pandas_df.columns):
        pandas_df.rename(columns={'easting': 'eastings', 'northing': 'northings'}, inplace=True)
        logger.info('easting northing renamed')
    # if all 4 columns are already here and populated, just create geom in the wished target CRS
    if {'latitude', 'longitude', 'eastings', 'northings'}.issubset(pandas_df.columns):
        logger.info('4 cols present')
        if target_crs == '27700':
            geopandas_df = geopandas.GeoDataFrame(pandas_df, crs="epsg:27700",
                                                  geometry=geopandas.points_from_xy(pandas_df.eastings,
                                                                                    pandas_df.northings))
            logger.info('geodataframe created in 27700')
        elif target_crs == '4326':
            geopandas_df = geopandas.GeoDataFrame(pandas_df, crs="epsg:4326",
                                                  geometry=geopandas.points_from_xy(pandas_df.longitude,
                                                                                    pandas_df.latitude))
            logger.info('geodataframe created in 4326')
        return geopandas_df
    # otherwise, if we only have lat lon, create geom and generate eastings/northings
    if {'latitude', 'longitude'}.issubset(pandas_df.columns):
        geopandas_df = geopandas.GeoDataFrame(pandas_df, crs="epsg:4326",
                                              geometry=geopandas.points_from_xy(pandas_df.longitude,
                                                                                pandas_df.latitude))
        geopandas_df = geopandas_df.to_crs("EPSG:27700")
        geopandas_df['eastings'] = geopandas_df['geometry'].x
        geopandas_df['northings'] = geopandas_df['geometry'].y
        logger.info('BNG columns generated from lat lon')
        if target_crs == '27700':
            return geopandas_df
        elif target_crs == '4326':
            geopandas_df = geopandas_df.to_crs("epsg:4326")
            return geopandas_df
    # otherwise, if we only have eastings northings, create geom and generate lat/lon
    if {'eastings', 'northings'}.issubset(pandas_df.columns):
        geopandas_df = geopandas.GeoDataFrame(pandas_df, crs="epsg:27700",
                                              geometry=geopandas.points_from_xy(pandas_df.eastings,
                                                                                pandas_df.northings))
        geopandas_df = geopandas_df.to_crs("epsg:4326")
        geopandas_df['longitude'] = geopandas_df['geometry'].x
        geopandas_df['latitude'] = geopandas_df['geometry'].y
        logger.info('lat lon columns generated from BNG')
        if target_crs == '4326':
            return geopandas_df
        elif target_crs == '27700':
            geopandas_df = geopandas_df.to_crs("epsg:27700")
            return geopandas_df


'''Same method as above, but with more variables for column names and coordinate reference system, so it doesn't 
assume anything on the input table '''


def create_geom_and_extra_coords(pandas_df, source_crs, target_crs, x_column, y_column, logger):
    logger.info(f'starting coords transformation from {source_crs} to {target_crs}')
    # Check target CRS is supported
    if not (target_crs in ['epsg:4326', 'epsg:27700']):
        logger.info(f'Target CRS: {target_crs} not supported')
        return f'Target CRS: {target_crs} is not supported for spatial enrichment'
    # Create geom column from coordinates
    geopandas_df = geopandas.GeoDataFrame(pandas_df, crs=source_crs,
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


'''Replaces nan values with '' in a pandas dataframe, so it can be converted to spark datafrane later even for non 
'string' columns '''


def deal_with_nan_columns(df, boundary_tables_dict):
    columns_with_potential_nan_values = []
    for boundary_table in boundary_tables_dict:
        for column in boundary_table["columns_to_append"]:
            columns_with_potential_nan_values.append(column["column_alias"])
    for column_name in columns_with_potential_nan_values:
        if column_name in df.columns:
            df[column_name] = df[column_name].fillna('')
    return df


'''Converts all coordinate columns to double, to prepare for writing'''


def convert_coordinate_columns_to_double(spark_point_df, x_column, y_column):
    spark_point_df = spark_point_df.withColumn(x_column, spark_point_df[x_column].cast(DoubleType()))
    spark_point_df = spark_point_df.withColumn(y_column, spark_point_df[y_column].cast(DoubleType()))
    if {'longitude', 'latitude'}.issubset(spark_point_df.columns):
        spark_point_df = spark_point_df.withColumn("longitude", spark_point_df.longitude.cast(DoubleType()))
        spark_point_df = spark_point_df.withColumn("latitude", spark_point_df.latitude.cast(DoubleType()))
    if {'eastings', 'northings'}.issubset(spark_point_df.columns):
        spark_point_df = spark_point_df.withColumn("eastings", spark_point_df.eastings.cast(DoubleType()))
        spark_point_df = spark_point_df.withColumn("northings", spark_point_df.northings.cast(DoubleType()))
    return spark_point_df


if __name__ == "__main__":

    args = getResolvedOptions(sys.argv,
                              ['TempDir', 'JOB_NAME', 'tables_to_enrich_dict_path', 'geography_tables_dict_path', 'target_location'])

    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger = glueContext.get_logger()

    # dictionary of tables to enrich
    enrich_tables_dict = spark.read.option("multiline", "true").json(args["tables_to_enrich_dict_path"]).rdd.collect()[0]
    logger.info(f'enrich text: {enrich_tables_dict}')
    # dictionary of geography tables used for enrichment
    geography_tables_dict = spark.read.option("multiline", "true").json(args["geography_tables_dict_path"]).rdd.collect()[0]
    logger.info(f'geography_tables = {geography_tables_dict}')
    # dictionary where we will put the geography dataframes
    geography_df_dict = {}

    # Step 1: load all boundary tables, prepare them and keep the resulting dataframes in the dict for later

    for geography_table in geography_tables_dict:
        # load the table from S3
        logger.info(f'geography record: {geography_table}')
        logger.info(f'loading geography: {geography_table["table_name"]}')
        geography_data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space=geography_table["database_name"],
            table_name=geography_table["table_name"],
            push_down_predicate = create_pushdown_predicate_for_max_date_partition_value(geography_table["database_name"], geography_table["table_name"], 'import_date')
        )
        geography_df = geography_data_source.toDF()

        # Only keep the columns used for enrichment + the geometry
        columns_to_keep_list = []
        for column_to_keep in geography_table["columns_to_append"]:
            columns_to_keep_list.append(column_to_keep["column_name"])
        logger.info(f'list of columns to keep in addition to geom: {columns_to_keep_list}')
        geography_df = geography_df.select('geom', *columns_to_keep_list)
        # rename the enrichment columns as defined in the dict
        for column_to_append in geography_table["columns_to_append"]:
            geography_df = geography_df.withColumnRenamed(column_to_append["column_name"],
                                                          column_to_append["column_alias"])
        # Convert to a geo dataframe, assuming the geometry is encoded in WKB (it is the case in postgis), discarding null geometries
        geography_df = geography_df.toPandas()
        geography_df = geography_df[geography_df.geom.notnull()]
        boundary_geometry = geography_df['geom'].apply(shapely.wkb.loads, args=(True,))
        geography_df = geography_df.drop(columns=['geom'])
        geography_geo_df = geopandas.GeoDataFrame(geography_df, crs="epsg:27700", geometry=boundary_geometry)
        logger.info(f'boundary frame: {geography_geo_df.head()}')
        # store the geo df in a dict for later
        geography_df_dict[geography_table["geography_title"]] = geography_geo_df

    # Step 2: in a loop, load and enrich the tables to enrich

    for enrich_table in enrich_tables_dict:
        table_name = enrich_table["table_name"]
        database_name = enrich_table["database_name"]
        if not table_exists_in_catalog(glueContext, table_name, database_name):
            logger.info(f"Couldn't find table {table_name} in database {database_name}, moving onto next table.")
            continue
        # Load the table
        logger.info(f"Now enriching {table_name} in database {database_name}")
        table_to_enrich_source = glueContext.create_dynamic_frame.from_catalog(
            name_space=database_name,
            table_name=table_name,
            push_down_predicate = create_pushdown_predicate_for_max_date_partition_value(enrich_table["database_name"], enrich_table["table_name"], enrich_table["date_partition_name"]),
            transformation_ctx = f"datasource_{table_name}"
        )
        table_to_enrich_df = table_to_enrich_source.toDF()
        if table_to_enrich_df.rdd.isEmpty():
            logger.info(f"No data found for {table_name}, moving onto next table to enrich.")
            continue

        # Prepare the spatial dataframe
        geom_format = enrich_table["geom_format"]
        source_crs = enrich_table["source_crs"]
        # Scenario 1: there is a geom column
        if "geom_column" in enrich_table:
            geom_column_name = enrich_table["geom_column"]
            logger.info(f"geom column name:{geom_column_name}")
            # if the geom column is called geometry, rename it to avoid a clash with Geopandas later
            if enrich_table["geom_column"] == "geometry":
                table_to_enrich_df = table_to_enrich_df.withColumnRenamed("geometry", "geom")
                geom_column_name = "geom"
            # create subdataframe with only the geom column, then convert it to pandas
            point_df = table_to_enrich_df.select(geom_column_name).dropna().distinct()
            point_df = point_df.toPandas()
            # fill empty geom values so the conversion to spark (string) works later
            # point_df[geom_column_name] = point_df[geom_column_name].fillna('')
            if geom_format == "wkt":
                enrich_geo_df = geopandas.GeoDataFrame(point_df, crs=source_crs,
                                                       geometry=point_df[geom_column_name].apply(wkt_loads))
            elif geom_format == "wkb":
                enrich_geo_df = geopandas.GeoDataFrame(point_df, crs=source_crs,
                                                       geometry=point_df[geom_column_name].apply(shapely.wkb.loads,
                                                                                                 args=(True,)))
            else:
                logger.info(
                    f"Couldn't decode geometry column {geom_column_name} for {table_name} in database {database_name}, moving onto next table.")
                continue
            if source_crs != '27700':
                enrich_geo_df = enrich_geo_df.to_crs("epsg:27700")
        # Scenario 2: there is no geom column but 2 coords columns
        elif geom_format == "coords":
            x_column = enrich_table["x_column"]
            y_column = enrich_table["y_column"]
            # create subdataframe with only the geom columns, then convert it to pandas
            point_df = table_to_enrich_df.select(x_column, y_column).dropna().distinct()
            point_df = point_df.toPandas()
            # point_df = point_df.astype({x_column:'float64', y_column:'float64'})
            enrich_geo_df = create_geom_and_extra_coords(point_df, source_crs, 'epsg:27700', x_column, y_column, logger)
        else:
            logger.info(f"Cannot handle geom format: {geom_format}")
            continue

        # Enrich with every relevant table from the boundary tables dictionary
        for geography_table_key in geography_df_dict:
            if geography_table_key in enrich_table["enrich_with"]:
                geography_df = geography_df_dict[geography_table_key]
                logger.info(f"boundary dataset column types:\n{geography_df.dtypes}")
                logger.info(f"point dataset column types:\n{enrich_geo_df.dtypes}")
                enrich_geo_df = geopandas.sjoin(enrich_geo_df, geography_df, how='left', predicate='intersects',
                                                lsuffix='left', rsuffix='right')
                enrich_geo_df = enrich_geo_df.drop(columns=['index_right'])

        # back from geopandas to pandas
        enrich_pd_df = pandas.DataFrame(enrich_geo_df)
        enrich_pd_df = enrich_pd_df.drop(columns=['geometry'])
        logger.info(f"column types in the joint dataframe:\n{enrich_pd_df.dtypes}")

        # deal with nan for non geom columns
        enrich_pd_df = deal_with_nan_columns(enrich_pd_df, geography_tables_dict)

        # back from pandas to spark
        enrich_spark_df = spark.createDataFrame(enrich_pd_df)

        # Convert coordinates columns to double (Pandas make them decimal when calculating them)
        if geom_format == "coords":
            enrich_spark_df = convert_coordinate_columns_to_double(enrich_spark_df, x_column, y_column)
        
        # joins back the dataframe with only enriched geom to the initial dataframe with all the columns
        # Scenario 1: there was a geom column: join on this column
        if "geom_column" in enrich_table:
            table_to_enrich_df = table_to_enrich_df.join(enrich_spark_df, geom_column_name, "left")
            # if the geometry column has been renamed earlier to avoid a clash, rename it back to 'geometry'
            if enrich_table["geom_column"] == "geometry":
                table_to_enrich_df = table_to_enrich_df.withColumnRenamed("geom", "geometry")
        # Scenario 2: there were 2 coordinate columns: join on these 2 columns
        elif geom_format == "coords":
            table_to_enrich_df = table_to_enrich_df.join(enrich_spark_df, [enrich_table["x_column"],enrich_table["y_column"]], "left")
            
        # Convert data frame to dynamic frame
        dynamic_frame = DynamicFrame.fromDF(table_to_enrich_df, glueContext, "target_data_to_write")

        # Write the data to S3
        logger.info(f'Now writing  {table_name} enriched records inside {args["target_location"] + table_name}')
        parquet_data = glueContext.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            format="parquet",
            connection_options={"path": args["target_location"] + table_name, "partitionKeys": enrich_table["partition_keys"]},
            transformation_ctx=f'target_data_to_write_{table_name}')

    job.commit()
