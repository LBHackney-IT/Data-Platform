import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
environment = get_glue_env_var("environment")

# Script generated for node Liberator Refined - pcnfoidetails_pcn_foi_full
LiberatorRefinedpcnfoidetails_pcn_foi_full_node1716380330290 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-refined-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="pcnfoidetails_pcn_foi_full", transformation_ctx="LiberatorRefinedpcnfoidetails_pcn_foi_full_node1716380330290")

# Script generated for node parking_raw_zone - parking_nas_live_manual_updates_data_load
parking_raw_zoneparking_nas_live_manual_updates_data_load_node1716380310939 = glueContext.create_dynamic_frame.from_catalog(database="parking-raw-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="parking_nas_live_manual_updates_data_load", transformation_ctx="parking_raw_zoneparking_nas_live_manual_updates_data_load_node1716380310939")

# Script generated for node SQL Query
SqlQuery0 = '''
With pcns as ( Select
/*pcn data*/
pcnfoidetails_pcn_foi_full.pcn as pcn_pcn
,pcnfoidetails_pcn_foi_full.pcnissuedate as pcn_pcnissuedate
,pcnfoidetails_pcn_foi_full.pcnissuedatetime as pcn_pcnissuedatetime
,pcnfoidetails_pcn_foi_full.pcn_canx_date as pcn_pcn_canx_date
,pcnfoidetails_pcn_foi_full.cancellationgroup as pcn_cancellationgroup
,pcnfoidetails_pcn_foi_full.cancellationreason as pcn_cancellationreason
,pcnfoidetails_pcn_foi_full.pcn_casecloseddate as pcn_pcn_casecloseddate
,pcnfoidetails_pcn_foi_full.street_location as pcn_street_location
,pcnfoidetails_pcn_foi_full.whereonlocation as pcn_whereonlocation
,pcnfoidetails_pcn_foi_full.zone as pcn_zone
,pcnfoidetails_pcn_foi_full.usrn as pcn_usrn
,pcnfoidetails_pcn_foi_full.contraventioncode as pcn_contraventioncode
,pcnfoidetails_pcn_foi_full.contraventionsuffix as pcn_contraventionsuffix
,pcnfoidetails_pcn_foi_full.debttype as pcn_debttype
,pcnfoidetails_pcn_foi_full.vrm as pcn_vrm
,pcnfoidetails_pcn_foi_full.vehiclemake as pcn_vehiclemake
,pcnfoidetails_pcn_foi_full.vehiclemodel as pcn_vehiclemodel
,pcnfoidetails_pcn_foi_full.vehiclecolour as pcn_vehiclecolour
,pcnfoidetails_pcn_foi_full.ceo as pcn_ceo
,pcnfoidetails_pcn_foi_full.ceodevice as pcn_ceodevice
,pcnfoidetails_pcn_foi_full.current_30_day_flag as pcn_current_30_day_flag
,pcnfoidetails_pcn_foi_full.isvda as pcn_isvda
,pcnfoidetails_pcn_foi_full.isvoid as pcn_isvoid
,pcnfoidetails_pcn_foi_full.isremoval as pcn_isremoval
,pcnfoidetails_pcn_foi_full.driverseen as pcn_driverseen
,pcnfoidetails_pcn_foi_full.allwindows as pcn_allwindows
,pcnfoidetails_pcn_foi_full.parkedonfootway as pcn_parkedonfootway
,pcnfoidetails_pcn_foi_full.doctor as pcn_doctor
,pcnfoidetails_pcn_foi_full.warningflag as pcn_warningflag
,pcnfoidetails_pcn_foi_full.progressionstage as pcn_progressionstage
,pcnfoidetails_pcn_foi_full.nextprogressionstage as pcn_nextprogressionstage
,pcnfoidetails_pcn_foi_full.nextprogressionstagestarts as pcn_nextprogressionstagestarts
,pcnfoidetails_pcn_foi_full.holdreason as pcn_holdreason
,pcnfoidetails_pcn_foi_full.lib_initial_debt_amount as pcn_lib_initial_debt_amount
,pcnfoidetails_pcn_foi_full.lib_payment_received as pcn_lib_payment_received
,pcnfoidetails_pcn_foi_full.lib_write_off_amount as pcn_lib_write_off_amount
,pcnfoidetails_pcn_foi_full.lib_payment_void as pcn_lib_payment_void
,pcnfoidetails_pcn_foi_full.lib_payment_method as pcn_lib_payment_method
,pcnfoidetails_pcn_foi_full.lib_payment_ref as pcn_lib_payment_ref
,pcnfoidetails_pcn_foi_full.baliff_from as pcn_baliff_from
,pcnfoidetails_pcn_foi_full.bailiff_to as pcn_bailiff_to
,pcnfoidetails_pcn_foi_full.bailiff_processedon as pcn_bailiff_processedon
,pcnfoidetails_pcn_foi_full.bailiff_redistributionreason as pcn_bailiff_redistributionreason
,pcnfoidetails_pcn_foi_full.bailiff as pcn_bailiff
,pcnfoidetails_pcn_foi_full.warrantissuedate as pcn_warrantissuedate
,pcnfoidetails_pcn_foi_full.allocation as pcn_allocation
,pcnfoidetails_pcn_foi_full.eta_datenotified as pcn_eta_datenotified
,pcnfoidetails_pcn_foi_full.eta_packsubmittedon as pcn_eta_packsubmittedon
,pcnfoidetails_pcn_foi_full.eta_evidencedate as pcn_eta_evidencedate
,pcnfoidetails_pcn_foi_full.eta_adjudicationdate as pcn_eta_adjudicationdate
,pcnfoidetails_pcn_foi_full.eta_appealgrounds as pcn_eta_appealgrounds
,pcnfoidetails_pcn_foi_full.eta_decisionreceived as pcn_eta_decisionreceived
,pcnfoidetails_pcn_foi_full.eta_outcome as pcn_eta_outcome
,pcnfoidetails_pcn_foi_full.eta_packsubmittedby as pcn_eta_packsubmittedby
,pcnfoidetails_pcn_foi_full.cancelledby as pcn_cancelledby
,pcnfoidetails_pcn_foi_full.registered_keeper_address as pcn_registered_keeper_address
,pcnfoidetails_pcn_foi_full.current_ticket_address as pcn_current_ticket_address
,pcnfoidetails_pcn_foi_full.corresp_dispute_flag as pcn_corresp_dispute_flag
,pcnfoidetails_pcn_foi_full.keyworker_corresp_dispute_flag as pcn_keyworker_corresp_dispute_flag
,pcnfoidetails_pcn_foi_full.fin_year_flag as pcn_fin_year_flag
,pcnfoidetails_pcn_foi_full.fin_year as pcn_fin_year
,pcnfoidetails_pcn_foi_full.ticket_ref as pcn_ticket_ref
,pcnfoidetails_pcn_foi_full.nto_printed as pcn_nto_printed
,pcnfoidetails_pcn_foi_full.appeal_accepted as pcn_appeal_accepted
,pcnfoidetails_pcn_foi_full.arrived_in_pound as pcn_arrived_in_pound
,pcnfoidetails_pcn_foi_full.cancellation_reversed as pcn_cancellation_reversed
,pcnfoidetails_pcn_foi_full.cc_printed as pcn_cc_printed
,pcnfoidetails_pcn_foi_full.drr as pcn_drr
,pcnfoidetails_pcn_foi_full.en_printed as pcn_en_printed
,pcnfoidetails_pcn_foi_full.hold_released as pcn_hold_released
,pcnfoidetails_pcn_foi_full.dvla_response as pcn_dvla_response
,pcnfoidetails_pcn_foi_full.dvla_request as pcn_dvla_request
,pcnfoidetails_pcn_foi_full.full_rate_uplift as pcn_full_rate_uplift
,pcnfoidetails_pcn_foi_full.hold_until as pcn_hold_until
,pcnfoidetails_pcn_foi_full.lifted_at as pcn_lifted_at
,pcnfoidetails_pcn_foi_full.lifted_by as pcn_lifted_by
,pcnfoidetails_pcn_foi_full.loaded as pcn_loaded
,pcnfoidetails_pcn_foi_full.nor_sent as pcn_nor_sent
,pcnfoidetails_pcn_foi_full.notice_held as pcn_notice_held
,pcnfoidetails_pcn_foi_full.ofr_printed as pcn_ofr_printed
,pcnfoidetails_pcn_foi_full.pcn_printed as pcn_pcn_printed
,pcnfoidetails_pcn_foi_full.reissue_nto_requested as pcn_reissue_nto_requested
,pcnfoidetails_pcn_foi_full.reissue_pcn as pcn_reissue_pcn
,pcnfoidetails_pcn_foi_full.set_back_to_pre_cc_stage as pcn_set_back_to_pre_cc_stage
,pcnfoidetails_pcn_foi_full.vehicle_released_for_auction as pcn_vehicle_released_for_auction
,pcnfoidetails_pcn_foi_full.warrant_issued as pcn_warrant_issued
,pcnfoidetails_pcn_foi_full.warrant_redistributed as pcn_warrant_redistributed
,pcnfoidetails_pcn_foi_full.warrant_request_granted as pcn_warrant_request_granted
,pcnfoidetails_pcn_foi_full.ad_hoc_vq4_request as pcn_ad_hoc_vq4_request
,pcnfoidetails_pcn_foi_full.paper_vq5_received as pcn_paper_vq5_received
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_buslane as pcn_pcn_extracted_for_buslane
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_pre_debt as pcn_pcn_extracted_for_pre_debt
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_collection as pcn_pcn_extracted_for_collection
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_drr as pcn_pcn_extracted_for_drr
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_cc as pcn_pcn_extracted_for_cc
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_nto as pcn_pcn_extracted_for_nto
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_print as pcn_pcn_extracted_for_print
,pcnfoidetails_pcn_foi_full.warning_notice_extracted_for_print as pcn_warning_notice_extracted_for_print
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_ofr as pcn_pcn_extracted_for_ofr
,pcnfoidetails_pcn_foi_full.pcn_extracted_for_warrant_request as pcn_pcn_extracted_for_warrant_request
,pcnfoidetails_pcn_foi_full.pre_debt_new_debtor_details as pcn_pre_debt_new_debtor_details
,pcnfoidetails_pcn_foi_full.importdattime as pcn_importdattime
,pcnfoidetails_pcn_foi_full.importdatetime as pcn_importdatetime
,pcnfoidetails_pcn_foi_full.import_year as pcn_import_year
,pcnfoidetails_pcn_foi_full.import_month as pcn_import_month
,pcnfoidetails_pcn_foi_full.import_day as pcn_import_day
,pcnfoidetails_pcn_foi_full.import_date as pcn_import_date
  FROM pcnfoidetails_pcn_foi_full
WHERE import_date = (SELECT max(import_date) from pcnfoidetails_pcn_foi_full)
   and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
order by cast(pcnfoidetails_pcn_foi_full.pcnissuedate as date) desc
--limit 100000
) SELECT parking_nas_live_manual_updates_data_load.*--, pcns.* ,pcns2.* ,pcns3.* 

,pcns.pcn_pcn as pcn1_pcn
,pcns.pcn_pcnissuedate as pcn1_pcnissuedate
,pcns.pcn_pcn_canx_date as pcn1_pcn_canx_date
,pcns.pcn_cancellationgroup as pcn1_cancellationgroup
,pcns.pcn_cancellationreason as pcn1_cancellationreason
,pcns.pcn_pcn_casecloseddate as pcn1_pcn_casecloseddate
,pcns.pcn_street_location as pcn1_street_location
,pcns.pcn_whereonlocation as pcn1_whereonlocation
,pcns.pcn_zone as pcn1_zone
,pcns.pcn_usrn as pcn1_usrn
,pcns.pcn_contraventioncode as pcn1_contraventioncode
,pcns.pcn_contraventionsuffix as pcn1_contraventionsuffix
,pcns.pcn_debttype as pcn1_debttype
,pcns.pcn_vrm as pcn1_vrm
,pcns.pcn_ceo as pcn1_ceo
,pcns.pcn_progressionstage as pcn1_progressionstage
,pcns.pcn_nextprogressionstage as pcn1_nextprogressionstage
,pcns.pcn_nextprogressionstagestarts as pcn1_nextprogressionstagestarts
,pcns.pcn_holdreason as pcn1_holdreason
,pcns.pcn_bailiff as pcn1_bailiff
,pcns.pcn_warrantissuedate as pcn1_warrantissuedate
,pcns.pcn_allocation as pcn1_allocation
,pcns.pcn_eta_datenotified as pcn1_eta_datenotified
,pcns.pcn_eta_packsubmittedon as pcn1_eta_packsubmittedon
,pcns.pcn_eta_evidencedate as pcn1_eta_evidencedate
,pcns.pcn_eta_adjudicationdate as pcn1_eta_adjudicationdate
,pcns.pcn_eta_appealgrounds as pcn1_eta_appealgrounds
,pcns.pcn_eta_decisionreceived as pcn1_eta_decisionreceived
,pcns.pcn_eta_outcome as pcn1_eta_outcome
,pcns.pcn_eta_packsubmittedby as pcn1_eta_packsubmittedby
,pcns.pcn_cancelledby as pcn1_cancelledby
,pcns.pcn_corresp_dispute_flag as pcn1_corresp_dispute_flag
,pcns.pcn_appeal_accepted as pcn1_appeal_accepted
,pcns.pcn_hold_released as pcn1_hold_released
,pcns.pcn_hold_until as pcn1_hold_until
,pcns.pcn_nor_sent as pcn1_nor_sent
,pcns.pcn_notice_held as pcn1_notice_held
,pcns.pcn_import_date


/*Multi PCNs records*/
--pcn2
,pcns2.pcn_pcn as pcn2_pcn
,pcns2.pcn_pcnissuedate as pcn2_pcnissuedate
,pcns2.pcn_pcn_canx_date as pcn2_pcn_canx_date
,pcns2.pcn_cancellationgroup as pcn2_cancellationgroup
,pcns2.pcn_cancellationreason as pcn2_cancellationreason
,pcns2.pcn_pcn_casecloseddate as pcn2_pcn_casecloseddate
,pcns2.pcn_street_location as pcn2_street_location
,pcns2.pcn_whereonlocation as pcn2_whereonlocation
,pcns2.pcn_zone as pcn2_zone
,pcns2.pcn_usrn as pcn2_usrn
,pcns2.pcn_contraventioncode as pcn2_contraventioncode
,pcns2.pcn_contraventionsuffix as pcn2_contraventionsuffix
,pcns2.pcn_debttype as pcn2_debttype
,pcns2.pcn_vrm as pcn2_vrm
,pcns2.pcn_ceo as pcn2_ceo
,pcns2.pcn_progressionstage as pcn2_progressionstage
,pcns2.pcn_nextprogressionstage as pcn2_nextprogressionstage
,pcns2.pcn_nextprogressionstagestarts as pcn2_nextprogressionstagestarts
,pcns2.pcn_holdreason as pcn2_holdreason
,pcns2.pcn_bailiff as pcn2_bailiff
,pcns2.pcn_warrantissuedate as pcn2_warrantissuedate
,pcns2.pcn_allocation as pcn2_allocation
,pcns2.pcn_eta_datenotified as pcn2_eta_datenotified
,pcns2.pcn_eta_packsubmittedon as pcn2_eta_packsubmittedon
,pcns2.pcn_eta_evidencedate as pcn2_eta_evidencedate
,pcns2.pcn_eta_adjudicationdate as pcn2_eta_adjudicationdate
,pcns2.pcn_eta_appealgrounds as pcn2_eta_appealgrounds
,pcns2.pcn_eta_decisionreceived as pcn2_eta_decisionreceived
,pcns2.pcn_eta_outcome as pcn2_eta_outcome
,pcns2.pcn_eta_packsubmittedby as pcn2_eta_packsubmittedby
,pcns2.pcn_cancelledby as pcn2_cancelledby
,pcns2.pcn_corresp_dispute_flag as pcn2_corresp_dispute_flag
,pcns2.pcn_appeal_accepted as pcn2_appeal_accepted
,pcns2.pcn_hold_released as pcn2_hold_released
,pcns2.pcn_hold_until as pcn2_hold_until
,pcns2.pcn_nor_sent as pcn2_nor_sent
,pcns2.pcn_notice_held as pcn2_notice_held

--pcn3
,pcns3.pcn_pcn as pcn3_pcn
,pcns3.pcn_pcnissuedate as pcn3_pcnissuedate
,pcns3.pcn_pcn_canx_date as pcn3_pcn_canx_date
,pcns3.pcn_cancellationgroup as pcn3_cancellationgroup
,pcns3.pcn_cancellationreason as pcn3_cancellationreason
,pcns3.pcn_pcn_casecloseddate as pcn3_pcn_casecloseddate
,pcns3.pcn_street_location as pcn3_street_location
,pcns3.pcn_whereonlocation as pcn3_whereonlocation
,pcns3.pcn_zone as pcn3_zone
,pcns3.pcn_usrn as pcn3_usrn
,pcns3.pcn_contraventioncode as pcn3_contraventioncode
,pcns3.pcn_contraventionsuffix as pcn3_contraventionsuffix
,pcns3.pcn_debttype as pcn3_debttype
,pcns3.pcn_vrm as pcn3_vrm
,pcns3.pcn_ceo as pcn3_ceo
,pcns3.pcn_progressionstage as pcn3_progressionstage
,pcns3.pcn_nextprogressionstage as pcn3_nextprogressionstage
,pcns3.pcn_nextprogressionstagestarts as pcn3_nextprogressionstagestarts
,pcns3.pcn_holdreason as pcn3_holdreason
,pcns3.pcn_bailiff as pcn3_bailiff
,pcns3.pcn_warrantissuedate as pcn3_warrantissuedate
,pcns3.pcn_allocation as pcn3_allocation
,pcns3.pcn_eta_datenotified as pcn3_eta_datenotified
,pcns3.pcn_eta_packsubmittedon as pcn3_eta_packsubmittedon
,pcns3.pcn_eta_evidencedate as pcn3_eta_evidencedate
,pcns3.pcn_eta_adjudicationdate as pcn3_eta_adjudicationdate
,pcns3.pcn_eta_appealgrounds as pcn3_eta_appealgrounds
,pcns3.pcn_eta_decisionreceived as pcn3_eta_decisionreceived
,pcns3.pcn_eta_outcome as pcn3_eta_outcome
,pcns3.pcn_eta_packsubmittedby as pcn3_eta_packsubmittedby
,pcns3.pcn_cancelledby as pcn3_cancelledby
,pcns3.pcn_corresp_dispute_flag as pcn3_corresp_dispute_flag
,pcns3.pcn_appeal_accepted as pcn3_appeal_accepted
,pcns3.pcn_hold_released as pcn3_hold_released
,pcns3.pcn_hold_until as pcn3_hold_until
,pcns3.pcn_nor_sent as pcn3_nor_sent
,pcns3.pcn_notice_held as pcn3_notice_held

--pcn4
,pcns4.pcn_pcn as pcn4_pcn
,pcns4.pcn_pcnissuedate as pcn4_pcnissuedate
,pcns4.pcn_pcn_canx_date as pcn4_pcn_canx_date
,pcns4.pcn_cancellationgroup as pcn4_cancellationgroup
,pcns4.pcn_cancellationreason as pcn4_cancellationreason
,pcns4.pcn_pcn_casecloseddate as pcn4_pcn_casecloseddate
,pcns4.pcn_street_location as pcn4_street_location
,pcns4.pcn_whereonlocation as pcn4_whereonlocation
,pcns4.pcn_zone as pcn4_zone
,pcns4.pcn_usrn as pcn4_usrn
,pcns4.pcn_contraventioncode as pcn4_contraventioncode
,pcns4.pcn_contraventionsuffix as pcn4_contraventionsuffix
,pcns4.pcn_debttype as pcn4_debttype
,pcns4.pcn_vrm as pcn4_vrm
,pcns4.pcn_ceo as pcn4_ceo
,pcns4.pcn_progressionstage as pcn4_progressionstage
,pcns4.pcn_nextprogressionstage as pcn4_nextprogressionstage
,pcns4.pcn_nextprogressionstagestarts as pcn4_nextprogressionstagestarts
,pcns4.pcn_holdreason as pcn4_holdreason
,pcns4.pcn_bailiff as pcn4_bailiff
,pcns4.pcn_warrantissuedate as pcn4_warrantissuedate
,pcns4.pcn_allocation as pcn4_allocation
,pcns4.pcn_eta_datenotified as pcn4_eta_datenotified
,pcns4.pcn_eta_packsubmittedon as pcn4_eta_packsubmittedon
,pcns4.pcn_eta_evidencedate as pcn4_eta_evidencedate
,pcns4.pcn_eta_adjudicationdate as pcn4_eta_adjudicationdate
,pcns4.pcn_eta_appealgrounds as pcn4_eta_appealgrounds
,pcns4.pcn_eta_decisionreceived as pcn4_eta_decisionreceived
,pcns4.pcn_eta_outcome as pcn4_eta_outcome
,pcns4.pcn_eta_packsubmittedby as pcn4_eta_packsubmittedby
,pcns4.pcn_cancelledby as pcn4_cancelledby
,pcns4.pcn_corresp_dispute_flag as pcn4_corresp_dispute_flag
,pcns4.pcn_appeal_accepted as pcn4_appeal_accepted
,pcns4.pcn_hold_released as pcn4_hold_released
,pcns4.pcn_hold_until as pcn4_hold_until
,pcns4.pcn_nor_sent as pcn4_nor_sent
,pcns4.pcn_notice_held as pcn4_notice_held

--pcn5
,pcns5.pcn_pcn as pcn5_pcn
,pcns5.pcn_pcnissuedate as pcn5_pcnissuedate
,pcns5.pcn_pcn_canx_date as pcn5_pcn_canx_date
,pcns5.pcn_cancellationgroup as pcn5_cancellationgroup
,pcns5.pcn_cancellationreason as pcn5_cancellationreason
,pcns5.pcn_pcn_casecloseddate as pcn5_pcn_casecloseddate
,pcns5.pcn_street_location as pcn5_street_location
,pcns5.pcn_whereonlocation as pcn5_whereonlocation
,pcns5.pcn_zone as pcn5_zone
,pcns5.pcn_usrn as pcn5_usrn
,pcns5.pcn_contraventioncode as pcn5_contraventioncode
,pcns5.pcn_contraventionsuffix as pcn5_contraventionsuffix
,pcns5.pcn_debttype as pcn5_debttype
,pcns5.pcn_vrm as pcn5_vrm
,pcns5.pcn_ceo as pcn5_ceo
,pcns5.pcn_progressionstage as pcn5_progressionstage
,pcns5.pcn_nextprogressionstage as pcn5_nextprogressionstage
,pcns5.pcn_nextprogressionstagestarts as pcn5_nextprogressionstagestarts
,pcns5.pcn_holdreason as pcn5_holdreason
,pcns5.pcn_bailiff as pcn5_bailiff
,pcns5.pcn_warrantissuedate as pcn5_warrantissuedate
,pcns5.pcn_allocation as pcn5_allocation
,pcns5.pcn_eta_datenotified as pcn5_eta_datenotified
,pcns5.pcn_eta_packsubmittedon as pcn5_eta_packsubmittedon
,pcns5.pcn_eta_evidencedate as pcn5_eta_evidencedate
,pcns5.pcn_eta_adjudicationdate as pcn5_eta_adjudicationdate
,pcns5.pcn_eta_appealgrounds as pcn5_eta_appealgrounds
,pcns5.pcn_eta_decisionreceived as pcn5_eta_decisionreceived
,pcns5.pcn_eta_outcome as pcn5_eta_outcome
,pcns5.pcn_eta_packsubmittedby as pcn5_eta_packsubmittedby
,pcns5.pcn_cancelledby as pcn5_cancelledby
,pcns5.pcn_corresp_dispute_flag as pcn5_corresp_dispute_flag
,pcns5.pcn_appeal_accepted as pcn5_appeal_accepted
,pcns5.pcn_hold_released as pcn5_hold_released
,pcns5.pcn_hold_until as pcn5_hold_until
,pcns5.pcn_nor_sent as pcn5_nor_sent
,pcns5.pcn_notice_held as pcn5_notice_held

--pcn6
,pcns6.pcn_pcn as pcn6_pcn
,pcns6.pcn_pcnissuedate as pcn6_pcnissuedate
,pcns6.pcn_pcn_canx_date as pcn6_pcn_canx_date
,pcns6.pcn_cancellationgroup as pcn6_cancellationgroup
,pcns6.pcn_cancellationreason as pcn6_cancellationreason
,pcns6.pcn_pcn_casecloseddate as pcn6_pcn_casecloseddate
,pcns6.pcn_street_location as pcn6_street_location
,pcns6.pcn_whereonlocation as pcn6_whereonlocation
,pcns6.pcn_zone as pcn6_zone
,pcns6.pcn_usrn as pcn6_usrn
,pcns6.pcn_contraventioncode as pcn6_contraventioncode
,pcns6.pcn_contraventionsuffix as pcn6_contraventionsuffix
,pcns6.pcn_debttype as pcn6_debttype
,pcns6.pcn_vrm as pcn6_vrm
,pcns6.pcn_ceo as pcn6_ceo
,pcns6.pcn_progressionstage as pcn6_progressionstage
,pcns6.pcn_nextprogressionstage as pcn6_nextprogressionstage
,pcns6.pcn_nextprogressionstagestarts as pcn6_nextprogressionstagestarts
,pcns6.pcn_holdreason as pcn6_holdreason
,pcns6.pcn_bailiff as pcn6_bailiff
,pcns6.pcn_warrantissuedate as pcn6_warrantissuedate
,pcns6.pcn_allocation as pcn6_allocation
,pcns6.pcn_eta_datenotified as pcn6_eta_datenotified
,pcns6.pcn_eta_packsubmittedon as pcn6_eta_packsubmittedon
,pcns6.pcn_eta_evidencedate as pcn6_eta_evidencedate
,pcns6.pcn_eta_adjudicationdate as pcn6_eta_adjudicationdate
,pcns6.pcn_eta_appealgrounds as pcn6_eta_appealgrounds
,pcns6.pcn_eta_decisionreceived as pcn6_eta_decisionreceived
,pcns6.pcn_eta_outcome as pcn6_eta_outcome
,pcns6.pcn_eta_packsubmittedby as pcn6_eta_packsubmittedby
,pcns6.pcn_cancelledby as pcn6_cancelledby
,pcns6.pcn_corresp_dispute_flag as pcn6_corresp_dispute_flag
,pcns6.pcn_appeal_accepted as pcn6_appeal_accepted
,pcns6.pcn_hold_released as pcn6_hold_released
,pcns6.pcn_hold_until as pcn6_hold_until
,pcns6.pcn_nor_sent as pcn6_nor_sent
,pcns6.pcn_notice_held as pcn6_notice_held

--pcn7
,pcns7.pcn_pcn as pcn7_pcn
,pcns7.pcn_pcnissuedate as pcn7_pcnissuedate
,pcns7.pcn_pcn_canx_date as pcn7_pcn_canx_date
,pcns7.pcn_cancellationgroup as pcn7_cancellationgroup
,pcns7.pcn_cancellationreason as pcn7_cancellationreason
,pcns7.pcn_pcn_casecloseddate as pcn7_pcn_casecloseddate
,pcns7.pcn_street_location as pcn7_street_location
,pcns7.pcn_whereonlocation as pcn7_whereonlocation
,pcns7.pcn_zone as pcn7_zone
,pcns7.pcn_usrn as pcn7_usrn
,pcns7.pcn_contraventioncode as pcn7_contraventioncode
,pcns7.pcn_contraventionsuffix as pcn7_contraventionsuffix
,pcns7.pcn_debttype as pcn7_debttype
,pcns7.pcn_vrm as pcn7_vrm
,pcns7.pcn_ceo as pcn7_ceo
,pcns7.pcn_progressionstage as pcn7_progressionstage
,pcns7.pcn_nextprogressionstage as pcn7_nextprogressionstage
,pcns7.pcn_nextprogressionstagestarts as pcn7_nextprogressionstagestarts
,pcns7.pcn_holdreason as pcn7_holdreason
,pcns7.pcn_bailiff as pcn7_bailiff
,pcns7.pcn_warrantissuedate as pcn7_warrantissuedate
,pcns7.pcn_allocation as pcn7_allocation
,pcns7.pcn_eta_datenotified as pcn7_eta_datenotified
,pcns7.pcn_eta_packsubmittedon as pcn7_eta_packsubmittedon
,pcns7.pcn_eta_evidencedate as pcn7_eta_evidencedate
,pcns7.pcn_eta_adjudicationdate as pcn7_eta_adjudicationdate
,pcns7.pcn_eta_appealgrounds as pcn7_eta_appealgrounds
,pcns7.pcn_eta_decisionreceived as pcn7_eta_decisionreceived
,pcns7.pcn_eta_outcome as pcn7_eta_outcome
,pcns7.pcn_eta_packsubmittedby as pcn7_eta_packsubmittedby
,pcns7.pcn_cancelledby as pcn7_cancelledby
,pcns7.pcn_corresp_dispute_flag as pcn7_corresp_dispute_flag
,pcns7.pcn_appeal_accepted as pcn7_appeal_accepted
,pcns7.pcn_hold_released as pcn7_hold_released
,pcns7.pcn_hold_until as pcn7_hold_until
,pcns7.pcn_nor_sent as pcn7_nor_sent
,pcns7.pcn_notice_held as pcn7_notice_held

--pcn8
,pcns8.pcn_pcn as pcn8_pcn
,pcns8.pcn_pcnissuedate as pcn8_pcnissuedate
,pcns8.pcn_pcn_canx_date as pcn8_pcn_canx_date
,pcns8.pcn_cancellationgroup as pcn8_cancellationgroup
,pcns8.pcn_cancellationreason as pcn8_cancellationreason
,pcns8.pcn_pcn_casecloseddate as pcn8_pcn_casecloseddate
,pcns8.pcn_street_location as pcn8_street_location
,pcns8.pcn_whereonlocation as pcn8_whereonlocation
,pcns8.pcn_zone as pcn8_zone
,pcns8.pcn_usrn as pcn8_usrn
,pcns8.pcn_contraventioncode as pcn8_contraventioncode
,pcns8.pcn_contraventionsuffix as pcn8_contraventionsuffix
,pcns8.pcn_debttype as pcn8_debttype
,pcns8.pcn_vrm as pcn8_vrm
,pcns8.pcn_ceo as pcn8_ceo
,pcns8.pcn_progressionstage as pcn8_progressionstage
,pcns8.pcn_nextprogressionstage as pcn8_nextprogressionstage
,pcns8.pcn_nextprogressionstagestarts as pcn8_nextprogressionstagestarts
,pcns8.pcn_holdreason as pcn8_holdreason
,pcns8.pcn_bailiff as pcn8_bailiff
,pcns8.pcn_warrantissuedate as pcn8_warrantissuedate
,pcns8.pcn_allocation as pcn8_allocation
,pcns8.pcn_eta_datenotified as pcn8_eta_datenotified
,pcns8.pcn_eta_packsubmittedon as pcn8_eta_packsubmittedon
,pcns8.pcn_eta_evidencedate as pcn8_eta_evidencedate
,pcns8.pcn_eta_adjudicationdate as pcn8_eta_adjudicationdate
,pcns8.pcn_eta_appealgrounds as pcn8_eta_appealgrounds
,pcns8.pcn_eta_decisionreceived as pcn8_eta_decisionreceived
,pcns8.pcn_eta_outcome as pcn8_eta_outcome
,pcns8.pcn_eta_packsubmittedby as pcn8_eta_packsubmittedby
,pcns8.pcn_cancelledby as pcn8_cancelledby
,pcns8.pcn_corresp_dispute_flag as pcn8_corresp_dispute_flag
,pcns8.pcn_appeal_accepted as pcn8_appeal_accepted
,pcns8.pcn_hold_released as pcn8_hold_released
,pcns8.pcn_hold_until as pcn8_hold_until
,pcns8.pcn_nor_sent as pcn8_nor_sent
,pcns8.pcn_notice_held as pcn8_notice_held

--pcn9
,pcns9.pcn_pcn as pcn9_pcn
,pcns9.pcn_pcnissuedate as pcn9_pcnissuedate
,pcns9.pcn_pcn_canx_date as pcn9_pcn_canx_date
,pcns9.pcn_cancellationgroup as pcn9_cancellationgroup
,pcns9.pcn_cancellationreason as pcn9_cancellationreason
,pcns9.pcn_pcn_casecloseddate as pcn9_pcn_casecloseddate
,pcns9.pcn_street_location as pcn9_street_location
,pcns9.pcn_whereonlocation as pcn9_whereonlocation
,pcns9.pcn_zone as pcn9_zone
,pcns9.pcn_usrn as pcn9_usrn
,pcns9.pcn_contraventioncode as pcn9_contraventioncode
,pcns9.pcn_contraventionsuffix as pcn9_contraventionsuffix
,pcns9.pcn_debttype as pcn9_debttype
,pcns9.pcn_vrm as pcn9_vrm
,pcns9.pcn_ceo as pcn9_ceo
,pcns9.pcn_progressionstage as pcn9_progressionstage
,pcns9.pcn_nextprogressionstage as pcn9_nextprogressionstage
,pcns9.pcn_nextprogressionstagestarts as pcn9_nextprogressionstagestarts
,pcns9.pcn_holdreason as pcn9_holdreason
,pcns9.pcn_bailiff as pcn9_bailiff
,pcns9.pcn_warrantissuedate as pcn9_warrantissuedate
,pcns9.pcn_allocation as pcn9_allocation
,pcns9.pcn_eta_datenotified as pcn9_eta_datenotified
,pcns9.pcn_eta_packsubmittedon as pcn9_eta_packsubmittedon
,pcns9.pcn_eta_evidencedate as pcn9_eta_evidencedate
,pcns9.pcn_eta_adjudicationdate as pcn9_eta_adjudicationdate
,pcns9.pcn_eta_appealgrounds as pcn9_eta_appealgrounds
,pcns9.pcn_eta_decisionreceived as pcn9_eta_decisionreceived
,pcns9.pcn_eta_outcome as pcn9_eta_outcome
,pcns9.pcn_eta_packsubmittedby as pcn9_eta_packsubmittedby
,pcns9.pcn_cancelledby as pcn9_cancelledby
,pcns9.pcn_corresp_dispute_flag as pcn9_corresp_dispute_flag
,pcns9.pcn_appeal_accepted as pcn9_appeal_accepted
,pcns9.pcn_hold_released as pcn9_hold_released
,pcns9.pcn_hold_until as pcn9_hold_until
,pcns9.pcn_nor_sent as pcn9_nor_sent
,pcns9.pcn_notice_held as pcn9_notice_held



FROM parking_nas_live_manual_updates_data_load
left join pcns on parking_nas_live_manual_updates_data_load.pcn = pcns.pcn_pcn
left join pcns pcns2 on parking_nas_live_manual_updates_data_load.pcn_2 = pcns2.pcn_pcn
left join pcns pcns3 on parking_nas_live_manual_updates_data_load.pcn_3 = pcns3.pcn_pcn
left join pcns pcns4 on parking_nas_live_manual_updates_data_load.pcn_4 = pcns4.pcn_pcn
left join pcns pcns5 on parking_nas_live_manual_updates_data_load.pcn_5 = pcns5.pcn_pcn
left join pcns pcns6 on parking_nas_live_manual_updates_data_load.pcn_6 = pcns6.pcn_pcn
left join pcns pcns7 on parking_nas_live_manual_updates_data_load.pcn_7 = pcns7.pcn_pcn
left join pcns pcns8 on parking_nas_live_manual_updates_data_load.pcn_8 = pcns8.pcn_pcn
left join pcns pcns9 on parking_nas_live_manual_updates_data_load.pcn_9 = pcns9.pcn_pcn

WHERE import_date = (SELECT max(import_date) from parking_nas_live_manual_updates_data_load)
order by parking_nas_live_manual_updates_data_load.timestamp desc
'''
SQLQuery_node1716380336388 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"pcnfoidetails_pcn_foi_full":LiberatorRefinedpcnfoidetails_pcn_foi_full_node1716380330290, "parking_nas_live_manual_updates_data_load":parking_raw_zoneparking_nas_live_manual_updates_data_load_node1716380310939}, transformation_ctx = "SQLQuery_node1716380336388")

# Script generated for node Amazon S3
AmazonS3_node1716380345114 = glueContext.getSink(path=f"s3://dataplatform-{environment}-refined-zone/parking/liberator/parking_nas_live_manual_updates_data_load_with_pcns/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=["import_year", "import_month", "import_day", "import_date"], enableUpdateCatalog=True, transformation_ctx="AmazonS3_node1716380345114")
AmazonS3_node1716380345114.setCatalogInfo(catalogDatabase="parking-refined-zone",catalogTableName="parking_nas_live_manual_updates_data_load_with_pcns")
AmazonS3_node1716380345114.setFormat("glueparquet", compression="snappy")
AmazonS3_node1716380345114.writeFrame(SQLQuery_node1716380336388)
job.commit()
