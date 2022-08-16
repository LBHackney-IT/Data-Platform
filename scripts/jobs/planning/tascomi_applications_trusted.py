"""This job reads daily planning apps snapshot from the refined zone and transforms it into a user-friendly version in
the trusted zone ready for use by Qlik and data analysts.

The job can be run in local mode (i.e. on your local environment) and also on AWS (see Usage below).

Usage:
To run in local mode:
set the mode to 'local' and provide the path of data set of your local machine
--execution_mode=local
--applications_data_path=<test_data/applications/>
--application_types_data_path=<test_data/application_types/>
--ps_development_codes_data_path=<test_data/ps_development_codes/>
--target_destination"=<local_output_folder>

To run in AWS mode:
No need to provide mode (or optionally set it to 'aws')
--source_catalog_table = <applications table>
--source_catalog_table2
--source_catalog_table3
--source_catalog_database
--target_destination
"""

import argparse
import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import *
import pyspark.sql.functions as F

from scripts.jobs.env_context import ExecutionContextProvider, DEFAULT_MODE_AWS, LOCAL_MODE
from scripts.helpers.helpers import create_pushdown_predicate, PARTITION_KEYS_SNAPSHOT, working_days_diff


# Define the functions that will be used in your job (optional).
# For Production jobs, these functions should be tested via unit testing.


def get_latest_snapshot(df):
    df = df.where(F.col('snapshot_date') == df.select(max('snapshot_date')).first()[0])
    return df


# Creates a function that clears the target folder in S3
def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName + '/', '') + '/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return


