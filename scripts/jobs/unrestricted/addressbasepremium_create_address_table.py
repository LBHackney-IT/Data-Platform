"""
Script to turn pre-processed OS AddressBasePremium CSV files into one national address table and save it
into S3 refined zone and glue catalogue.
The table structure is compatible with the Addresses API.
"""

import sys
import csv
import s3fs
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, split

from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS

# Queries
join_blpu_query = """
SELECT
b.uprn, 
b.parent_uprn, 
b.x_coordinate, 
b.y_coordinate, 
b.latitude, 
b.longitude, 
case when b.start_date is null then 0
else cast(regexp_replace(b.start_date, '-', '') as integer) end as start_date, 
case when b.end_date is null then 0
else cast(regexp_replace(b.end_date, '-', '') as integer) end as end_date, 
case when b.last_update_date is null then 0
else cast(regexp_replace(b.last_update_date, '-', '') as integer) end as last_update_date, 
b.postcode_locator,
cls.classification_code,
cls.usage_description,
cls.planning_use_class,
latestorg.organisation,
xref.ward_name as ward
from BLPU b
left join CLASSIF cls on cls.uprn = b.uprn
left join ORG latestorg on latestorg.uprn = b.uprn
left join XREF xref on xref.uprn=b.uprn
"""

join_lpi_query = """
SELECT
l.lpi_key,
(case 
when l.logical_status = '1' then 'Approved Preferred' 
when l.logical_status = '3' then 'Alternative' 
when l.logical_status = '6' then 'Provisional'
when l.logical_status = '8' then 'Historic' 
end) as lpi_logical_status,
case when l.start_date is null then 0
else cast(regexp_replace(l.start_date, '-', '') as integer) end as lpi_start_date, 
case when l.end_date is null then 0
else cast(regexp_replace(l.end_date, '-', '') as integer) end as lpi_end_date, 
case when l.last_update_date is null then 0
else cast(regexp_replace(l.last_update_date, '-', '') as integer) end as lpi_last_update_date, 
l.usrn as usrn,
l.uprn as uprn,
b.parent_uprn as parent_uprn,
b.start_date as blpu_start_date, 
b.end_date as blpu_end_date, 
b.last_update_date as blpu_last_update_date,
b.classification_code as blpu_class, 
b.usage_description,
b.planning_use_class,
false as property_shell,
cast(b.x_coordinate as real) as easting, 
cast(b.y_coordinate as real) northing,
l.sao_text as sao_text,
cast(l.sao_start_number as integer),
l.sao_start_suffix,
cast(l.sao_end_number as integer),
l.sao_end_suffix,
cast(l.sao_start_number as integer) as unit_number,
l.pao_text as pao_text,
cast(l.pao_start_number as integer),
l.pao_start_suffix,
cast(l.pao_end_number as integer),
l.pao_end_suffix,
s.street_description, 
s.locality_name as locality,
s.town_name as town, 
b.postcode_locator as postcode,
replace (b.postcode_locator, ' ', '') as postcode_nospace,
b.ward,
false as neverexport,
cast(b.longitude as real), 
cast(b.latitude as real), 
'National' as gazetteer,
b.organisation
FROM 
LPI l 
left join BLPU b on b.uprn=l.uprn
left join STREETDESC s on s.usrn=l.usrn;
"""

create_building_number_query = """
select a.*,  
(case
when pao_start_number is not null then pao_start_number else '' end
--case statement for different combinations of the pao start suffixes
||case
when pao_start_suffix is not null then pao_start_suffix else '' end
--Add a '-' between the start and end of the primary address (e.g. only when pao start and pao end)
||case
when pao_start_number is not null and pao_end_number is not null then '-' else '' end
--case statement for different combinations of the pao end numbers and pao end suffixes
||case
when pao_end_number is not null then pao_end_number else '' end
--pao end suffix
||case 
when pao_end_suffix is not null then pao_end_suffix else '' end) as building_number
FROM ADDRESS_TABLE a
"""

create_short_address_line_query = """
select a.*, 
--Concatenate a single GEOGRAPHIC address line label
--This code takes into account all possible combinations os pao/sao numbers and suffixes
(case
when sao_text is not null then sao_text||', ' else '' end
--case statement for different combinations of the sao start numbers (e.g. if no sao start suffix)
||case
when unit_number is not null and sao_start_suffix is null and sao_end_number is null
then unit_number||''
when unit_number is null then '' else sao_start_number||'' end
--case statement for different combinations of the sao start suffixes (e.g. if no sao end number)
||case
when sao_start_suffix is not null and sao_end_number is null then sao_start_suffix||''
when sao_start_suffix is not null and sao_end_number is not null then sao_start_suffix else '' end
--Add a '-' between the start and end of the secondary address (e.g. only when sao start and sao end)
||case
when sao_end_suffix is not null and sao_end_number is not null then '-'
when unit_number is not null and sao_end_number is not null then '-' else '' end
--case statement for different combinations of the sao end numbers and sao end suffixes
||case
when sao_end_number is not null and sao_end_suffix = '' then sao_end_number||' '
when sao_end_number is null then '' else sao_end_number end
--pao end suffix
||case when sao_end_suffix is not null then sao_end_suffix||', ' else '' end
--potential comma between sao_num and pao text
||case 
when pao_text is null and sao_start_number is not null then ', '
when pao_text is not null and unit_number is not null then ' ' else '' end
--Primary Addressable Information-------------------------------------------------------------------------------------
||case when pao_text is not null then pao_text||', ' else '' end
--Building number
||case when building_number != '' then building_number||' ' else '' end
--Street Information----------------------------------------------------------------------------------------------
||case when street_description is not null then street_description else '' end
--Locality---------------------------------------------------------------------------------------------------------
||case when locality is not null then ', '||locality else '' end) as short_address_line
from ADDRESS_TABLE a
"""

