"""
Script for preparing Noiseworks complaints dataset to refined, and associated location based dataset for geospatial
enrichment.
"""

import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
import pyspark.sql.functions as f
from scripts.helpers.helpers import get_glue_env_var, clear_target_folder
from scripts.helpers.coordinates import convert_bng_to_latlon


if __name__ == "__main__":
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table1 = get_glue_env_var('source_catalog_table1', '')
    source_catalog_table2 = get_glue_env_var('source_catalog_table2', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    s3_bucket_target2 = get_glue_env_var('s3_bucket_target2', '')

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger.info(f'The job is starting. The source tables are {source_catalog_database}.{source_catalog_table1},'
                f' {source_catalog_database}.{source_catalog_table2}')

    # Load data from glue catalog
    data_source1 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table1,
        push_down_predicate="import_date=date_format(current_date, 'yyyyMMdd')"
    )
    data_source2 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table2,
        push_down_predicate="import_date=date_format(current_date, 'yyyyMMdd')"
    )

    # convert dynamic frame to data frame
    logger.info(f'Cases table schema before conversion.{data_source1.printSchema()}')
    logger.info(f'Complaints table schema before conversion.{data_source2.printSchema()}')
    
    df1 = data_source1.toDF()
    df2 = data_source2.toDF()

    # filter out the blanks
    df1 = df1.filter(df1.id != "")
    df2 = df2.filter(df2.case_id != "")

    # remove the partition dates from complaints
    df2 = df2.drop("import_datetime", "import_timestamp", "import_year", "import_year", "import_month", "import_day",
                   "import_date")
    df2 = df2.withColumnRenamed("id", "complaint_id")

    # Create date and time columns
    df1 = df1.withColumn('case_created_date', f.date_format("created", "MM/dd/yyyy"))
    df1 = df1.withColumn('case_created_time', f.date_format("created", "HH:mm"))
    df2 = df2.withColumn('complaint_created_date', f.date_format("created", "MM/dd/yyyy"))
    df2 = df2.withColumn('complaint_created_time', f.date_format("created", "HH:mm"))

    # rename the created fields
    df1 = df1.withColumnRenamed("created", "case_created_datetime")
    df2 = df2.withColumnRenamed("created", "complaint_created_datetime")

    # join the tables
    output = df1.join(df2, df1.id == df2.case_id, "left")
    output = output.drop("id")

    # convert to int so suitable for geo df
    logger.info('Coverting coordinates...')
    output = output.withColumn('easting', f.col('easting').cast('double'))
    output = output.withColumn('northing', f.col('northing').cast('double'))

    # convert the coordinates
    geo = output.filter(f.length(f.col('easting')) > 0)
    geo = convert_bng_to_latlon(geo, 'easting', 'northing')

    # create output to gecode
    geo = geo.withColumnRenamed("lat", "latitude")
    geo = geo.withColumnRenamed("lon", "longitude")
    geo = geo.select("complaint_id", "latitude", "longitude", "import_year", "import_month", "import_day",
                     "import_date")
    geo = geo.filter(geo.latitude.isNotNull())
    geo = geo.withColumnRenamed("complaint_id", "id")
    geo = geo.withColumn("Source", f.lit('noiseworks'))

    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(output.repartition(1), glueContext, "target_data_to_write")
    clear_target_folder(s3_bucket_target)

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target,
                            "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")

    # dataframe for geo output
    dynamic_frame_geo = DynamicFrame.fromDF(geo.repartition(1), glueContext, "target_data_to_write")
    clear_target_folder(s3_bucket_target2)

    # Write the data to S3 for geo
    parquet_data_geo = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame_geo,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target2,
                            "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")

    job.commit()