columns_to_delete_from_apps_table = (
    'access_hardstand_existing',
    'access_hardstand_proposed',
    'certificate_c_signed_by',
    'certificate_c_signed_on',
    'decision_monitoring_standard_phrase_id',
    'doors_existing',
    'doors_existing_details',
    'doors_proposed',
    'doors_proposed_details',
    'explanation_for_proposal',
    'grounds_for_the_certificate',
    'ldp_site_details',
    'other_existing',
    'other_owner_details',
    'other_proposed',
    'other_total_existing',
    'other_total_proposed',
    'referral_reason_id',
    'relationship_details',
    'temporary_consent_months',
    'walls_existing',
    'walls_existing_details',
    'walls_proposed',
    'walls_proposed_details',
    'windows_proposed',
    'windows_proposed_details',
    'affordable_housing_balancing_sum',
    'certificate_of_immunity',
    'current_building_use_details',
    'expiry_of_temporary_consent_use_operations',
    'extension_description',
    'legal_draft_received_date',
    'proposed_development_description',
    'agricultural_holding_involved_signed_on',
    'legal_services_instructed_date',
    'motorcycles_total_existing',
    'motorcycles_total_proposed',
    'non_agricultural_holding_signed_on',
    'overturn_reason_id',
    'temporary_consent_years',
    'agricultural_holding_involved_signed_by',
    'approved_units',
    'non_agricultural_holding_signed_by',
    'site_visit_other_contact',
    'tree_location_description',
    'ian_deadline_date',
    'lbc_chimney_existing',
    'lbc_chimney_existing_details',
    'lbc_chimney_proposed',
    'lbc_chimney_proposed_details',
    'lgv_total_proposed',
    'requested_committee_meeting_id',
    'lgv_total_existing',
    'agricultural_holdings',
    'hoardings',
    'referral_returned_date',
    'disability_total_existing',
    'lbc_internal_doors_existing',
    'lbc_internal_doors_existing_details',
    'lbc_internal_doors_proposed',
    'lbc_internal_doors_proposed_details',
    'lbc_ceilings_existing',
    'lbc_ceilings_existing_details',
    'lbc_ceilings_proposed',
    'lbc_ceilings_proposed_details',
    'tpo_title',
    'lbc_floors_existing',
    'lbc_floors_existing_details',
    'lbc_floors_proposed',
    'lbc_floors_proposed_details',
    'certificate_b_owner_notified',
    'certificate_b_signed_by',
    'certificate_b_signed_on',
    'expected_legal_agreement_sum',
    'referral_date',
    'lbc_external_doors_existing_details',
    'lbc_external_doors_proposed',
    'lbc_external_doors_proposed_details',
    'committee_actual_date',
    'lbc_internal_walls_existing',
    'lbc_internal_walls_existing_details',
    'lbc_internal_walls_proposed',
    'lbc_internal_walls_proposed_details',
    'expected_community_infrastructure_levy_sum',
    'consultation_details',
    'disability_total_proposed',
    'detailed_description_of_existing_apparatus',
    'detailed_description_of_porposed_apparatus',
    'type_of_apparatus',
    'lpa_planning_application_reference',
    'justification_for_tree_works',
    'full_details_of_trees_and_proposed_works',
    'lbc_external_walls_existing_details',
    'lbc_external_walls_proposed',
    'lbc_external_walls_proposed_details',
    'lbc_external_doors_existing',
    'committee_proposed_date',
    'certificate_a_signed_by',
    'certificate_a_signed_on',
    'cycle_total_existing',
    'end_of_previous_use',
    'existing_employees_part_time',
    'projecting_or_hanging_signs',
    'proposed_employees_part_time',
    'fascia_signs',
    'advert_drawing_references',
    'application_source_id',
    'waste_storage_collection_details',
    'recycling_storage_collection_details',
    'proposed_employees_full_time',
    'existing_employees_full_time',
    'return_as_invalid_reason',
    'work_completed_date',
    'lighting_existing_details',
    'lighting_existing',
    'justification_for_removal',
    'variance_to_condition_requested',
    'lighting_proposed_details',
    'lighting_proposed',
    'advertisement_from',
    'advertisement_to',
    'consultation_not_applicable_reason',
    'use_works_activity_date',
    'car_total_proposed',
    'advert_description',
    'advert_details_of_work_start',
    'other_signs_details',
    'reason_for_no_permission',
    'car_total_existing',
    'site_address_y',
    'site_address_x',
    'justification',
    'new_plans_or_drawings_references',
    'old_plans_or_drawings_references',
    'proposed_amendment',
    'alteration_references',
    'description_of_demolition',
    'justification_of_demolition_extension',
    'lbc_materials_plan_references',
    'work_started_date',
    'cycle_total_proposed',
    'documents_to_legal_date',
    'service_centre_id',
    'legal_agreement_date',
    'boundaries_existing',
    'boundaries_existing_details',
    'boundaries_proposed',
    'boundaries_proposed_details',
    'pre_application_reference',
    'description',
    'interruption_details',
    'ldce_justification',
    'material_change_of_use_details',
    'other_grounds',
    'description_dates_of_existing_last_known_use',
    'detailed_description_building_operations',
    'detailed_description_of_use_change',
    'date_of_advice',
    'legal_agreement_obligation_type_id',
    'discharge_details',
    'partial_discharge_details',
    'roof_existing',
    'roof_existing_details',
    'plan_drawing_refs_as_applicable',
    'plan_drawing_refs_as_applicable_inc_scale',
    'validation_officer_id',
    'roof_proposed',
    'roof_proposed_details',
    'existing_employees_full_time_equivalent',
    'proposed_employees_full_time_equivalent',
    'community_id',
    'windows_existing',
    'windows_existing_details',
    'description_of_naturevolume_method_of_disposal',
    'validation_notes',
    'cycle_difference',
    'car_difference',
    'disability_difference',
    'lgv_difference',
    'motorcycles_difference',
    'other_difference',
    'sewage_applicable_drawing_references',
    'current_use_s_',
    'prow_applicable_drawing_references',
    'materials_plan_references',
    'decision_user_team_id',
    'neighbours_dtf_location_id_json',
    'neighbours_geom',
    'certificate_c_notification_steps',
    'certificate_d_notification_steps',
    'decision_officer_id',
    'decision_expiry_years',
    'linguistic_impact_assessment_required',
    'viability_challenge',
    'site_visit_please_contact',
    'advice_description',
    'application_declaration_signed_on',
    'application_declaration_signed_by',
    'feature_info_data_json',
    'dtf_location_id_json',
    'admin_officer_id',
    'submit_date',
    'creation_user_id',
    'previous_excavations_deposits_area',
    'previous_total_cou_floorspace_m2',
    'previous_total_cou_floorspace_m2_4acd',
    'previous_total_cou_floorspace_m2_4sca',
    'proposed_area_of_unit',
    'proposed_cou_floorspace_m2',
    'proposed_road_dimensions_length',
    'proposed_road_dimensions_width',
    'proposed_total_cou_floorspace_m2',
    'proposed_total_cou_floorspace_m2_4sca',
    'quantity_m3',
    'refined_white_sugar_tonnes_',
    'site_area_gis',
    'site_area_proposed_for_cou_ha',
    'size_of_holding',
    'social_housing_existing_gross_int_floorspace',
    'social_housing_gross_int_floorspace_lost',
    'social_housing_total_gross_floorspace_proposed',
    'solar',
    'sulphur_dioxide_tonnes_',
    'surface_area_ha',
    'surface_site_area_ha',
    'total_cou_floorspace_m2',
    'total_fee',
    'total_non_residential_existing_gross_int_floorspace',
    'total_non_residential_gross_int_floorspace_lost',
    'total_non_residential_total_gross_floorspace_proposed',
    'total_residential_existing_gross_int_floorspace',
    'total_residential_gross_int_floorspace_lost',
    'total_residential_total_gross_floorspace_proposed',
    'waste_heat_energy',
    'wind',
    'a_rear_projection_m',
    'acrylonitrile_tonnes_',
    'ammonia_tonnes_',
    'amount_of_open_space_gained',
    'amount_of_open_space_lost',
    'anaerobic_digestion',
    'approximate_total_volume_m3',
    'b_ridge_height_m',
    'biofuels',
    'biomass',
    'bromine_tonnes_',
    'brownfield_greenfield_greenfield_land',
    'brownfield_greenfield_previously_developed_land',
    'c_eaves_height_m',
    'c1_flood_plain_risks_non_residential_units',
    'c1_flood_plain_risks_residential_units',
    'c2_flood_plain_risks_non_residential_units',
    'c2_flood_plain_risks_residential_units',
    'chlorine_tonnes_',
    'combined_heat_and_power',
    'commercial_and_industrial_throughput',
    'construction_demolition_and_excavation_throughput',
    'cumulative_cou_floorspace_m2',
    'depth_height_of_excavation_landfilling_landraising',
    'district_heating',
    'ethylene_oxide_tonnes_',
    'excavation_proposed_area_of_work',
    'flat_roof_projection_m',
    'floor_area',
    'floorspace_proposed_for_cou_m2',
    'floorspace_where_cou_proposed_m2',
    'flour_tonnes_',
    'fuel_cells',
    'geothermal',
    'gross_floor_space_m2',
    'gross_floorspace_m2',
    'gross_floorspace_m2_4acd',
    'ground_water_air_heat_pumps',
    'hazardous',
    'hydrogen_cyanide_tonnes_',
    'hydropower',
    'length_of_hedgerow_removal',
    'liquid_oxygen_tonnes_',
    'liquid_petroleum_gas_tonnes_',
    'market_housing_existing_gross_int_floorspace',
    'market_housing_gross_int_floorspace_lost',
    'market_housing_total_gross_floorspace_proposed',
    'maximum_height_m',
    'municipal_throughput',
    'number_of_holding',
    'other_renewable_low_carbon_energy_capacity',
    'other_tonnes_',
    'phosgene_tonnes_',
    'pitched_roof_projection_m',
    'last_updated_by',
    'eia_id')

