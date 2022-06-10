### This ETL script:            etl_ctax_live_properties.py
### Last updated:               2022-06-01 UNTESTED
### Deployment status:          https://github.com/stevefarrhackneygovuk/Academy-sql/blob/main/CTax/CTax_Live_Properties/README.md#data-platform
### Based upon:                 AWSGlue-Revenues-ETL-CTax_Live_Properties_Automation.SparkSQL.py
### Taken from AWS Glue job:    Revenues ETL CTax_Live_Properties_Automation
### Target path 1 updated:      s3://dataplatform-stg-refined-zone/revenues/ctax/ctax-live-properties/
### Target path 2 updated:      s3://dataplatform-stg-refined-zone/revenues/ctax/ctax-transforms/
### Source tables:              Data from the raw zone is pulled via the Data Catalog
### Feedback from targets 1&2:  Data from the refined zone is also pulled via the Data Catalog

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from awsglue import DynamicFrame
from pyspark.sql import functions as SqlFuncs


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


def sparkAggregate(
    glueContext, parentFrame, groups, aggs, transformation_ctx
) -> DynamicFrame:
    aggsFuncs = []
    for column, func in aggs:
        aggsFuncs.append(getattr(SqlFuncs, func)(column))
    result = (
        parentFrame.toDF().groupBy(*groups).agg(*aggsFuncs)
        if len(groups) > 0
        else parentFrame.toDF().agg(*aggsFuncs)
    )
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node ctax_transforms
ctax_transforms_node1653392237115 = glueContext.create_dynamic_frame.from_catalog(
    database="revenues-refined-zone",
    table_name="ctax_transforms",
    transformation_ctx="ctax_transforms_node1653392237115",
)

# Script generated for node ctax_live_properties
ctax_live_properties_node1653391213498 = glueContext.create_dynamic_frame.from_catalog(
    database="revenues-refined-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="ctax_live_properties",
    transformation_ctx="ctax_live_properties_node1653391213498",
)

# Script generated for node lbhaliverbviews_core_ctproperty
lbhaliverbviews_core_ctproperty_node1651056949881 = glueContext.create_dynamic_frame.from_catalog(
    database="revenues-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="lbhaliverbviews_core_ctproperty",
    transformation_ctx="lbhaliverbviews_core_ctproperty_node1651056949881",
)

# Script generated for node lbhaliverbviews_core_ctbandperiod
lbhaliverbviews_core_ctbandperiod_node1651055946682 = glueContext.create_dynamic_frame.from_catalog(
    database="revenues-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="lbhaliverbviews_core_ctbandperiod",
    transformation_ctx="lbhaliverbviews_core_ctbandperiod_node1651055946682",
)

# Script generated for node lbhaliverbviews_core_ctoccupation
lbhaliverbviews_core_ctoccupation_node1651056747058 = glueContext.create_dynamic_frame.from_catalog(
    database="revenues-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="lbhaliverbviews_core_ctoccupation",
    transformation_ctx="lbhaliverbviews_core_ctoccupation_node1651056747058",
)

# Script generated for node lbhaliverbviews_core_ctaccount
lbhaliverbviews_core_ctaccount_node1651057095386 = glueContext.create_dynamic_frame.from_catalog(
    database="revenues-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="lbhaliverbviews_core_ctaccount",
    transformation_ctx="lbhaliverbviews_core_ctaccount_node1651057095386",
)

# Script generated for node ctax_transforms
ctax_transforms_node1653392355291 = SelectFields.apply(
    frame=ctax_transforms_node1653392237115,
    paths=["jx_id", "generation_id"],
    transformation_ctx="ctax_transforms_node1653392355291",
)

# Script generated for node ctax_live_properties.import_date
ctax_live_propertiesimport_date_node1653391773650 = SelectFields.apply(
    frame=ctax_live_properties_node1653391213498,
    paths=["import_date"],
    transformation_ctx="ctax_live_propertiesimport_date_node1653391773650",
)

# Script generated for node ctproperty
ctproperty_node1651660287657 = SelectFields.apply(
    frame=lbhaliverbviews_core_ctproperty_node1651056949881,
    paths=[
        "addr4",
        "addr3",
        "addr2",
        "addr1",
        "postcode",
        "import_date",
        "property_ref",
        "import_datetime",
    ],
    transformation_ctx="ctproperty_node1651660287657",
)

