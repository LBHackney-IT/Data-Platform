import sys
import boto3
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.job import Job
from pyspark.sql.functions import *
import pyspark.sql.functions as F
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS,parse_json_into_dataframe, table_exists_in_catalog

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.
def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    spark= glueContext.spark_session
    logger = glueContext.get_logger()
    job = Job(glueContext)


    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source database is {source_catalog_database}')


    # Load data from glue catalog
    df = glueContext.create_data_frame.from_catalog( 
        database = source_catalog_database, 
        table_name = "mtfh_tenureinformation", 
        transformation_ctx = "mtfh_tenureinformation_source")
    df.createOrReplaceTempView("mtfh_tenureinformation")

    df2 = glueContext.create_data_frame.from_catalog( 
        database = source_catalog_database, 
        table_name = "mtfh_persons", 
        transformation_ctx = "mtfh_persons_source")
    df2.createOrReplaceTempView("mtfh_persons")

    df3 = glueContext.create_data_frame.from_catalog( 
        database = source_catalog_database, 
        table_name = "mtfh_contactdetails", 
        transformation_ctx = "mtfh_contactdetails_source")
    df3.createOrReplaceTempView("mtfh_contactdetails")
    
    df4 = glueContext.create_data_frame.from_catalog( 
        database = source_catalog_database, 
        table_name = "mtfh_assets", 
        transformation_ctx = "mtfh_assets_source")
    df4.createOrReplaceTempView("mtfh_assets")

    # tenancy 
    ten = spark.sql(f'''
    SELECT *
    FROM mtfh_tenureinformation a
         where  import_date=(select max(import_date) from mtfh_tenureinformation) 
       ''')
    
    ten= ten.select("*",element_at("legacyreferences",1).value.alias("uh_ten_ref")
                    ,element_at("legacyreferences",2).value.alias("saffron_pay_ref"))
    
    ten = ten.withColumn("endoftenuredate", ten.endOfTenureDate.string.cast("string"))
    
    ten2 = ten.withColumn("members", F.explode_outer("householdmembers"))\
                  .withColumn("notices", F.explode_outer("notices"))\
                   .withColumnRenamed("id","tenancy_id")\
                        .selectExpr(
                      "tenancy_id",
                        "paymentreference",
                        "uh_ten_ref",
                        "saffron_pay_ref",
                        "startOfTenureDate",
                        "endoftenuredate",
                         "evictiondate",
                         "potentialenddate",
                         "ismutualexchange",
                         "subletenddate",
                         "tenuretype.code as tenure_code",
                        "tenuretype.description",  
                        "members.fullname",
                        "members.isresponsible",
                        "members.dateofbirth",
                        "members.persontenuretype",
                        "members.id as person_id",
                        "members.type as member_type",
                        "notices.expirydate as  notice_expiry_date",
                        "notices.serveddate as notice_served_date",
                        "notices.effectivedate as notice_effective_date",
                        "tenuredasset.uprn",
                        "tenuredasset.propertyReference as property_reference",
                        "tenuredasset.fullAddress as full_address",
                        "tenuredasset.id as  asset_id",
                        "tenuredasset.type as asset_type",
                        "charges.currentbalance",
                         "charges.billingfrequency",
                         "charges.combinedrentcharges",
                         "charges.tenancyinsurancecharge",
                         "charges.servicecharge",
                         "charges.othercharges",
                         "charges.combinedservicecharges",  
                         "terminated.isterminated",   
                        "terminated.reasonfortermination",  
                        "import_year",
                        "import_month",
                        "import_day",
                        "import_date"
                       )
    
    #get the first elements from split cells
    ten3 = ten2.select("*","currentbalance.double").withColumnRenamed("double","balance").drop("currentbalance")
    ten3 = ten3.select("*","combinedrentcharges.double").withColumnRenamed("double","combined_rent_charges").drop("combinedrentcharges")
    ten3 = ten3.select("*","tenancyinsurancecharge.double").withColumnRenamed("double","tenancy_insurance_charge").drop("tenancyinsurancecharge")
    ten3 = ten3.select("*","servicecharge.double").withColumnRenamed("double","service_charge").drop("servicecharge")
    ten3 = ten3.select("*","othercharges.double").withColumnRenamed("double","other_charges").drop("othercharges")
    ten3 = ten3.select("*","combinedservicecharges.double").withColumnRenamed("double","comb_service_charges").drop("combinedservicecharges")\
                 .selectExpr("tenancy_id",
                        "paymentreference",
                        "uh_ten_ref",
                        "saffron_pay_ref",
                        "startOfTenureDate",
                        "endoftenuredate",
                        "evictiondate",
                         "potentialenddate",
                         "ismutualexchange",
                         "subletenddate",
                         "tenure_code",
                        "description", 
                         "person_id",
                        "fullname as member_fullname",
                        "isresponsible as member_is_responsible",
                        "dateofbirth",
                        "persontenuretype",
                        "member_type",
                        "notice_expiry_date",
                        "notice_served_date",
                        "notice_effective_date",
                        "uprn",
                        "property_reference",
                        "full_address",
                        "asset_id",
                        "asset_type",
                        "balance",
                         "billingfrequency",
                         "combined_rent_charges",
                         "tenancy_insurance_charge",
                         "service_charge",
                         "other_charges",
                         "comb_service_charges",  
                          "isterminated",   
                        "reasonfortermination",  
                        "import_year",
                        "import_month",
                        "import_day",
                        "import_date")
    
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(ten3.repartition(1), glueContext, "target_data_to_write")
    
    # wipe out the target folder in the trusted zone
    clear_target_folder(s3_bucket_target+'/tenure_reshape')
    
    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target+'/tenure_reshape', "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")
        
    #Persons table
    df2 = spark.sql(f'''
    SELECT *
    FROM mtfh_persons a
         where  import_date=(select max(import_date) from mtfh_persons) 
       ''')
    
    per = df2.withColumn("combined", arrays_zip("tenures", "persontypes")) \
        .withColumn("combined_exploded", F.explode_outer(col("combined")))\
        .withColumn("tenure", col("combined_exploded.tenures"))\
        .withColumn("person_type", col("combined_exploded.persontypes")).drop("combined", "combined_exploded") \
        .withColumnRenamed("id","person_id")\
        .withColumn("persontypes2",concat_ws(",",col("persontypes")))   
    
    per =  per.withColumn("new_person_type", when(per.person_type.isNull(), per.persontypes2)
                                 .otherwise(per.person_type))
    
    per =  per.select("person_id",
                    "preferredTitle",
                    "firstName",
                    "middleName",
                    "surname",
                    "dateOfBirth",
                    "placeOfBirth",
                    "isOrganisation",
                    "reason",
                    "tenure.id", ##needs to be renamed
                    "tenure.uprn",
                    "tenure.propertyReference",
                    "tenure.paymentReference",
                    "tenure.startDate",
                    "tenure.endDate",   
                    "tenure.assetId",   
                    "tenure.type",   
                    "tenure.assetFullAddress",
            ##      "person_type",
                    "new_person_type",
                    "import_year",
                    "import_month",
                    "import_day",
                    "import_date")\
            .withColumnRenamed("id","tenancy_id")\
            .withColumnRenamed("new_person_type","person_type")

    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(per.repartition(1), glueContext, "target_data_to_write")
    
    # wipe out the target folder in the trusted zone
    clear_target_folder(s3_bucket_target+'/person_reshape')
    
    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target+'/person_reshape', "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")
    
    #contact details
    cont = spark.sql(f'''
    SELECT *
    FROM mtfh_contactdetails a
         where  import_date=(select max(import_date) from mtfh_contactdetails) 
       ''')
    
    cont2 = cont.select("id",
                  "targetid",
                  "createdby.createdAt",
                  "contactinformation.contacttype",
                  "contactinformation.subtype",
                  "contactinformation.value",
                  "contactinformation",
                  "lastmodified",
                  "targettype",      
                   "isactive",
                   "import_datetime",
                   "import_timestamp",
                    "import_year",
                   "import_month",
                    "import_day",
                   "import_date"
                       )
    
    cont2 = cont2.withColumn('person_id', when(cont2.targettype=="person",cont2.targetid)
                                                .otherwise("")) \
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(cont2.repartition(1), glueContext, "target_data_to_write")
    
    # wipe out the target folder in the trusted zone
    clear_target_folder(s3_bucket_target+'/contacts_reshape')
    
    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target+'/contacts_reshape', "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")
        
    #asset output
    ass = spark.sql(f'''
    SELECT *
    FROM mtfh_assets a
         where  import_date=(select max(import_date) from mtfh_assets)  
       ''')
    
    ass= ass.withColumnRenamed("id","asset_id")
    
    ass=ass.select("*",
               "assetAddress.*",
               "tenure.*",
               "assetManagement.*",
                "assetLocation.*",
               "assetCharacteristics.*"
                         )
    
    
    ass2 = ass.withColumn("parentAssets", F.explode_outer("assetLocation.parentAssets"))\
        .withColumn("parentAssets_name", col("parentAssets.name"))\
        .withColumn("parentAssets_id", col("parentAssets.id"))\
        .withColumn("parentAssets_type", col("parentAssets.type"))
    
    estate = ass2.filter(ass2.parentAssets_type == "Estate")\
                 .withColumnRenamed("parentAssets_name","estate_name")\
                 .withColumnRenamed("parentAssets_id","estate_id")
    
    ass3 = ass.join(estate,ass.asset_id ==  estate.asset_id,"left").select(ass["*"],estate["estate_name"],estate["estate_id"])\
              .withColumnRenamed("id","tenancy_id")

    output= ass3.select("asset_id",
                        "assetId", 
                        "assetType",
                       "parentAssetIds",
                        "uprn",
                        "postPreamble",
                        "addressLine1",
                        "addressLine2",
                        "addressLine3",
                        "addressLine4",
                        "postCode",
                        "tenancy_id",
                        "startOfTenureDate",
                        "EndOfTenureDate",
                        "paymentReference",
                        "type",
                        "owner",
                        "agent",
                        "isNoRepairsMaintenance",
                        "propertyOccupiedStatus",
                        "isCouncilProperty",
                        "isTMOManaged",
                        "managingOrganisation",
                        "managingOrganisationId",
                        "areaOfficeName",
                        "totalBlockFloors",
                        "floorNo",
                        "numberOfLifts",
                        "numberOfLivingRooms",
                        "yearConstructed",
                        "numberOfBedrooms",
                        "windowType",
                        "estate_name",
                        "estate_id",                                 
                        "import_year",
                        "import_month",
                        "import_day",
                        "import_date")
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(output.repartition(1), glueContext, "target_data_to_write")
    
    # wipe out the target folder in the trusted zone
    clear_target_folder(s3_bucket_target+'/assets_reshape')
    
    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target+'/assets_reshape', "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")

    job.commit()

   