# Create Dictionary for mappings - similar to mapping load in Qlik

mapStage = {
    '1': '1: RECEIPT/RECEIVED',
    '2': '2: INVALID/INCOMPLETE',
    '3': '3: VALID/COMPLETE',
    '4': '4: CONSULTATION/PUBLICITY',
    '5': '5: CONSULATION COMPLETE',
    '6': '6: ASSESSMENT',
    '7': '7: RECOMMENDATION',
    '8': '8: COMMITTEE',
    '9': '9: DETERMINATION REFERRED',
    '10': '10: DECISION ISSUED',
    '11': '11: UNDER APPEAL'}

CONST_NAME = "No Reg. on Stat Returns"

mapDev = {
    '(E)Major Development (TDC)': 'Other',
    '(E)Minor (Housing-Led) (PIP)': 'Other',
    '(E)Minor (Housing-Led) (TDC)': 'Other',
    '(E)Minor Gypsy and Traveller sites development': 'Minor',
    '(E)Relevant Demolition In A Conservation Area (Other)': 'Other',
    'Advertisements': 'Other',
    'All Others': CONST_NAME,
    'Certificate of Lawful Development': CONST_NAME,
    'Certificates of Appropriate Alternative Development': CONST_NAME,
    'Certificates of Lawfuless of Proposed Works to Listed Buildings': CONST_NAME,
    'Change of use': 'Other',
    'Conservation Area Consents': 'Other',
    'Extended construction hours': CONST_NAME,
    'Householder': 'Other',
    'Larger Household Extensions': CONST_NAME,
    'Listed Building Alterations': 'Other',
    'Listed Building Consent to Demolish': 'Other',
    'Major Dwellings': 'Major',
    'Major Gypsy and Traveller sites development': 'Major',
    'Major Industrial': 'Major',
    'Major Office': 'Major',
    'Major Retail': 'Major',
    'Minerals': 'Other',
    'Minor Industrial': 'Minor',
    'Minor Office': 'Minor',
    'Minor Residential': 'Minor',
    'Minor Retail': 'Minor',
    'Non-Material Amendments': CONST_NAME,
    'Not Required On Statutory Returns': CONST_NAME,
    'Notifications': CONST_NAME,
    'Office to Residential': 'Other',
    'Other Major Developments': 'Major',
    'Other Minor Developments': 'Minor',
    'Prior notification - new dwellings': CONST_NAME,
    'Retail and Sui Generis Uses to Residential': CONST_NAME,
    'Storage or Distribution Centres to Residential': CONST_NAME,
    'To State-Funded School or Registered Nursery': CONST_NAME}