# Script generated for node ctbandperiod
ctbandperiod_node1651659633005 = SelectFields.apply(
    frame=lbhaliverbviews_core_ctbandperiod_node1651055946682,
    paths=[
        "import_date",
        "property_ref",
        "band_from",
        "band",
        "live_ind",
        "band_to",
        "import_datetime",
    ],
    transformation_ctx="ctbandperiod_node1651659633005",
)

# Script generated for node ctoccupation
ctoccupation_node1651659955096 = SelectFields.apply(
    frame=lbhaliverbviews_core_ctoccupation_node1651056747058,
    paths=[
        "import_date",
        "account_ref",
        "property_ref",
        "vacation_date",
        "live_ind",
        "import_datetime",
    ],
    transformation_ctx="ctoccupation_node1651659955096",
)

# Script generated for node ctaccount
ctaccount_node1651660422737 = SelectFields.apply(
    frame=lbhaliverbviews_core_ctaccount_node1651057095386,
    paths=[
        "import_date",
        "account_ref",
        "account_cd",
        "lead_liab_name",
        "lead_liab_pos",
        "paymeth_code",
        "paymeth_type",
        "import_datetime",
    ],
    transformation_ctx="ctaccount_node1651660422737",
)

# Script generated for node Jx_ID
Jx_ID_node1653927733384 = RenameField.apply(
    frame=ctax_transforms_node1653392355291,
    old_name="jx_id",
    new_name="Jx_ID",
    transformation_ctx="Jx_ID_node1653927733384",
)

# Script generated for node max(import_date)
maximport_date_node1653665281967 = sparkAggregate(
    glueContext,
    parentFrame=ctax_live_propertiesimport_date_node1653391773650,
    groups=[],
    aggs=[["import_date", "max"]],
    transformation_ctx="maximport_date_node1653665281967",
)

# Script generated for node ctproperty
ctproperty_node1653304315018 = DynamicFrame.fromDF(
    ctproperty_node1651660287657.toDF().dropDuplicates(
        ["addr1", "addr2", "addr3", "addr4", "postcode", "import_date", "property_ref"]
    ),
    glueContext,
    "ctproperty_node1653304315018",
)

# Script generated for node ctbandperiod
ctbandperiod_node1653305110954 = DynamicFrame.fromDF(
    ctbandperiod_node1651659633005.toDF().dropDuplicates(
        ["property_ref", "band", "band_from", "band_to", "live_ind", "import_date"]
    ),
    glueContext,
    "ctbandperiod_node1653305110954",
)

# Script generated for node ctoccupation
ctoccupation_node1653305239658 = DynamicFrame.fromDF(
    ctoccupation_node1651659955096.toDF().dropDuplicates(
        ["account_ref", "property_ref", "vacation_date", "import_date", "live_ind"]
    ),
    glueContext,
    "ctoccupation_node1653305239658",
)

# Script generated for node ctaccount
ctaccount_node1653304985950 = DynamicFrame.fromDF(
    ctaccount_node1651660422737.toDF().dropDuplicates(
        [
            "account_ref",
            "account_cd",
            "lead_liab_name",
            "lead_liab_pos",
            "paymeth_code",
            "paymeth_type",
            "import_date",
        ]
    ),
    glueContext,
    "ctaccount_node1653304985950",
)

# Script generated for node generation_ID
generation_ID_node1653927804700 = RenameField.apply(
    frame=Jx_ID_node1653927733384,
    old_name="generation_id",
    new_name="generation_ID",
    transformation_ctx="generation_ID_node1653927804700",
)

# Script generated for node import_date
import_date_node1653666447563 = RenameField.apply(
    frame=maximport_date_node1653665281967,
    old_name="`max(import_date)`",
    new_name="import_date",
    transformation_ctx="import_date_node1653666447563",
)