create_full_address_line_query = """
select a.*,
(short_address_line 
||case when town is not null then ', '||town else '' end
||case when postcode is not null and postcode != '' then ', '||postcode else '' end
) as full_address_line
from ADDRESS_TABLE a
"""

if __name__ == "__main__":
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME', 'processed_source_data_path', 'target_path', 'ward_lookup_path',
                                         'blpu_class_lookup_path'])

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    spark = glueContext.spark_session
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger.info(f'The job is starting.')

    # Prepare organisation table by only keeping the last org for a given UPRN
    logger.info(f'Preparing Organisation records')

    df_31 = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['processed_source_data_path'] + "ID31_Org_Records.csv")

    df_31 = df_31.filter('END_DATE is null')

    df_31 = df_31.orderBy('LAST_UPDATE_DATE', ascending=False) \
        .coalesce(1) \
        .dropDuplicates(subset=['UPRN'])

    df_31.createOrReplaceTempView('ORG')

    # Prepare xref table by only keeping the wards, and get corresponding ward names from Geolive
    logger.info(f'Preparing xref records for wards')

    df_23 = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['processed_source_data_path'] + "ID23_XREF_Records.csv")

    df_23 = df_23.filter("SOURCE = '7666OW' and END_DATE is null")

    ward_df = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['ward_lookup_path']) \
        .select(["WD23CD", "WD23NM"]) \
        .withColumnRenamed("WD23CD", "ward_code") \
        .withColumnRenamed("WD23NM", "ward_name")

    df_23 = df_23.join(ward_df, df_23.CROSS_REFERENCE == ward_df.ward_code, "left")
    df_23.createOrReplaceTempView('XREF')

    # Prepare classification table by only keeping abp classification scheme
    logger.info(f'Preparing classif records')

    df_32 = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['processed_source_data_path'] + "ID32_Class_Records.csv")

    df_32 = df_32.filter("CLASS_SCHEME = 'AddressBase Premium Classification Scheme'")

    df_blpu_class_lookup = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['blpu_class_lookup_path']) \
        .select(["blpu_class", "usage_description", "planning_use_class"])

    df_32 = df_32.join(df_blpu_class_lookup, df_32.CLASSIFICATION_CODE == df_blpu_class_lookup.blpu_class, "left")

    df_32.createOrReplaceTempView('CLASSIF')

    # Prepare BLPU records and join them with wards, orgs and classification
    logger.info(f'Preparing BLPU records and join them with wards, orgs and classification')

    df_21 = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['processed_source_data_path'] + "ID21_BLPU_Records.csv")

    df_21.createOrReplaceTempView('BLPU')
    result_df = spark.sql(join_blpu_query)
    result_df.createOrReplaceTempView('BLPU')

    # Prepare streetdesc and LPI to only keep english language
    logger.info(f'Preparing streetdesc and LPI records keeping only english language')

    df_15 = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['processed_source_data_path'] + "ID15_StreetDesc_Records.csv")
    df_24 = spark.read \
        .format("csv") \
        .option("header", "true") \
        .load(args['processed_source_data_path'] + "ID24_LPI_Records.csv")

    df_15 = df_15.filter("LANGUAGE = 'ENG'")
    df_15.createOrReplaceTempView('STREETDESC')
    df_24 = df_24.filter("LANGUAGE = 'ENG'")
    df_24.createOrReplaceTempView('LPI')

    # Join LPI, BLPU and street into one address table
    logger.info(f'Joining LPI, BLPU and streets into one address table')
    result_df = spark.sql(join_lpi_query)
    result_df.createOrReplaceTempView('ADDRESS_TABLE')

    # Create building numbers and address lines

    logger.info(f'Creating building numbers')
    result_df = spark.sql(create_building_number_query)
    result_df.createOrReplaceTempView('ADDRESS_TABLE')

    logger.info(f'Creating short address line')
    result_df = spark.sql(create_short_address_line_query)

    logger.info(f'Creating lines 1 2 3 4')
    result_df = result_df.withColumn("lines", split(col("short_address_line"), ", ")) \
        .withColumn("line1", col("lines")[0]) \
        .withColumn("line2", col("lines")[1]) \
        .withColumn("line3", col("lines")[2]) \
        .withColumn("line4", col("lines")[3]) \
        .drop("lines")
    result_df.createOrReplaceTempView('ADDRESS_TABLE')

    logger.info(f'Creating full address line')
    result_df = spark.sql(create_full_address_line_query)

    # Write to s3
    result_df = add_import_time_columns(result_df)
    address_dyf = DynamicFrame.fromDF(result_df, glueContext, "national_address_dyf")

    s3output = glueContext.getSink(
        path=args['target_path'],
        connection_type="s3",
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=PARTITION_KEYS,
        compression="snappy",
        enableUpdateCatalog=True,
        transformation_ctx="s3output",
    )
    s3output.setCatalogInfo(
        catalogDatabase="unrestricted-refined-zone", catalogTableName="national_address"
    )
    s3output.setFormat("glueparquet")
    s3output.writeFrame(address_dyf)

    job.commit()
