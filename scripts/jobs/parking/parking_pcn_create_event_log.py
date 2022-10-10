import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var
environment = get_glue_env_var("environment")

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)

SqlQuery0 = '''
With Event_logFULL AS 
    (SELECT ticket_ref,
     CASE 
              When audit_message like '%NTO printed%' Then 'NTO printed'
              When audit_message like '%Appeal accepted%' Then 'Appeal accepted'
              When audit_message like '%Arrived in pound%' Then 'Arrived in pound'
              When audit_message like '%Cancellation reversed%' Then 'Cancellation reversed'
              When audit_message like '%CC printed%' Then 'CC printed'
              When audit_message like '%Debt Registration request%' Then 'Debt Registration request'
              When audit_message like '%EN printed%' Then 'EN printed'
              When audit_message like '%Hold released%' Then 'Hold released'
              When audit_message like '%DVLA Response%' Then 'DVLA Response'
              When audit_message like '%DVLA Request%' Then 'DVLA Request'
              When audit_message like '%Full rate uplift%' Then 'Full rate uplift'
              When audit_message like '%Hold until%' Then 'Hold until'
              When audit_message like '%Lifted at%' Then 'Lifted at'
              When audit_message like '%Lifted by%' Then 'Lifted by'
              When audit_message like '%Loaded%' Then 'Loaded'
              When audit_message like '%NoR sent%' Then 'NoR sent'
              When audit_message like '%Notice held%' Then 'Notice held'
              When audit_message like '%OFR printed%' Then 'OFR printed'
              When audit_message like '%PCN printed%' Then 'PCN printed'
              When audit_message like '%Re-issue NTO  requested%' Then 'Re-issue NTO  requested'
              When audit_message like '%Re-issue PCN%' Then 'Re-issue PCN'
              When audit_message like '%Set back to pre-CC stage%' Then 'Set back to pre-CC stage'
              When audit_message like '%Vehicle released for auction%' Then 'Vehicle released for auction'
              When audit_message like '%Warrant issued%' Then 'Warrant issued'
              When audit_message like '%Warrant redistributed%' Then 'Warrant redistributed'
              When audit_message like '%Warrant request granted%' Then 'Warrant request granted'
              When audit_message like '%Ad-hoc VQ4 request%' Then 'Ad-hoc VQ4 request'
              When audit_message like '%Paper VQ5 received%' Then 'Paper VQ5 received'
              When audit_message like '%Buslane PCN extracted for Enforcement notice%' 
                                                                         Then 'Buslane PCN extracted for Enforcement notice'
              When audit_message like '%PCN extracted for pre-debt screening%' Then 'PCN extracted for pre-debt screening'
              When audit_message like '%PCN extracted for collection%' Then 'PCN extracted for collection'
              When audit_message like '%PCN extracted for Debt Registration request%' 
                                                                                   Then 'PCN extracted for Debt Registration request'
              When audit_message like '%PCN extracted for CC%' Then 'PCN extracted for CC'
              When audit_message like '%PCN extracted for NTO%' Then 'PCN extracted for NTO'
              When audit_message like '%PCN extracted for print%' Then 'PCN extracted for print'
              When audit_message like '%Warning notice extracted for print%' Then 'Warning notice extracted for print'
              When audit_message like '%PCN extracted for OfR%' Then 'PCN extracted for OfR'
              When audit_message like '%PCN extracted for Warrant request%' Then 'PCN extracted for Warrant request'
              When audit_message like '%Pre-debt: New debtor details%' Then 'Pre-debt: New debtor details'
              else audit_message 
     END as audit_message, record_date_time, event_date_time, import_year, import_month, import_day, import_date
    FROM liberator_pcn_audit
    WHERE import_date = (SELECT MAX(import_date) FROM liberator_pcn_audit)),
    
Event_Row_no as (select *,
                     ROW_NUMBER() OVER ( PARTITION BY ticket_ref, audit_message, import_year, import_month, import_day, import_date
                     ORDER BY  ticket_ref,audit_message,event_date_time DESC) row_num
                     FROM Event_logFULL),
                     
EVENT_LOG as (Select ticket_ref, 
       MIN(Case When audit_message = 'NTO printed'           Then event_date_time END) AS NTO_printed, 
       MIN(Case When audit_message = 'Appeal accepted'       Then event_date_time END) AS Appeal_accepted,
       MIN(Case When audit_message = 'Arrived in pound'      Then event_date_time END) AS Arrived_in_pound,
       MIN(Case When audit_message = 'Cancellation reversed' Then event_date_time END) AS Cancellation_reversed, 
       
       MIN(Case When audit_message = 'CC printed'                Then event_date_time END) AS CC_printed, 
       MIN(Case When audit_message = 'Debt Registration request' Then event_date_time END) AS DRR,
       MIN(Case When audit_message = 'EN printed'                Then event_date_time END) AS EN_printed,
       MIN(Case When audit_message = 'Hold released'             Then event_date_time END) AS Hold_released,

       MIN(Case When audit_message = 'DVLA Response'             Then event_date_time END) AS DVLA_Response, 
       MIN(Case When audit_message = 'DVLA Request'              Then event_date_time END) AS DVLA_Request,
       MIN(Case When audit_message = 'Full rate uplift'          Then event_date_time END) AS Full_rate_uplift,
       MIN(Case When audit_message = 'Hold until'                Then event_date_time END) AS Hold_until,

      MIN(Case When audit_message = 'Lifted at'                 Then event_date_time END) AS Lifted_at, 
      MIN(Case When audit_message = 'Lifted by'                 Then event_date_time END) AS Lifted_by,
      MIN(Case When audit_message = 'Loaded'                    Then event_date_time END) AS Loaded,
      MIN(Case When audit_message = 'NoR sent'                  Then event_date_time END) AS NoR_sent,
      
      MIN(Case When audit_message = 'Notice held'               Then event_date_time END) AS Notice_held, 
      MIN(Case When audit_message = 'OFR printed'               Then event_date_time END) AS OFR_printed,
      MIN(Case When audit_message = 'PCN printed'               Then event_date_time END) AS PCN_printed,
      MIN(Case When audit_message = 'Re-issue NTO  requested'   Then event_date_time END) AS ReIssue_NTO_requested,

      MIN(Case When audit_message = 'Re-issue PCN'                 Then event_date_time END) AS ReIssue_PCN, 
      MIN(Case When audit_message = 'Set back to pre-CC stage'     Then event_date_time END) AS Set_back_to_pre_CC_stage,
      MIN(Case When audit_message = 'Vehicle released for auction' Then event_date_time END) AS Vehicle_released_for_auction,
      MIN(Case When audit_message = 'Warrant issued'               Then event_date_time END) AS Warrant_issued,

      MIN(Case When audit_message = 'Warrant redistributed'       Then event_date_time END) AS Warrant_redistributed, 
      MIN(Case When audit_message = 'Warrant request granted'     Then event_date_time END) AS Warrant_request_granted,
      MIN(Case When audit_message = 'Ad-hoc VQ4 request'          Then event_date_time END) AS Ad_hoc_VQ4_request,
      MIN(Case When audit_message = 'Paper VQ5 received'          Then event_date_time END) AS Paper_VQ5_received,

      MIN(Case When audit_message = 'Buslane PCN extracted for Enforcement notice' Then event_date_time END) 
                                                                                            AS PCN_extracted_for_BusLane, 
      MIN(Case When audit_message = 'PCN extracted for pre-debt screening'         Then event_date_time END) 
                                                                                            AS PCN_extracted_for_pre_debt,
      MIN(Case When audit_message = 'PCN extracted for collection'                 Then event_date_time END) 
                                                                                            AS PCN_extracted_for_collection,
      MIN(Case When audit_message = 'PCN extracted for Debt Registration request'  Then event_date_time END) 
                                                                                            AS PCN_extracted_for_DRR,

      MIN(Case When audit_message = 'PCN extracted for CC'                Then event_date_time END) AS PCN_extracted_for_CC, 
      MIN(Case When audit_message = 'PCN extracted for NTO'               Then event_date_time END) AS PCN_extracted_for_NTO,
      MIN(Case When audit_message = 'PCN extracted for print'             Then event_date_time END) AS PCN_extracted_for_print,
      MIN(Case When audit_message = 'Warning notice extracted for print'  Then event_date_time END) 
                                                                                             AS Warning_notice_extracted_for_print,

      MIN(Case When audit_message = 'PCN extracted for OfR'             Then event_date_time END) AS PCN_extracted_for_OfR, 
      MIN(Case When audit_message = 'PCN extracted for Warrant request' Then event_date_time END) AS PCN_extracted_for_Warrant_request,
      MIN(Case When audit_message = 'Pre-debt: New debtor details'      Then event_date_time END) AS Pre_debt_New_debtor_details,
      import_year, import_month, import_day, import_date
from Event_Row_no
 WHERE row_num = 1
  AND audit_message IN 
  ('NTO printed', 'Appeal accepted', 'Arrived in pound','Cancellation reversed', 'CC printed', 'Debt Registration request',
  'EN printed','Hold released','DVLA Response','DVLA Request','Full rate uplift','Hold until','Lifted at','Lifted by','Loaded',
  'NoR sent','Notice held','OFR printed','PCN printed','Re-issue NTO  requested','Re-issue PCN',
  'Set back to pre-CC stage','Vehicle released for auction','Warrant issued','Warrant redistributed','Warrant request granted',
  'Ad-hoc VQ4 request','Paper VQ5 received','Buslane PCN extracted for Enforcement notice','PCN extracted for pre-debt screening',
  'PCN extracted for collection','PCN extracted for Debt Registration request','PCN extracted for CC','PCN extracted for NTO',
  'PCN extracted for print','Warning notice extracted for print','PCN extracted for OfR','PCN extracted for Warrant request',
  'Pre-debt: New debtor details') 
Group by ticket_ref, import_year, import_month, import_day, import_date)

SELECT A.*, current_timestamp() as ImportDatTime
FROM EVENT_LOG as A

'''

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_pcn_audit", transformation_ctx = "DataSource0"]
## @return: DataSource0
## @inputs: []
DataSource0 = glueContext.create_dynamic_frame.from_catalog(database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_pcn_audit", transformation_ctx = "DataSource0")
## @type: SqlCode
## @args: [sqlAliases = {"liberator_pcn_audit": DataSource0}, sqlName = SqlQuery0, transformation_ctx = "Transform0"]
## @return: Transform0
## @inputs: [dfc = DataSource0]
Transform0 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"liberator_pcn_audit": DataSource0}, transformation_ctx = "Transform0")
## @type: DataSink
## @args: [connection_type = "s3", catalog_database_name = "dataplatform-" + environment + "-liberator-refined-zone", format = "glueparquet", connection_options = {"path": "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/PCNFOIDetails_PCN_EVENT_LOG/", "partitionKeys": ["import_year" ,"import_month" ,"import_day" ,"import_date"], "enableUpdateCatalog":true, "updateBehavior":"UPDATE_IN_DATABASE"}, catalog_table_name = "PCNFOIDetails_PCN_EVENT_LOG", transformation_ctx = "DataSink0"]
## @return: DataSink0
## @inputs: [frame = Transform0]
DataSink0 = glueContext.getSink(path = "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/PCNFOIDetails_PCN_EVENT_LOG/", connection_type = "s3", updateBehavior = "UPDATE_IN_DATABASE", partitionKeys = ["import_year","import_month","import_day","import_date"], enableUpdateCatalog = True, transformation_ctx = "DataSink0")
DataSink0.setCatalogInfo(catalogDatabase = "dataplatform-" + environment + "-liberator-refined-zone",catalogTableName = "PCNFOIDetails_PCN_EVENT_LOG")
DataSink0.setFormat("glueparquet")
DataSink0.writeFrame(Transform0)

job.commit()