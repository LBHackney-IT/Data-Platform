import sys

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions
from awsglue.job import Job
from pyspark.context import SparkContext
import pyspark.sql.functions as f
from pyspark.sql.window import Window

from scripts.helpers.helpers import get_latest_partitions_optimized, PARTITION_KEYS,\
    clear_target_folder


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv,
                              ['JOB_NAME', 'source_catalog_database2', 's3_target_refined', 's3_target_trusted',
                               'source_catalog_database'])
    source_catalog_database = args["source_catalog_database"]
    source_catalog_database2 = args["source_catalog_database2"]
    s3_target_refined = args["s3_target_refined"]
    s3_target_trusted = args["s3_target_trusted"]

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    spark = glueContext.spark_session
    logger = glueContext.get_logger()
    job = Job(glueContext)
    spark.conf.set("spark.sql.broadcastTimeout", 7200)

    logger.info(f'source_catalog_database is {source_catalog_database}')
    logger.info(f's3_refined_target is {s3_target_refined}.')
    logger.info(f'trusted target path is {s3_target_trusted}.')
    logger.info(f'The job is starting. The source table is {source_catalog_database},'
                f' the refined zone target it {s3_target_refined} and trusted zone is {s3_target_trusted}.')

    df = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database,
        table_name="mtfh_housingregister",
        transformation_ctx="mtfh_housingregister_ctx")

    df2 = get_latest_partitions_optimized(df)

    llpg = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database2,
        table_name="latest_llpg",
        # table_name = "Assets",
        transformation_ctx="llpg_latest_ctx"
    )

    # main applicant details
    df3 = df2.withColumnRenamed("id", "application_reference_overall")
    df4 = df3.select("application_reference_overall",
                     "createdAt",
                     "submittedat",
                     "status",
                     "reference",
                     "activerecord",
                     "sensitivedata",
                     "lastissuedbiddingnumber",
                     "calculatedBedroomNeed",
                     "mainApplicant.medicalNeed.*",
                     "mainApplicant.address.*",
                     "mainApplicant.contactInformation.*",
                     "mainApplicant.requiresMedical",
                     "mainApplicant.person.*",
                     "assessment.*",
                     "mainApplicant.questions",
                     "import_year", "import_month", "import_day", "import_date"
                     ) \
        .withColumnRenamed("id", "application_ref") \
        .withColumnRenamed("addressType", "main_addressType") \
        .withColumnRenamed("postcode", "main_postcode") \
        .withColumnRenamed("addressLine1", "main_addressLine1") \
        .withColumnRenamed("addressLine2", "main_addressLine2") \
        .withColumnRenamed("addressLine3", "main_addressLine3") \
        .withColumn("full_address",
                    f.concat_ws(',', f.col('main_addressLine1'), f.col("main_addressLine2"), f.col("main_addressLine3"),
                                f.col("main_postcode"))) \
        .withColumn("date_of_birth", f.to_date(f.col("dateOfBirth"), "yyyy-MM-dd")) \
        .withColumn("date_submitted", f.to_date(f.col("submittedat"), "yyyy-MM-dd")) \
        .withColumn("effective_band_date", f.to_date(f.col("effectivedate"), "yyyy-MM-dd")) \
        .drop('dateOfBirth')

    # get the values from the questions for the main person
    df6 = df4.select(df4.application_reference_overall, f.explode_outer(df4.questions))
    df7 = df6.select("application_reference_overall",
                     "col.*")\
        .withColumnRenamed("id", "question")

    df8 = df7.select("application_reference_overall", "question", f.regexp_replace("answer", "[^0-9a-zA-Z_\-]+", "")
                     .alias('answer_clean'))

    pivot_df = df8.groupBy("application_reference_overall").pivot("question").agg(f.max("answer_clean")) \
                  .withColumnRenamed("application_reference_overall", "application_reference_overall1")

    # join back to the main df
    member_detail = df4.join(pivot_df,
                             df4.application_reference_overall == pivot_df.application_reference_overall1,
                             "left") \
        .drop("application_reference_overall1")

    # generate the llpg output with the most common ward
    llpg2 = llpg.select("postcode", "ward")

    # llpg_distinct = llpg_distinct.distinct()
    llpg_distinct_group = llpg2.groupBy("postcode", "ward").count() \
        .withColumnRenamed("count", "recs")

    llpg_distinct_max = llpg_distinct_group.groupBy("postcode").max() \
        .withColumnRenamed("max(recs)", "max1") \
        .withColumnRenamed("postcode", "postcode1")

    llpg_match = llpg_distinct_max.join(llpg_distinct_group,
                                        (llpg_distinct_max.postcode1 == llpg_distinct_group.postcode) & (
                                                llpg_distinct_max.max1 == llpg_distinct_group.recs), "left") \
        .drop("postcode1", "max1", "recs")

    # sift the dupes
    window_spec = Window.partitionBy("postcode").orderBy("monotonically_increasing_id")

    # Person details
    llpg_mono = llpg_match.withColumn("mono_id", f.monotonically_increasing_id()) \
        .withColumnRenamed("mono_id", "mon_id")

    llpg_distinct_min = llpg_mono.groupBy("postcode").min("mon_id") \
        .withColumnRenamed("min(mon_id)", "low") \
        .drop("mon_id") \
        .withColumnRenamed("postcode", "postcode1")

    llpg_match = llpg_mono.join(llpg_distinct_min, llpg_mono.mon_id == llpg_distinct_min.low, "right") \
        .drop("mon_id", "low", "postcode1")
    llpg_match = llpg_match.distinct()

    # join back
    member_detail_final = member_detail.join(llpg_match,
                                             member_detail.main_postcode == llpg_match.postcode,
                                             "left")

    # OTHER MEMBER DETAILS
    members_person = df3.select("application_reference_overall",
                                "otherMembers.person",
                                "otherMembers.medicalNeed",
                                "otherMembers.address",
                                "otherMembers.contactInformation"
                                )

    # explode values and create rows to person
    members_person_explode = members_person.select(members_person.application_reference_overall,
                                                   f.explode_outer(members_person.person))
    members_meds_explode = members_person.select(members_person.application_reference_overall,
                                                 f.explode_outer(members_person.medicalNeed))
    members_address_explode = members_person.select(members_person.application_reference_overall,
                                                    f.explode_outer(members_person.address))
    members_contact_explode = members_person.select(members_person.application_reference_overall,
                                                    f.explode_outer(members_person.contactInformation))

    window_spec = Window.partitionBy("application_reference_overall").orderBy("monotonically_increasing_id")

    # Person details
    member_person_mono = members_person_explode.withColumn("monotonically_increasing_id",
                                                           f.monotonically_increasing_id())
    member_person_id = member_person_mono.withColumn("app_person_id", f.row_number().over(window_spec))

    # split values into named columns for person
    member_person = member_person_id.select("application_reference_overall",
                                            "app_person_id",
                                            "col.*") \
        .withColumnRenamed("id", "question") \
        .selectExpr("*",
                    "cast (app_person_id as string) as member_string") \
        .withColumn("member_id", f.concat_ws('_', f.col('application_reference_overall'), f.col("member_string"))) \
        .drop("member_string", "app_person_id")

    # Medical Need
    member_person_mono = members_meds_explode.withColumn("monotonically_increasing_id", f.monotonically_increasing_id())
    member_person_id = member_person_mono.withColumn("app_person_id", f.row_number().over(window_spec))

    # split values into named columns for person
    member_med_need = member_person_id.select("application_reference_overall",
                                              "app_person_id",
                                              "col.*") \
        .withColumnRenamed("id", "question") \
        .selectExpr("*",
                    "cast (app_person_id as string) as member_string") \
        .withColumn("member_id1", f.concat_ws('_', f.col('application_reference_overall'), f.col("member_string"))) \
        .drop("member_string", "app_person_id", "application_reference_overall")

    member_person_final = member_person.join(member_med_need,
                                             member_person.member_id == member_med_need.member_id1,
                                             "left")

    # Address
    member_person_mono = members_address_explode.withColumn("monotonically_increasing_id",
                                                            f.monotonically_increasing_id())
    member_person_id = member_person_mono.withColumn("app_person_id", f.row_number().over(window_spec))
    member_address = member_person_id.select("application_reference_overall",
                                             "app_person_id",
                                             "col.*") \
        .withColumnRenamed("id", "question") \
        .selectExpr("*",
                    "cast (app_person_id as string) as member_string") \
        .withColumn("member_id2", f.concat_ws('_', f.col('application_reference_overall'), f.col("member_string"))) \
        .drop("member_string", "app_person_id", "application_reference_overall")

    member_person_final = member_person_final.join(member_address,
                                                   member_person_final.member_id == member_address.member_id2,
                                                   "left")

    # Member contacts
    member_person_mono = members_contact_explode.withColumn("monotonically_increasing_id",
                                                            f.monotonically_increasing_id())
    member_person_id = member_person_mono.withColumn("app_person_id", f.row_number().over(window_spec))
    member_contacts = member_person_id.select("application_reference_overall",
                                              "app_person_id",
                                              "col.*") \
        .withColumnRenamed("id", "question") \
        .selectExpr("*", "cast (app_person_id as string) as member_string") \
        .withColumn("member_id3", f.concat_ws('_', f.col('application_reference_overall'),
                                              f.col("member_string"))) \
        .drop("member_string", "app_person_id", "application_reference_overall")

    member_person_final = member_person_final.join(member_contacts,
                                                   member_person_final.member_id == member_contacts.member_id3,
                                                   "left")\
        .drop("member_id3", "member_id2", "member_id1","questions")

    # get the partition fields
    partitions = df3.selectExpr("application_reference_overall as application_reference_overall1",
                                "import_year",
                                "import_month",
                                "import_day",
                                "import_date"
                                )

    member_person_final = member_person_final.join(partitions,
                                                   member_person_final.application_reference_overall == partitions.application_reference_overall1,
                                                   "left")
    other_member_remove_nulls = member_person_final.filter(member_person_final.firstName.isNotNull())

    # Join to create R01b
    member_summary = other_member_remove_nulls.groupBy("application_reference_overall").count() \
        .withColumnRenamed("count", "No_people_in_household") \
        .withColumnRenamed("application_reference_overall", "application_reference_overall1")

    member_detail_final1 = member_detail_final.join(member_summary,
                                                    member_detail.application_reference_overall == member_summary.application_reference_overall1,
                                                    "left") \
        .drop("application_reference_overall1") \
        .withColumnRenamed("date_submitted", "Date_submitted") \
        .withColumnRenamed("ethnicity-questions/ethnicity-main-category", "Ethnicity") \
        .withColumnRenamed("current-accommodation/living-situation", "Tenure") \
        .withColumnRenamed("employment/employment", "Employed") \
        .withColumnRenamed("income-savings/income", "Income_range") \
        .withColumnRenamed("current-accommodation/home-how-many-bedrooms", "Current_bedrooms") \
        .withColumnRenamed("income-savings/savings", "Capital_range")

    ro1b = member_detail_final1.selectExpr("application_reference_overall as ID",
                                           "reference as Application_reference",
                                           "biddingnumber as Bidding_number",
                                           "title as Title",
                                           "firstname as First_Name",
                                           "surname as Surname",
                                           "date_of_birth as Date_of_Birth",
                                           "gender as Gender",
                                           "age as Age",
                                           "Tenure",
                                           "main_postcode",
                                           "main_addressLine1",
                                           "main_addressLine2",
                                           "main_addressLine3",
                                           "full_address as Address",
                                           "main_postcode as Post_code",
                                           "ward as Ward",
                                           "Current_bedrooms",
                                           "bedroomneed as Bedroom_needs",
                                           "band as Band",
                                           "Employed",
                                           "Income_range",
                                           "Capital_range",
                                           "Date_submitted",
                                           "effective_band_date",
                                           "reason as Reason_for_qualification",
                                           "status as Status",
                                           "Ethnicity",
                                           "No_people_in_household",
                                           "accessibilehousingregister as applicant_AHR",
                                           "import_year",
                                           "import_month",
                                           "import_day",
                                           "import_date"
                                           )

    # store out the data - main applicant
    dynamic_frame = DynamicFrame.fromDF(member_detail_final.repartition(1),
                                        glueContext, "target_data_to_write")

    S3bucket_node3 = glueContext.getSink(
        path=s3_target_refined + '/housing_register_main_applicant',
        connection_type="s3",
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=PARTITION_KEYS,
        enableUpdateCatalog=True,
        transformation_ctx="S3bucket_node3"
    )

    S3bucket_node3.setCatalogInfo(
        catalogDatabase='bens-housing-needs-refined-zone',
        catalogTableName='housing_register_main_applicant'
    )

    S3bucket_node3.setFormat("glueparquet")
    S3bucket_node3.writeFrame(dynamic_frame)

    # store out the data - other members
    dynamic_frame = DynamicFrame.fromDF(other_member_remove_nulls.repartition(1),
                                        glueContext, "target_data_to_write")

    S3bucket_node3 = glueContext.getSink(
        path=s3_target_refined + '/housing_register_other_members',
        connection_type="s3",
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=PARTITION_KEYS,
        enableUpdateCatalog=True,
        transformation_ctx="S3bucket_node3"
    )

    S3bucket_node3.setCatalogInfo(
        catalogDatabase='bens-housing-needs-refined-zone',
        catalogTableName='housing_register_other_members'
    )

    S3bucket_node3.setFormat("glueparquet")
    S3bucket_node3.writeFrame(dynamic_frame)

    # output R01b table
    clear_target_folder(s3_target_trusted + '/housing_register_ro1b')
    dynamic_frame = DynamicFrame.fromDF(ro1b.repartition(1),
                                        glueContext, "target_data_to_write")

    S3bucket_node3 = glueContext.getSink(
        path=s3_target_trusted + '/housing_register_ro1b',
        connection_type="s3",
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=PARTITION_KEYS,
        enableUpdateCatalog=True,
        transformation_ctx="S3bucket_node3"
    )

    S3bucket_node3.setCatalogInfo(
        catalogDatabase='bens-housing-needs-trusted-zone',
        catalogTableName='housing_register_ro1b'
    )

    S3bucket_node3.setFormat("glueparquet")
    S3bucket_node3.writeFrame(dynamic_frame)

    job.commit()