# Script generated for node Jx_ID_1_Automation.Spark.sql
SqlQuery2 = """
-- Last updated:        2022-05-31 
-- Spark SQL query:     Jx_ID_1_Automation.Spark.sql
---
-- AWS Glue job:        Revenues ETL CTax_Live_Properties_Automation
---
-- Jx database:         Defined externally
-- Jx source:           Defined externally and established programatically
-- Jx target:           Jx_Data.Spark.sql and optionally Jx_Transforms.Spark.sql
-- Jx predicate:        N/A
-- Jx columns supplied and selectively sourced:
--                      transform_timestamp     TIMESTAMP
--                      transform_name          STRING
--      Partition(0):   transform_year          STRING  'yyyy'
--      Partition(1):   transform_month         STRING  'MM'
--      Partition(2):   transform_day           STRING  'dd'
--      Partition(3):   transform_date          STRING  'yyyyMMdd'
--      Partition(5):   Jx_ID                   INT     (renamed field)
--      Partition(6):   generation_ID           INT     (renamed field)
--                      debug_info              STRING  -- Information recorded for testing and debugging jobs.
---
-- In AWS Glue Studio, adding this transform as "dummy" input source to the main ETL transform, will ensure this transform produces an appropriate current_timestamp() value which is close as possible to the start of the ETL process.
-- Also trying to fool AWS Glue Studio into ensuring this transform is on the first import branch eg. By introducing extra RenameField transforms.
-- Due to Spark bug, cannot use the ApplyMapping transform in place of the RenameField transforms because Spark will substitute NULLs in place of values. May be an issue with INT partitions.
---
WITH 
aggregation AS (
    SELECT
        MAX(CAST(j.Jx_ID AS INT))                       AS Jx_ID,
        MAX(CAST(j.generation_ID AS INT))               AS max_generation_ID,   -- Last generation or none  -- DEBUG ISSUE: Must ensure Spark doesn't MAX(generation_ID) like it's a string.
        CAST(COUNT(j.*) AS INT)                         AS Jx_rows              -- Wanted for debug_info    -- Beware, Spark SQL COUNT(j.*) outputs NULL instead of ZERO where no rows FROM jobs j.
    FROM 
        jobs j
    WHERE
        CAST(j.Jx_ID AS INT) = 1   -- Job's index ID = Number ONE is the identifier of this job aka transform.name
    -- By using MAX(j.Jx_ID) and not using GROUP BY ensures single aggregate row is always produced. 
    -- GROUP BY
    --    j.Jx_ID
)
SELECT
    CAST(1 AS INT)                                      AS Jx_ID,           -- Job's index ID = Number ONE
    CAST(IFNULL(a.max_generation_ID, 0) + 1 AS INT)     AS generation_ID,   -- Generation increment
    'Revenues ETL CTax_Live_Properties_Automation'      AS transform_name,  -- In theory this could be anything so long as both ID columns are used to reference the transform
    CAST(current_timestamp() AS TIMESTAMP)              AS transform_timestamp,
    CAST(year(current_date()) AS STRING)                AS transform_year, 
    CAST(month(current_date()) AS STRING)               AS transform_month, 
    CAST(day(current_date()) AS STRING)                 AS transform_day,
    REPLACE(CAST(current_date() AS STRING), '-', '')    AS transform_date,
    'Jx_ID_1_Automation.Spark.sql: '                    -- Reproducing the critical outputs to monitor...
        || 'MAX(CAST(j.Jx_ID AS INT)) -> a.Jx_ID = ' || IFNULL(STRING( a.Jx_ID ), 'NULL') || '; ' 
        || 'CAST(1 AS INT) --> Jx_ID = ' || STRING( CAST(1 AS INT) ) || '; '
        || 'MAX(CAST(j.generation_ID AS INT)) -> a.max_generation_ID = ' || IFNULL(STRING( a.max_generation_ID ), 'NULL') || '; ' 
        || 'CAST(IFNULL(a.max_generation_ID, 0) + 1 AS INT) --> generation_ID = ' || STRING( CAST(IFNULL(a.max_generation_ID, 0) + 1 AS INT) ) || '; ' 
        || 'CAST(COUNT(j.*) AS INT) -> a.Jx_rows = ' || IFNULL(STRING( a.Jx_rows ), 'NULL')  || '; ' 
        AS debug_info
FROM
    aggregation a
--;--

"""
Jx_ID_1_AutomationSparksql_node1652882136682 = sparkSqlQuery(
    glueContext,
    query=SqlQuery2,
    mapping={"jobs": generation_ID_node1653927804700},
    transformation_ctx="Jx_ID_1_AutomationSparksql_node1652882136682",
)