# The main function
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=local to run locally")
    parser.add_argument(f"--applications_data_path", type=str, required=False,
                        metavar=f"set --applications_data_path=/path/to/directory/containing source applications data to run locally")
    parser.add_argument(f"--application_types_data_path", type=str, required=False,
                        metavar=f"set --application_types_data_path=/path/to/directory/containing source application_types data to run locally")
    parser.add_argument(f"--ps_development_codes_data_path", type=str, required=False,
                        metavar=f"set --ps_development_codes_data_path=/path/to/directory/containing source ps_development_codes data to run locally")
    parser.add_argument(f"--target_destination", type=str, required=False,
                        metavar=f"set --target_destination=/path/to/output_folder")

    applications_data_path_local_arg = "applications_data_path"  # planning applications data path
    application_types_data_path_local_arg = "application_types_data_path"  # planning applications types data path
    ps_development_codes_data_path_local_arg = "ps_development_codes_data_path"  # ps_codes types data path

    source_catalog_table_glue_arg = "source_catalog_table"  # planning applications table name
    source_catalog_table2_glue_arg = "source_catalog_table2"  # planning applications types table name
    source_catalog_table3_glue_arg = "source_catalog_table3"  # ps_codes table name
    source_catalog_database_glue_arg = "source_catalog_database"  # source database name

    target_destination_arg = "target_destination"  # output location (S3 path or local)

    glue_args = [source_catalog_table_glue_arg, source_catalog_table2_glue_arg,
                 source_catalog_table3_glue_arg, source_catalog_database_glue_arg, target_destination_arg]
    local_args, _ = parser.parse_known_args()
    execution_mode = local_args.execution_mode

    with ExecutionContextProvider(execution_mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        target_destination = execution_context.get_input_args(target_destination_arg)
        if not target_destination:
            logger.error("target_destination is empty")
            raise ValueError("target_destination cannot be empty")

        # read job parameters

        applications_data_path_local = execution_context.get_input_args(applications_data_path_local_arg)
        source_catalog_table = execution_context.get_input_args(source_catalog_table_glue_arg)

        application_types_data_path_local = execution_context.get_input_args(application_types_data_path_local_arg)
        source_catalog_table2 = execution_context.get_input_args(source_catalog_table2_glue_arg)

        ps_development_codes_data_path_local = execution_context.get_input_args(
            ps_development_codes_data_path_local_arg)
        source_catalog_table3 = execution_context.get_input_args(source_catalog_table3_glue_arg)
        source_catalog_database = execution_context.get_input_args(source_catalog_database_glue_arg)

        # Log something. This will be output in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
        logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')
        logger.info(f'execution mode = {execution_mode}')

        # Load data from glue catalog
        df = execution_context \
            .get_dataframe(local_path_parquet=applications_data_path_local,
                           name_space=source_catalog_database,
                           table_name=source_catalog_table,
                           push_down_predicate=create_pushdown_predicate('snapshot_date', 3))

        # Data processing Starts

        # If the source data IS partitionned by import_date, you have loaded several days but only need
        # the latest version, use the get_latest_partitions() helper
        df = get_latest_snapshot(df)

        # Drop Columns we know are not needed by Qlik
        df = df.drop(*columns_to_delete_from_apps_table)

        # Rename id column
        df = df.withColumnRenamed("id", "application_id")

        # Create Calculated Fields for Reporting Measures

        # Date Calculations
        df = df.withColumn('day_of_week', F.dayofweek(F.col('decision_issued_date'))) \
            .selectExpr('*', 'date_sub(decision_issued_date, day_of_week-2) as decision_report_week') \
            .withColumn('day_of_week', F.dayofweek(F.col('registration_date'))) \
            .selectExpr('*', 'date_sub(registration_date, day_of_week-2) as registration_report_week') \
            .withColumn('day_of_week', F.dayofweek(F.col('received_date'))) \
            .selectExpr('*', 'date_sub(received_date, day_of_week-2) as received_report_week') \
            .withColumn('export_date', F.date_sub(current_date(), 1)) \
            .withColumn('days_received_to_decision', F.datediff('decision_issued_date', 'received_date')) \
            .withColumn('days_received_to_valid', F.datediff('valid_date', 'received_date')) \
            .withColumn('days_in_system', F.datediff('export_date', 'received_date'))

        # calculate days_valid_to_registered taking into account bank holidays
        bank_hol = execution_context.spark_session.read.format("csv").option("header", "true").load(
            "s3://dataplatform-stg-raw-zone/unrestricted/util/hackney_bank_holiday.csv")
        # replace with local path in local mode "C:\\Users\\sballey\\data_dp\\data\\hackney_bank_holiday"
        # "s3://dataplatform-stg-raw-zone/unrestricted/util/hackney_bank_holiday.csv"
        bank_hol = bank_hol.withColumn('date', F.to_date('date', "dd-MM-yyyy"))
        df = working_days_diff(df, 'application_id', 'valid_date', 'registration_date', 'days_valid_to_registered',
                               bank_hol)

        # Merge Dates to calculate correct expiry date
        df = df.withColumn('date_application_expiry', F.coalesce('extension_of_time_due_date', 'expiry_date'))

        # Create Flags for reporting measures
        df = df.withColumn("flag_validated", when(df.valid_date.isNull(), 0).otherwise(1)) \
            .withColumn("flag_decided", when(df.decision_issued_date.isNull(), 0).otherwise(1)) \
            .withColumn("flag_extended", when(df.extension_of_time_due_date.isNull(), 0).otherwise(1)) \
            .withColumn("flag_registered", when(df.registration_date.isNull(), 0).otherwise(1)) \
            .withColumn("flag_ppa", when(df.ppa_decision_due_date.isNull(), 0).otherwise(1))

        # Apply Map to application stage field - first convert data types so they are both strings
        df = df.withColumn('application_stage_name', col('application_stage').cast('string'))
        df = df.replace(to_replace=mapStage, subset=['application_stage_name'])
        # Applications table is ready for joining

        # Load Application Types Table
        df2 = execution_context \
            .get_dataframe(local_path_parquet=application_types_data_path_local,
                           name_space=source_catalog_database,
                           table_name=source_catalog_table2,
                           push_down_predicate=create_pushdown_predicate('snapshot_date', 3))

        df2 = get_latest_snapshot(df2)

        # Rename Relevant Columns
        df2 = df2.withColumnRenamed("name", "application_type") \
            .withColumnRenamed("code", "application_type_code")

        # Keep Only Relevant Columns
        df2 = df2.select("id", "application_type", "application_type_code")

        # Load PS Codes
        df3 = execution_context \
            .get_dataframe(local_path_parquet=ps_development_codes_data_path_local,
                           name_space=source_catalog_database,
                           table_name=source_catalog_table3,
                           push_down_predicate=create_pushdown_predicate('snapshot_date', 3))

        df3 = get_latest_snapshot(df3)

        # Rename Relevant Columns
        df3 = df3.withColumnRenamed("id", "ps_id") \
            .withColumnRenamed("name", "development_type")

        # Keep Only Relevant Columns
        df3 = df3.select("ps_id", "expiry_days", 'development_type')

        # Apply Dev Type Mapping
        df3 = df3.withColumn("dev_type", col("development_type"))
        df3 = df3.replace(to_replace=mapDev, subset=['dev_type'])

        # Left Join Application Types and PS Development Codes onto Applications Table
        df = df.join(df2, df.application_type_id == df2.id, "left")
        df = df.join(df3, df.ps_development_code_id == df3.ps_id, "left")

        # Create Additional Calculations that required fields from the joined tables
        df = df.selectExpr('*', 'date_add(received_date, expiry_days) as calc_expiry_date')
        df = df.withColumn('current_expiry_date', F.coalesce('date_application_expiry', 'calc_expiry_date'))
        df = df.withColumn('flag_overdue_decided', when(df.decision_issued_date > df.current_expiry_date, 1)
                           .otherwise(0)) \
            .withColumn('flag_overdue_live', when(df.export_date > df.current_expiry_date, 1)
                        .otherwise(0)) \
            .withColumn('flag_overdue_registration', when(df.days_valid_to_registered > 5, 1)
                        .otherwise(0)) \
            .withColumn('days_over_expiry', F.datediff('decision_issued_date', 'current_expiry_date'))

        # Add a Counter
        df = df.withColumn('counter_application', lit(1))

        # Drop Duplicated Id columns created by the Join
        df = df.drop("ps_id", "id")
        df.select('valid_date', 'registration_date', 'days_valid_to_registered', 'flag_overdue_registration').show()

        # Data Processing Ends

        # wipe out the target folder in the trusted zone - comment out in local mode
        logger.info(f'clearing target bucket')
        # clear_target_folder(target_destination)

        # Write data
        execution_context.save_dataframe(df, target_destination, *PARTITION_KEYS_SNAPSHOT)


if __name__ == '__main__':
    main()