# Script generated for node CTax_Live_Properties_Automation.Spark.sql
SqlQuery1 = """
-- Last updated:        2022-05-27
-- Spark SQL query:     CTax_Live_Properties_Automation.Spark.sql
---
-- AWS Glue job:        Revenues ETL CTax_Live_Properties_Automation
-- Job bookmark:        Disable
-- Worker type:         G.2X
-- Number of workers:   10 requested
---
-- Jx database:         revenues-refined-zone
-- Jx predicate:        N/A
-- Jx source/target:    jobs = ctax_transforms
-- Jx partition(0):     transform_year          STRING  'yyyy'
-- Jx partition(1):     transform_month         STRING  'MM'
-- Jx partition(2):     transform_day           STRING  'dd'
-- Jx partition(3):     transform_date          STRING  'yyyyMMdd'
-- Jx partition(4):     import_date             STRING  'yyyyMMdd'
-- Jx partition(5):     Jx_ID                   INT
-- Jx partition(6):     generation_ID           INT
--                      generation_rows         INT
--                      generation_time         DOUBLE
--                      transform_timestamp     TIMESTAMP
--                      transform_name          STRING
--                      import_min_timestamp    TIMESTAMP
--                      import_max_timestamp    TIMESTAMP
---
-- Source database 1:   revenues-raw-zone
-- Source type:         S3 Data Catalog table
-- Source predicate:    to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)
-- Source tables:
--                      ctbandperiod    = lbhaliverbviews_core_ctbandperiod
--                      ctoccupation    = lbhaliverbviews_core_ctoccupation
--                      ctproperty      = lbhaliverbviews_core_ctproperty
--                      ctaccount       = lbhaliverbviews_core_ctaccount
---
-- Source database 2:   revenues-refined-zone
-- Source type:         S3 Data Catalog table
-- Source predicate:    to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)
-- Source table/column: ctax_live_properties.import_date
---
-- Target database:     revenues-refined-zone
-- Target table:        ctax_live_properties
-- Target format:       Parquet
-- Target path:         s3://dataplatform-stg-refined-zone/revenues/ctax/ctax-live-properties/
-- Target columns supplied:
--                      account_ref             INT
--                      lead_liab_name          STRING
--                      lead_liab_pos           SMALLINT
--                      property_ref            STRING 
--                      band                    STRING
--                      band_from               STRING
--                      full_account_number     STRING
--                      paymeth_code            STRING
--                      paymeth_type            SMALLINT
--                      vacation_date           TIMESTAMP
--                      addr1                   STRING
--                      addr2                   STRING
--                      addr3                   STRING
--                      addr4                   STRING
--                      postcode                STRING
--      Partition(4):   import_date             STRING  'yyyyMMdd'
--                      import_timestamp        TIMESTAMP
---
-- Target colummns externally supplied and cross-joined:
--      Partition(0):   transform_year          STRING  'yyyy'
--      Partition(1):   transform_month         STRING  'MM'
--      Partition(2):   transform_day           STRING  'dd'
--      Partition(3):   transform_date          STRING  'yyyyMMdd'
--                      transform_timestamp     TIMESTAMP
--      Partition(5):   Jx_ID                   INT
--      Partition(6):   generation_ID           INT
---
WITH
vw_ct_band AS (
    SELECT
        bp.import_date,
        MAX(CAST(bp.import_datetime AS TIMESTAMP)) AS import_timestamp,
        bp.property_ref,
        MAX(CAST(bp.band_from AS DATE)) AS band_from,
        bp.band        
    FROM 
        ctbandperiod bp
    WHERE 
        bp.live_ind = 1   
    AND 
        bp.band_to = DATE '2099-12-31'
    GROUP BY
        bp.import_date,
        bp.property_ref,
        bp.band                                      
),
qc AS (
    SELECT
        c.import_date,
        CAST(c.import_datetime AS TIMESTAMP) AS import_timestamp,
        c.account_ref,
        c.property_ref,
        CAST(c.vacation_date AS DATE) AS vacation_date
    FROM
        ctoccupation c
    WHERE
        c.live_ind = 1
    AND 
        c.vacation_date = DATE '2099-12-31'
),
qcd AS (
    SELECT 
        qc.import_date,
        GREATEST(qc.import_timestamp, CAST(d.import_datetime AS TIMESTAMP)) AS import_timestamp,
        qc.account_ref,
        qc.property_ref,
        qc.vacation_date,
        d.addr1,
        d.addr2,
        d.addr3,
        d.addr4,
        d.postcode
    FROM qc
    INNER JOIN
        ctproperty d
    ON
        qc.import_date = d.import_date
    AND
        qc.property_ref = d.property_ref
),
qcde AS (
    SELECT
        qcd.import_date,
        GREATEST(qcd.import_timestamp, e.import_timestamp) AS import_timestamp,
        qcd.account_ref,
        qcd.property_ref,
        qcd.vacation_date,
        qcd.addr1,
        qcd.addr2,
        qcd.addr3,
        qcd.addr4,
        qcd.postcode,
        e.band,
        e.band_from
    FROM qcd
    INNER JOIN 
        vw_ct_band e
    ON
        qcd.import_date = e.import_date
    AND
        qcd.property_ref = e.property_ref
),
ingested AS (
        SELECT MAX(import_date) AS last_import_date FROM ctbandperiod
    UNION
        SELECT MAX(import_date) AS last_import_date FROM ctoccupation
    UNION
        SELECT MAX(import_date) AS last_import_date FROM ctproperty
    UNION
        SELECT MAX(import_date) AS last_import_date FROM ctaccount
),
raw AS (
    SELECT 
        MIN(last_import_date) AS import_date 
    FROM 
        ingested
),
refined AS (
    SELECT 
        MAX(import_date) AS import_date 
    FROM 
        ctax_live_properties
),
p AS (
    SELECT 
        raw.import_date
    FROM 
        raw, 
        refined
    WHERE 
        raw.import_date > refined.import_date   -- If materialisation of raw.import_date already done in refined then no rows returned.
),
partition_ctaccount AS (
    SELECT 
        b.import_date,
        CAST(b.import_datetime AS TIMESTAMP) AS import_timestamp,
        b.account_ref,
        b.account_cd,  
        TRIM(CAST(b.account_ref AS STRING)) || b.account_cd AS full_account_number,  
        b.lead_liab_name,
        CAST(b.lead_liab_pos AS SMALLINT)  AS lead_liab_pos,   -- DECIMAL source type
        b.paymeth_code,
        CAST(b.paymeth_type AS SMALLINT)   AS paymeth_type     -- DECIMAL source type
    FROM 
        ctaccount b
    INNER JOIN p
    ON
        b.import_date = p.import_date   -- As per above, p.import_date is either latest complete import or none if already done.
)
SELECT
    pb.account_ref,
    pb.lead_liab_name,
    pb.lead_liab_pos,
    qcde.property_ref,
    qcde.band,
    qcde.band_from,
    pb.full_account_number,  
    pb.paymeth_code,
    pb.paymeth_type,
    qcde.vacation_date,
    qcde.addr1,
    qcde.addr2,
    qcde.addr3,
    qcde.addr4,
    qcde.postcode,
    pb.import_date,
    -- If data gets imported multiple times under same input_date then adding this makes import records remain unique...
    GREATEST(qcde.import_timestamp, pb.import_timestamp) AS import_timestamp  -- tabular-max aggregation
FROM qcde
INNER JOIN
    partition_ctaccount pb
ON 
    qcde.import_date = pb.import_date
AND
    qcde.account_ref = pb.account_ref
--;--
"""
CTax_Live_Properties_AutomationSparksql_node1650654183012 = sparkSqlQuery(
    glueContext,
    query=SqlQuery1,
    mapping={
        "ctbandperiod": ctbandperiod_node1653305110954,
        "ctoccupation": ctoccupation_node1653305239658,
        "ctaccount": ctaccount_node1653304985950,
        "dummy": Jx_ID_1_AutomationSparksql_node1652882136682,
        "ctproperty": ctproperty_node1653304315018,
        "ctax_live_properties": import_date_node1653666447563,
    },
    transformation_ctx="CTax_Live_Properties_AutomationSparksql_node1650654183012",
)

# Script generated for node Jx_Data.Spark.sql
SqlQuery3 = """
-- Last updated:        2022-05-23
-- Spark SQL query:     Jx_Data.Spark.sql
---
-- Jx database:         Defined externally
-- Jx source:           Jx_ID_n_Automation.Spark.sql or Jx_ID_n_Initialization.Spark.sql
-- Jx target:           Externally defined target and optionally Jx_Transforms.Spark.sql
-- Jx predicate:        N/A
-- Jx columns sourced and supplied:
--                      transform_timestamp     TIMESTAMP
--                      transform_name          STRING
--      Partition(0):   transform_year          STRING  'yyyy'
--      Partition(1):   transform_month         STRING  'MM'
--      Partition(2):   transform_day           STRING  'dd'
--      Partition(3):   transform_date          STRING  'yyyyMMdd'
--      Partition(5):   Jx_ID                   INT
--      Partition(6):   generation_ID           INT
---
-- Jx target colummn in common with subject data:
--      Partition(4):   import_date             STRING  'yyyyMMdd'
--                      import_timestamp        TIMESTAMP
---
-- Subject data:        data    = Defined externally
-- Subject columns:     *       = Defined externally
---
SELECT
    -- NOTE: the transformed subject d.* MUST supply these columns for the Jx & subject targets...
    -- d.import_date,  
    -- d.import_timestamp,
    d.*,
    j.Jx_ID,                    --  singular job's index ID added partition key
    j.generation_ID,            --  incremented generation ID added partition key
    j.transform_name,           --  job info usually omitted from the subject target but added to transforms log
    j.transform_timestamp,      --  ealiest possible recordable job timestamp
    j.transform_year,           --  added partition key
    j.transform_month,          --  added partition key
    j.transform_day,            --  added partition key
    j.transform_date            --  added partition key
FROM 
    data d                      -- subject data
CROSS JOIN
    jobs j  -- singular job's index record
--;--
"""
Jx_DataSparksql_node1653307221832 = sparkSqlQuery(
    glueContext,
    query=SqlQuery3,
    mapping={
        "data": CTax_Live_Properties_AutomationSparksql_node1650654183012,
        "jobs": Jx_ID_1_AutomationSparksql_node1652882136682,
    },
    transformation_ctx="Jx_DataSparksql_node1653307221832",
)

# Script generated for node Jx_Transforms.Spark.sql
SqlQuery0 = """
-- Last updated:        2022-05-31
-- Spark SQL query:     Jx_Transforms.Spark.sql
---
-- Jx database:         Defined externally
-- Jx source:           jobs    = Jx_ID_n_Automation.Spark.sql or Jx_ID_n_Initialization.Spark.sql
-- Jx target:           Defined externally
-- Jx predicate:        N/A
-- Jx columns sourced and supplied to target:
--                      transform_timestamp     TIMESTAMP
--                      transform_name          STRING
--      Partition(0):   transform_year          STRING  'yyyy'
--      Partition(1):   transform_month         STRING  'MM'
--      Partition(2):   transform_day           STRING  'dd'
--      Partition(3):   transform_date          STRING  'yyyyMMdd'
--      Partition(5):   Jx_ID                   INT
--      Partition(6):   generation_ID           INT
---
-- Jx target colummns aggregated from subject data:
--      Partition(4):   import_date             STRING  'yyyyMMdd'
--                      import_min_timestamp    TIMESTAMP
--                      import_max_timestamp    TIMESTAMP
--                      generation_rows         INT
---
-- Jx target columns generated:
--                      generation_time         DOUBLE  -- Time elapsed, in seconds, since Jx_ID_n_Xxxxx.Spark.sql transform executed.
--                      debug_info              STRING  -- Information recorded for testing and debugging jobs.
---
-- Subject data:        data    = Defined externally, subsequently Jx-enhanced
-- Subject columns:     *       = Defined externally with Jx columns added
---
WITH 
aggregation AS (
    SELECT
        MAX(d.import_date)                          AS import_date,     -- Beware, using GROUP BY d.import_date instead of MAX(d.import_date) outputs zero rows where zero rows FROM data d. 
        CAST(MIN(import_timestamp) AS TIMESTAMP)    AS import_min_timestamp,
        CAST(MAX(import_timestamp) AS TIMESTAMP)    AS import_max_timestamp,
        CAST(COUNT(d.*) AS INT)                     AS generation_rows  -- Beware, Spark SQL COUNT(d.*) outputs NULL instead of ZERO where no rows FROM data d.
    FROM 
        data d
    -- Not using GROUP BY ensures Spark SQL always produces an aggregate result even when no rows to agregate.
)
SELECT 
    -- Because import_date is a partition key we must represent NULL...
    CAST(IFNULL(a.import_date, '00000000') AS STRING)                           AS import_date,
    -- ...but NULLs will be allowed for these min/max timestamps...
    a.import_min_timestamp                                                      AS import_min_timestamp,
    a.import_max_timestamp                                                      AS import_max_timestamp,
    CAST(IFNULL(a.generation_rows, 0) AS INT)                                   AS generation_rows,     -- Turns to ZERO when no data rows returned
    j.Jx_ID,                                                                                            -- Singular job's index ID
    j.generation_ID,                                                                                    -- Can generate IDS more frequently than just daily
    CAST(current_timestamp() AS DOUBLE) - CAST(j.transform_timestamp AS DOUBLE) AS generation_time,     -- result down to fractions of a second
    j.transform_name,                                                                                   -- omitted from report output
    j.transform_timestamp,
    j.transform_year, 
    j.transform_month, 
    j.transform_day,
    j.transform_date,
    j.debug_info        -- Copy critical outputs to monitor here.
FROM
    jobs j              -- singular job's index record
CROSS JOIN              -- want to ensure we get an output even when generation_rows = ZERO
    aggregation a
--;--

"""
Jx_TransformsSparksql_node1652888513566 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "data": Jx_DataSparksql_node1653307221832,
        "jobs": Jx_ID_1_AutomationSparksql_node1652882136682,
    },
    transformation_ctx="Jx_TransformsSparksql_node1652888513566",
)

# Script generated for node ctax_live_properties
ctax_live_properties_node1652885437268 = SelectFields.apply(
    frame=Jx_DataSparksql_node1653307221832,
    paths=[
        "import_date",
        "import_timestamp",
        "property_ref",
        "band",
        "band_from",
        "lead_liab_name",
        "paymeth_code",
        "paymeth_type",
        "addr1",
        "addr2",
        "addr3",
        "addr4",
        "postcode",
        "account_ref",
        "full_account_number",
        "lead_liab_pos",
        "vacation_date",
        "transform_month",
        "transform_timestamp",
        "Jx_ID",
        "generation_ID",
        "transform_year",
        "transform_day",
        "transform_date",
    ],
    transformation_ctx="ctax_live_properties_node1652885437268",
)

# Script generated for node ctax_transforms
ctax_transforms_node1652892278505 = glueContext.getSink(
    path="s3://dataplatform-stg-refined-zone/revenues/ctax/ctax-transforms/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=[
        "transform_year",
        "transform_month",
        "transform_day",
        "transform_date",
        "import_date",
        "Jx_ID",
        "generation_ID",
    ],
    enableUpdateCatalog=True,
    transformation_ctx="ctax_transforms_node1652892278505",
)
ctax_transforms_node1652892278505.setCatalogInfo(
    catalogDatabase="revenues-refined-zone", catalogTableName="ctax_transforms"
)
ctax_transforms_node1652892278505.setFormat("glueparquet")
ctax_transforms_node1652892278505.writeFrame(Jx_TransformsSparksql_node1652888513566)
# Script generated for node ctax_live_properties
ctax_live_properties_node3 = glueContext.getSink(
    path="s3://dataplatform-stg-refined-zone/revenues/ctax/ctax-live-properties/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=[
        "transform_year",
        "transform_month",
        "transform_day",
        "transform_date",
        "import_date",
        "Jx_ID",
        "generation_ID",
    ],
    enableUpdateCatalog=True,
    transformation_ctx="ctax_live_properties_node3",
)
ctax_live_properties_node3.setCatalogInfo(
    catalogDatabase="revenues-refined-zone", catalogTableName="ctax_live_properties"
)
ctax_live_properties_node3.setFormat("glueparquet")
ctax_live_properties_node3.writeFrame(ctax_live_properties_node1652885437268)
job.commit()
