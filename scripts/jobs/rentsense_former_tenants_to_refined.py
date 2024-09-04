import gzip
import sys
from datetime import date, datetime
from io import BytesIO

import boto3
import pyspark.sql.functions as F
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import DropFields
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import (
    col,
    current_date,
    date_format,
    date_sub,
    lit,
    substring,
    to_date,
    to_timestamp,
)
from scripts.helpers.helpers import (
    PARTITION_KEYS,
    add_import_time_columns,
    clear_target_folder,
    get_latest_partitions_optimized,
)


def export_dynamic_frame_as_xml_gzip(dynamic_frame: DynamicFrame, s3_bucket: str, target_path: str,
                                     file_name: str) -> None:
    """
    Export a DynamicFrame to an XML file, compress it using gzip, and upload to S3.

    Args:
        dynamic_frame (DynamicFrame): The Glue DynamicFrame to be exported.
        s3_bucket (str): The target S3 bucket.
        target_path (str): The target path in the S3 bucket.
        file_name (str): The name of the file to be saved.

    Returns:
        None
    """
    # Remove the partition fields
    dynamic_frame = DropFields.apply(dynamic_frame,
                                     paths=['import_datetime', 'import_timestamp', 'import_year', 'import_month',
                                            'import_day', 'import_date'])

    # Convert dynamic frame to Spark DataFrame
    spark_df = dynamic_frame.toDF()

    # Spark DataFrame to Pandas DataFrame
    pandas_df = spark_df.toPandas()

    # Convert Pandas DataFrame to XML string
    xml_string = pandas_df.to_xml(index=False, parser='etree')

    # Compress the XML string using gzip
    xml_buffer = BytesIO()
    with gzip.GzipFile(fileobj=xml_buffer, mode='w') as gz_file:
        gz_file.write(xml_string.encode('utf-8'))

    # Seek to the beginning of the buffer
    xml_buffer.seek(0)

    today = datetime.today()
    year, month, day = today.year, str(today.month).zfill(2), str(today.day).zfill(2)
    today = f"{year}{month}{day}"

    # Upload the gzipped XML file to S3
    s3_client = boto3.client("s3")
    s3_client.upload_fileobj(xml_buffer, s3_bucket, f"{target_path}/rent.{file_name}{today}.xml.gz")


if __name__ == "__main__":

    args = getResolvedOptions(sys.argv,
                              ['JOB_NAME', 's3_bucket', 's3_bucket_target', 'source_raw_database', 's3_landing',
                               'source_catalog_database'])
    source_catalog_database = args["source_catalog_database"]
    s3_bucket = args["s3_bucket"]
    s3_bucket_target = args["s3_bucket_target"]
    source_raw_database = args["source_raw_database"]
    s3_landing = args["s3_landing"]
    s3_export_bucket_target = 's3://' + s3_landing + '/housing_export/rentsense-ft'

    today = date.today()
    export_target_path = "housing/rentsense-ft/export/%s/" % today.strftime("%Y%m%d")
    export_target_source = "housing/rentsense-ft/export/%s" % today.strftime("%Y%m%d")
    #  target_path = "housing_export/rentsense-ft/%s" % today.strftime("%Y%m%d")
    target_path = "housing/rentsense-ft/export/%s" % today.strftime("%Y%m%d")
    s3 = boto3.client("s3")
    # s3_bucket_target = export_target_source

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    spark = glueContext.spark_session
    logger = glueContext.get_logger()
    job = Job(glueContext)
    spark.conf.set("spark.sql.broadcastTimeout", 7200)

    logger.info(f'args: {args}')
    logger.info(f'source_catalog_database is {source_catalog_database}')
    logger.info(f's3_export_bucket_target is {s3_export_bucket_target}.')
    logger.info(f'export target path is {export_target_path}.')
    logger.info(
        f'The job is starting. The source table is {source_catalog_database}, the landing zone target it {s3_export_bucket_target} and landing zone is {s3_landing}.')

    # clear the rentsense export bucket so that only one date is being moved in the S3 shift
    exist = s3.list_objects_v2(Bucket=s3_landing, Prefix='housing_export/rentsense-ft/')  # list the files

    if 'Contents' in exist:
        clear_target_folder(s3_export_bucket_target)
        logger.info("Deleted landing zone target area")
    else:
        logger.info("Couldn't find data to delete")

    # clear the refined zones
    exist2 = s3.list_objects_v2(Bucket=s3_bucket, Prefix='housing/rentsense-ft/export/')  # list the files
    if 'Contents' in exist2:
        clear_target_folder(s3_bucket_target + '/export')
        logger.info("Deleted refined export zone target area")
    else:
        logger.info("Couldn't find data in refined export zone to delete")

    exist3 = s3.list_objects_v2(Bucket=s3_bucket, Prefix='housing/rentsense-ft/gzip/')  # list the files
    if 'Contents' in exist3:
        clear_target_folder(s3_bucket_target + '/gzip')
        logger.info("Deleted refined gzip zone target area")
    else:
        logger.info("Couldn't find data in refined gzip zone to delete")

    # Mapping tables
    mapTransactions = {
        'D20': 'Section 20 Rebate',
        'D25': 'Section 125 Rebate',
        'DAT': 'Assignment SC Trans',
        'DBR': 'Basic Rent (No VAT)',
        'DBT': 'MW Balance Transfer',
        'DC1': 'C Preliminaries',
        'DC2': 'C Provisional Sums',
        'DC3': 'C Contingency Sums',
        'DC4': 'C Professional Fees',
        'DC5': 'C Administration',
        'DCB': 'Cleaning (Block)',
        'DCC': 'Court Costs',
        'DCE': 'Cleaning (Estate)',
        'DCI': 'Contents Insurance',
        'DCO': 'Concierge',
        'DCP': 'Car Port',
        'DCT': 'Communal Digital TV',
        'DGA': 'Garage (Attached)',
        'DGM': 'Grounds Maintenance',
        'DGR': 'Ground Rent',
        'DHA': 'Host Amenity',
        'DHE': 'Heating',
        'DHM': 'Heating Maintenance',
        'DHW': 'Hot Water',
        'DIN': 'Interest',
        'DIT': 'Arrangement Interest',
        'DKF': 'Lost Key Fobs',
        'DLD': 'Legacy Debit',
        'DLK': 'Lost Key Charge',
        'DLL': 'Landlord Lighting',
        'DLP': 'Late Payment Charge',
        'DMC': 'Major Works Capital',
        'DMF': 'TA Management Fee',
        'DMJ': 'MW Judgement Trans',
        'DML': 'Major Works Loan',
        'DMR': 'Major Works Revenue',
        'DPP': 'Parking Permits',
        'DPY': 'Parking Annual Chg',
        'DR1': 'R Preliminaries',
        'DR2': 'R Provisional Sums',
        'DR3': 'R Contingency Sums',
        'DR4': 'R Professional Fees',
        'DR5': 'R Administration Fee',
        'DRP': 'Rechg Repairs no VAT',
        'DRR': 'Rechargeable Repairs',
        'DSA': 'SC Adjustment',
        'DSB': 'SC Balancing Charge',
        'DSC': 'Service Charges',
        'DSJ': 'SC Judgement Debit',
        'DSO': 'Shared Owners Rent',
        'DSR': 'Reserve Fund',
        'DST': 'Storage',
        'DTA': 'Basic Rent Temp Acc',
        'DTC': 'Travellers Charge',
        'DTL': 'Tenants Levy',
        'DTV': 'Television License',
        'DVA': 'VAT Charge',
        'DWR': 'Water Rates',
        'DWS': 'Water Standing Chrg.',
        'DWW': 'Watersure Reduction',
        'RBA': 'Bailiff Payment',
        'RBP': 'Bank Payment',
        'RBR': 'PayPoint/Post Office',
        'RCI': 'Rep. Cash Incentive',
        'RCO': 'Cash Office Payments',
        'RCP': 'Debit / Credit Card',
        'RCT': 'MW Credit Transfer',
        'RDD': 'Direct Debit',
        'RDN': 'Direct Debit Unpaid',
        'RDP': 'Deduction (Work & P)',
        'RDR': 'BACS Refund',
        'RDS': 'Deduction (Salary)',
        'RDT': 'DSS Transfer',
        'REF': 'Tenant Refund',
        'RHA': 'HB Adjustment',
        'RHB': 'Housing Benefit',
        'RIT': 'Internal Transfer',
        'RML': 'MW Loan Payment',
        'ROB': 'Opening Balance',
        'RPD': 'Prompt Pay. Discount',
        'RPO': 'Postal Order',
        'RPY': 'PayPoint/Post Office',
        'RQP': 'Cheque Payments',
        'RRC': 'Returned Cheque',
        'RRP': 'Recharge Rep. Credit',
        'RSJ': 'SC Judgement Trans',
        'RSO': 'Standing Order',
        'RTM': 'TMO Reversal',
        'RUC': 'Universal Credit Rec',
        'RWA': 'Rent waiver',
        'WOF': 'Write Off',
        'WON': 'Write On'}

    mapAction = {
        'CVD': 'Covid 19 Call',
        'CVB': 'C19 Court Order Breached',
        'CBV': 'Court Breach Visit Made',
        'Z00': 'Arrears Cleared',
        '1RS': 'Old Stage One',
        '2RS': 'Old Stage Two',
        'AGR': 'Agreement brought up-to-date',
        '3RS': 'Old Stage Three',
        '4RS': 'Old Stage Four',
        'RR4': 'Reset Stage Four',
        'ZR1': 'Stage One Complete',
        'ZR2': 'Stage Two Complete',
        'ZR3': 'Stage Three Complete',
        'ZL4': 'Legal Referral Complete',
        '1TS': 'Stage One (T)',
        '2TS': 'Stage Two (T)',
        '5TA': 'Eviction',
        'ZT4': 'Court Proceedings Complete',
        'ZT5': 'Eviction Complete',
        'ZR5': 'Pre-Court Complete',
        '0RA': 'Old Breached Agreement (0)',
        '5RP': 'Pre Court',
        '4TC': 'Court Proceedings',
        'ZR4': 'Stage Four Complete',
        'ZT1': 'Stage One Complete',
        '1RA': 'Old Breached Agreement (1)',
        '2RA': 'Old Breached Agreement (2)',
        '3RA': 'Old Breached Agreement (3)',
        '6RO': 'Breached Order',
        '1LA': 'Breached Agreement 1L',
        '1LS': 'Stage One (L)',
        'ZT2': 'Stage Two Complete',
        '2LS': 'Stage Two (L)',
        'GEN': 'General Diary Note',
        '3LS': 'Stage Three (L)',
        '4LL': 'Legal Referral',
        '0LA': 'Breached Agreement 0L',
        '3LA': 'Breached Agreement 3L',
        '2LA': 'Breached Agreement 2L',
        '4LA': 'Breached Agreement 4L',
        'ZL1': 'Stage One Complete',
        'ZL2': 'Stage Two Complete',
        'ZL3': 'Stage Three Complete',
        'ZR6': 'Court Proceedings Complete',
        'CDL': 'Court Date Letter',
        'IC6': 'Court Outcome Added',
        'IC5': 'Court Outcome Letter',
        'IC4': 'Court Warning Letter',
        '3TS': 'Stage Three (T)',
        'BRE': 'Breached Agreement',
        'ZT3': 'Stage Three Complete',
        'OUT': 'Outright Possession Order',
        'VIU': 'Unsuccessful Visit',
        'VIM': 'Visit Made',
        'CAW': 'Costs Awarded',
        'ZT6': 'Eviction Complete',
        'MJA': 'Money Judgement Awarded',
        'CAP': 'Charge Against Property',
        'SPO': 'Suspended Possession',
        'PPO': 'Postponed Possession',
        'ADG': 'Adjourned Generally',
        'ADT': 'Adjourned on Terms',
        'DPQ': 'DWP Direct Payments Requested',
        'HBO': 'HB Outstanding',
        'DPR': 'DWP Direct Payments Refused',
        'DPM': 'DWP Direct Payments Being Made',
        'DPT': 'DWP Direct Payments Terminated',
        'MJQ': 'Money Judgement Requested',
        'EVI': 'Eviction',
        'DIS': 'Dispute',
        'CRC': 'Complaint Received',
        'CRS': 'Complaint Resolved',
        'NTS': 'Notice Served',
        'ITS': 'Introductory Tenancy to Secure',
        'VAP': 'Voluntary Attach. of Earnings',
        'IPA': 'Involuntary Att. of Earnings',
        'WEA': 'Warrant of Exec. Applied for',
        'NES': 'Notice of Extension Served',
        '7RE': 'Eviction',
        '1TA': 'Breached Agreement (1)',
        'DA1': 'Referred to Moorcroft',
        'DDR': 'Direct Debit new sign up',
        'DDC': 'Direct Debit Cancelled',
        'FTA': 'Now a Former Tenants Account',
        'AGG': 'FTA ARREARS AGREEMENT',
        'CDD': 'Changes to DirectDebit payment',
        'DC1': 'First contact with NOK',
        'DC2': 'Subsequent contact with NOK',
        '2TA': 'Breached Agreement (2)',
        'RT1': 'Returned by Moorcroft',
        'C': 'First FTA letter sent',
        'D': 'Second FTA reminder',
        'E': 'FTA Debt Agency warning',
        'FIV': 'Financial Inclusion Visit',
        'FIC': 'Financial Inclusion Call',
        'FIO': 'Financial Inclusion Interview',
        'OOC': 'Out of hours call',
        '3TA': 'Breached Agreement (3)',
        'OFI': 'Office interview',
        'DDP': 'Diirect Debit Payment',
        'BA': 'FTA Broken Agreement',
        'S01': 'S01 Stage One',
        'S02': 'S02 Stage Two',
        'S03': 'S03 Stage Three',
        'S04': 'S04 Stage Four',
        'S05': 'S05 Court',
        'S06': 'S06 Breach Court Order',
        'S0A': 'S0A Alternative Letter',
        '6RC': 'Court Proceedings',
        'CBL': 'Court Breach Letter',
        'WOA': 'Write Off - Uneconomical',
        'WOB': 'Write Off - Vulnerable/Infirm',
        'WOC': 'Write Off - Deceased',
        'WOE': 'Write Off - Address Unknown',
        'WOF': 'Write Off - Dispute unresolved',
        'WOH': 'Write Off - All action failed',
        'WOD': 'Write Off - FT on Prison',
        'VUN': 'Vunerable',
        'ZR7': 'Eviction Complete',
        'DEB': 'Referred for debt advice',
        'REP': 'Repairs',
        'PAB': 'Possible abandonment',
        'TMO': 'TMO a/c - no action required',
        'REF': 'FTA Refund Request Letter Sent',
        'MML': 'Arrears mail merge letter sent',
        'UCC': 'Universal Credit',
        'SMS': 'Text message sent',
        'ACB': 'Actual Cost Breakdown Sent',
        'TAA': 'TA New Account checks',
        'PLA': 'Pre legal action visit',
        'PEO': 'Pre eviction contact outcome',
        'AAD': 'Pre notice interview',
        'RAP': 'Rent Arrears Panel Outcome',
        'DA4': 'Referred to Credit Gee',
        'RT4': 'Returned by Credit Gee',
        'ZW0': 'MW Pre Arrears Completed',
        'ZW1': 'MW Letter Action 1 Completed',
        'ZW2': 'MW Letter Action 2 Completed',
        'ZW3': 'MW LBA Letter Completed',
        'ZWD': 'MW Charges Disputed Completed',
        'ZWC': 'MW MCOL Completed',
        'ZWL': 'MW Legal Referral Completed',
        'ZWA': 'MW Arrangement Completed',
        'AWO': 'Write on - arrears reinstated',
        'MWB': 'MW Arrangement Breached',
        'NFA': 'FTA - TO BE TRACED',
        'INC': 'Incoming telephone call',
        'OTC': 'Outgoing telephone call',
        'DA2': 'REFERRED TO VIL COLLECTIONS',
        'DA3': 'REFERRED TO LEWIS DEBT AGENCY',
        'RT2': 'RETURNED BY VIL COLLECTIONS',
        'RT3': 'RETURNED BY LEWIS DEBT AGENCY',
        'INV': 'ACTION ON HOLD',
        'MHB': 'HB INVESTIGATION PENDING',
        'MW0': 'MW Pre Arrears',
        'MW1': 'MW Letter Action 1',
        'MW2': 'MW Letter Action 2',
        'MW3': 'MW LBA Letter',
        'MWD': 'MW Charges Disputed',
        'MWC': 'MW MCOL',
        'MWL': 'MW Legal Referral',
        'MWA': 'MW Arrangement',
        'WON': 'Arrears reinstated to offset',
        'GAT': 'Automated green in Arrears sms message',
        'GAE': 'Automated green in Arrears email message',
        'GME': 'Manual green in Arrears email message',
        'GMS': 'Manual green in Arrears sms message',
        'AMS': 'Manual amber in Arrears sms message',
        'CDS': 'Court date set',
        'EDS': 'Eviction date set',
        'POP': 'Promise of payment',
        'DEC': 'Deceased',
        'MBH': 'Delayed benefit',
        'LF1': 'Letter 1 in arrears FH',
        'LF2': 'Letter 2 in arrears FH',
        'LL1': 'Letter 1 in arrears LH',
        'LL2': 'Letter 2 in arrears LH',
        'LS1': 'Letter 1 in arrears SO',
        'LS2': 'Letter 2 in arrears SO',
        'SLB': 'Letter Before Action',
        'IC1': 'Income Collection Letter 1',
        'IC2': 'Income Collection Letter 2',
        'RMD': 'Missing Data',
        'WPA': 'Warrant of Possession',
        'BLI': 'Informal Agreement Breach Letter Sent',
        'TEN': 'New Tenancy Letter Sent',
        'HCO': 'Home Contents Insurance',
        'REQ': 'Rent Refund Request Received',
        'RHB': 'Refund request sent to HB for approval',
        'RRF': 'Renf request refused',
        'RRP': 'Refund request processed',
        # 'DDB': 'Standing request ',
        'DDB': 'Debt Advice Ongoing',
        'SLC': 'Solicitor Intervention',
        'LEG': 'Case with internal Legal Team',
        'CPN': 'Ongoing internal Complaint',
        'CDH': 'Credit Due to Housing Benefit overpayment',
        'TDD': 'Termination Date Dispute refer to Housing Officer',
        'SUP': 'Change of tenancy',
        'TRR': 'Suspense payments',
        'CTE': 'Payment transfer between rent accounts'
    }

    df = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database,
        table_name="person_reshape",
        transformation_ctx="person_reshape_source")
    df = get_latest_partitions_optimized(df)

    df2 = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database,
        table_name="tenure_reshape",
        transformation_ctx="tenure_reshape_source")
    df2 = get_latest_partitions_optimized(df2)

    df3 = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database,
        table_name="assets_reshape",
        transformation_ctx="assets_reshape_source")
    df3 = get_latest_partitions_optimized(df3)

    df4 = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database,
        table_name="contacts_reshape",
        transformation_ctx="contacts_reshape_source")
    df4 = get_latest_partitions_optimized(df4)

    df5 = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="housingfinancedbproduction_agreements",
        transformation_ctx="housingfinancedbproduction_agreements_source")
    df5 = get_latest_partitions_optimized(df5)

    df6 = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="housingfinancedbproduction_agreement_states",
        transformation_ctx="housingfinancedbproduction_agreement_states_source")
    df6 = get_latest_partitions_optimized(df6)

    df7 = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="sow2b_dbo_matenancyagreement",
        transformation_ctx="sow2b_dbo_matenancyagreement_source")
    df7 = get_latest_partitions_optimized(df7)

    dfprop = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="sow2b_dbo_maproperty",
        transformation_ctx="sow2b_dbo_maproperty_source")
    dfprop = get_latest_partitions_optimized(dfprop)

    df9 = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="sow2b_dbo_uharaction",
        transformation_ctx="sow2b_dbo_uharaction_source")
    df9 = get_latest_partitions_optimized(df9)

    df10 = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="sow2b_dbo_ssminitransaction",
        transformation_ctx="sow2b_dbo_ssminitransaction_source")
    df10 = get_latest_partitions_optimized(df10)

    patch_officer = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="rent_officer_patch_mapping",
        transformation_ctx="rent_officer_patch_mapping_source")
    patch_officer = get_latest_partitions_optimized(patch_officer)

    balance = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="sow2b_dbo_calculatedcurrentbalance",
        transformation_ctx="sow2b_dbo_calculatedcurrentbalance_source")
    balance = get_latest_partitions_optimized(balance)

    case_priorities = glueContext.create_data_frame.from_catalog(
        database=source_raw_database,
        table_name="housingfinancedbproduction_case_priorities",
        transformation_ctx="housingfinancedbproduction_case_priorities_source")
    case_priorities = get_latest_partitions_optimized(case_priorities)

    # # create the patch information
    # patch_officer = patch_officer.withColumn("patch_number2", F.trim(F.col("patch_number")))

    # patch = dfprop.withColumn("patch2", F.trim(F.col("arr_patch"))) \
    #     .withColumn("property_ref", F.trim(F.col("prop_ref"))) \
    #     .replace(to_replace=mapPatch, subset=['patch2'])

    # patch = patch.join(patch_officer, patch.patch2 == patch_officer.patch_number2, "left")
    # patch = patch.selectExpr("property_ref as prop_ref",
    #                          "patch2 as Patch",
    #                          "officer_full_name as HousingOfficerName")
    # patch = patch.distinct()

    # data loads - takes all records that have and end date and secure tenancies, intro and mesne tenancies are added after as there are some tenancy ids with both
    accounts = df2.filter("endoftenuredate is not NULL and paymentreference<>''")
    accounts_s = accounts.where(col("description").isin({"Secure", "Non-Secure", "Private Garage", "Tenant Garage"}))
    accounts_int = accounts.where(col("description").isin({"Introductory", "Mense Profit Ac"}))
    accounts_int = accounts_int.join(accounts_s, accounts_int.paymentreference == accounts_s.paymentreference,
                                     'leftanti')  # remove the paymentreference in the other dataset

    accounts = accounts_s.union(accounts_int)
    accounts.select(col("startOfTenureDate"), to_date(col("startOfTenureDate"), "yyyy-MM-dd").alias("date")) \
        .drop("startOfTenureDate").withColumnRenamed("date", "startOfTenureDate")

    accounts = accounts.drop("uh_ten_ref")

    accounts = accounts.withColumn("prop_ref", F.trim(F.col("property_reference")))
    # accounts = accounts.join(patch, accounts.prop_ref == patch.prop_ref, "left")

    # get the max date to remove dupes
    start_ten = accounts.selectExpr("paymentreference as AccountR",
                                    "left(startOfTenureDate,10) as TenancyDate")

    df_agg = (start_ten
              .groupBy("AccountR")
              .agg(F.max("TenancyDate").alias("max_date")))

    # payref to tenancy ref

    p_ref = df7.selectExpr("trim(u_saff_rentacc) as pay_ref",
                           "trim(tag_ref) as uh_ten_ref")

    accounts = accounts.join(p_ref, accounts.paymentreference == p_ref.pay_ref, "left")

    bals_filter = balance.withColumn("BalanceDate", F.to_date(F.col("import_date"), "yyyyMMdd")) \
        .withColumn("paymentreference2", F.trim(F.col("RentAccount"))) \
        .filter(col("previousweekbalance") != 0) \
        .withColumnRenamed("import_date", "bal_date")

    accounts2 = accounts.join(bals_filter, accounts.paymentreference == bals_filter.paymentreference2, "right")

    accounts2 = accounts2.filter("paymentreference is not null") \
        .withColumn("TenancyEndDate", F.to_date(substring("endoftenuredate", 1, 10), "yyyy-MM-dd"))

    #     .withColumn("TenancyEndDate", F.to_date(F.to_timestamp(col("endoftenuredate"), "M/d/yyyy H:mm")))
    #        .filter(col('patch').like('%Patch%')) \

    # Arrangements

    ten = accounts2.select('uh_ten_ref', 'paymentreference')
    arr = df5.join(ten, df5.tenancy_ref == ten.uh_ten_ref, "inner")
    arr = arr.distinct()
    arr = arr.where(col("current_state").isin({"live", "breached"}))

    agg_end = df6.where(col("agreement_state").isin({"cancelled", "completed"}))
    agg_end = agg_end.selectExpr("agreement_id",
                                 "created_at as AgreementEndDate")

    arr = arr.join(agg_end, arr.id == agg_end.agreement_id, "left")
    arr = arr.withColumn("AgreementStartDate", F.to_date(F.col("start_date"), "yyyy-MM-dd")) \
        .withColumn("AgreementEndDate1", F.to_date(F.col("AgreementEndDate"), "yyyy-MM-dd")) \
        .withColumn("AgreementCreatedDate", F.to_date(F.col("created_at"), "yyyy-MM-dd")) \
        .withColumn("AgreementCode", F.when(F.col("court_case_id") > 0, "C").otherwise("N")) \
        .drop("AgreementEndDate")

    arr = arr.selectExpr("paymentreference as AccountReference",
                         "AgreementStartDate as StartDate",
                         "AgreementEndDate1 as EndDate",
                         "frequency as PaymentFrequency",
                         "AgreementCode as ArrangementCode",
                         #  "initial_payment_date as FirstInstallmentDueDate",
                         # "AgreementCreatedDate",
                         "Amount as PaymentAmount"
                         #   "uh_ten_ref as TenReference",
                         #  "import_date"
                         )

    arr = arr.distinct()
    output = arr
    arr = add_import_time_columns(arr)
    arr = arr.filter(col("AgreementEndDate").isNull())

    dynamic_frame = DynamicFrame.fromDF(arr.repartition(1), glueContext, "target_data_to_write")

    # save out the data

    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target + '/formerarrangements', "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    export_dynamic_frame_as_xml_gzip(dynamic_frame, s3_bucket, target_path, "formerarrangements")

    # Tenants
    tens = accounts2.filter("member_is_responsible like true")

    asset = df3.selectExpr("asset_id",
                           "addressLine1 as Address1",
                           "addressLine2 as Address2",
                           "addressLine3 as Address3",
                           "postCode as PostCode",
                           "assetType as PropertyType"
                           )
    tens = tens.join(asset, tens.asset_id == asset.asset_id, "left")

    per = df.selectExpr("person_id as pid",
                        "preferredTitle as Title",
                        "firstName as TenantFirstName",
                        "surname as TenantSurName")

    tens = tens.join(per, tens.person_id == per.pid, "left").distinct()

    # create contact methods

    mob = df4.filter((df4.contacttype == "phone") & (df4.subtype == "mobile") & (df4.isactive == "true")).selectExpr(
        "person_id as pid1",
        "value as MobileNumber")
    # get one record
    mob = (mob
           .groupBy("pid1")
           .agg(F.max("MobileNumber").alias("MobileNumber")))

    lline = df4.filter(
        (df4.contacttype == "phone") & (df4.subtype == "landline") & (df4.isactive == "true")).selectExpr(
        "person_id  as pid2",
        "value as TelephoneNumber")

    lline = (lline
             .groupBy("pid2")
             .agg(F.max("TelephoneNumber").alias("TelephoneNumber")))

    email = df4.filter(df4.contacttype == "email").selectExpr("person_id  as pid3",
                                                              "value as Email")

    email = (email
             .groupBy("pid3")
             .agg(F.max("Email").alias("Email")))

    # add the correspondence address
    cor = df4.filter((df4.subtype == "correspondenceAddress") & (df4.isactive == "true")).selectExpr(
        "person_id as pid4",
        "value as correspondenceAddress")

    tens = tens.join(mob, tens.person_id == mob.pid1, "left")

    tens = tens.join(lline, tens.person_id == lline.pid2, "left")

    tens = tens.join(email, tens.person_id == email.pid3, "left")

    tens = tens.join(cor, tens.person_id == cor.pid4, "left")

    tens = tens.selectExpr("paymentreference as AccountReference",
                           # "Title",
                           "case when length(TenantFirstName)=0 then '.' else TenantFirstName end as FirstName",
                           "case when length(TenantSurName)=0 then '.' else TenantSurName end as Surname",
                           #     "TenantSurName",
                           "left(MobileNumber,200) as PrimaryPhoneNumber",
                           "left(TelephoneNumber,200) as SecondaryPhoneNumber",
                           "case when length(Address1)=0 then '.' else Address1 end as PropertyAddress",
                           "correspondenceAddress as ContactAddress",
                           "trim(right(correspondenceAddress,8)) as ContactPostcode",
                           #     "Address1",
                           #     "Address2",
                           #     "Address3",
                           "PostCode as PropertyPostCode",
                           "Email as PrimaryEmailAddress",
                           "'' as SecondaryEmailAddress"
                           # "PropertyType",
                           # "uh_ten_ref as TenReference",
                           # "import_date"
                           )

    tens = tens.distinct()

    tens = tens.fillna({'FirstName': '.', 'SurName': '.', 'PropertyAddress': '.'})
    output = tens

    tens = add_import_time_columns(tens)

    dynamic_frame = DynamicFrame.fromDF(tens.repartition(1), glueContext, "target_data_to_write")

    # save out the data

    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target + '/formertenants', "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    export_dynamic_frame_as_xml_gzip(dynamic_frame, s3_bucket, target_path, "formertenants")

    # Balances
    ten = accounts2.select('uh_ten_ref', 'paymentreference')

    bals = balance.withColumn("BalanceDate", F.to_date(F.col("import_date"), "yyyyMMdd")) \
        .withColumn("paymentreference2", F.trim(F.col("RentAccount")))

    balances = ten.join(bals, ten.paymentreference == bals.paymentreference2, "inner")

    balances = balances.selectExpr("paymentreference as AccountReference",
                                   "previousweekbalance as CurrentBalance",
                                   "BalanceDate"
                                   # "uh_ten_ref as TenReference",
                                   #  "import_date"
                                   )

    balances = balances.distinct()
    output = balances

    balances = add_import_time_columns(balances)

    dynamic_frame = DynamicFrame.fromDF(balances.repartition(1), glueContext, "target_data_to_write")

    # save out the data
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target + '/formerbalances', "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    export_dynamic_frame_as_xml_gzip(dynamic_frame, s3_bucket, target_path, "formerbalances")

    # Actions

    ten = accounts2.select('uh_ten_ref', 'paymentreference')

    actions = df9.withColumn("uh_ten_ref1", F.trim(F.col("tag_ref"))) \
        .withColumn("timestamp", to_timestamp("action_date", "yyyy-MM-dd HH:mm:ss.S")) \
        .withColumn("ActionDate", date_format("timestamp", "yyyy-MM-dd'T'HH:mm:ss.SSSZ"))

    # .withColumn("ActionDate", F.to_date(F.col("action_date"), "yyyy-MM-dd"))

    actions = actions.filter(
        (F.col("action_date") > date_sub(current_date(), 365)) & (F.col("action_date") < current_date()))

    actions = ten.join(actions, ten.uh_ten_ref == actions.uh_ten_ref1, "inner")

    actions = actions.withColumn("code_lookup", F.trim(F.col("action_code"))) \
        .replace(to_replace=mapAction, subset=['code_lookup'])

    max_action = (actions
                  .groupBy("paymentreference")
                  .agg(F.max("action_no").alias("max_action"))) \
                  .withColumnRenamed("paymentreference", "payref")

    actions1 = actions.join(max_action, actions.paymentreference == max_action.payref, "inner")

    latest = actions1.filter("max_action=action_no")

    actions = latest.selectExpr("paymentreference as AccountReference",
                                "action_code as ActionCode",
                                "ActionDate"
                                )

    actions = actions.distinct()

    dynamic_frame = DynamicFrame.fromDF(actions, glueContext, "target_data_to_write")
    export_dynamic_frame_as_xml_gzip(dynamic_frame, s3_bucket, target_path, "formeractions")

    actions = add_import_time_columns(actions)

    dynamic_frame = DynamicFrame.fromDF(actions.repartition(1), glueContext, "target_data_to_write")

    # save out the data
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target + '/formeractions', "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    # Attach the last action as the patch and save out the accounts

    accounts3 = accounts2.join(actions, accounts2.paymentreference == actions.AccountReference, "left")

    accounts3 = accounts3.selectExpr("paymentreference as AccountReference",
                                     "description as TenureType",
                                     "tenure_code as TenureTypeCode",
                                     # "endoftenuredate as TenancyEndDate",
                                     "TenancyEndDate",
                                     "'Hackney' as LocalAuthority",
                                     "'' as HousingOfficerName",
                                     "ActionCode as Patch",
                                     #     "import_date as import_date",
                                     "uh_ten_ref as tenancy_ref",
                                     "PreviousWeekBalance"
                                     )

    accounts4 = accounts3.join(df_agg, accounts3.AccountReference == df_agg.AccountR, "left")

    case_priorities = case_priorities.filter(F.col("pause_reason") == "Deceased")

    case_priorities = case_priorities.withColumn('Deceased', lit(1)) \
        .drop("import_date") \
        .withColumnRenamed("tenancy_ref", "tenancy_ref2")

    accounts5 = accounts4.join(case_priorities, accounts4.tenancy_ref == case_priorities.tenancy_ref2, "left")

    accounts6 = accounts5.selectExpr("AccountReference as AccountReference",
                                     # "TenureType",
                                     #  "TenureTypeCode",
                                     # "max_date as TenancyStartDate",
                                     "TenancyEndDate",
                                     "LocalAuthority",
                                     # "HousingOfficerName",
                                     "Patch",
                                     "'Hackney' as Region",
                                     #   "import_date as import_date",
                                     #  "tenancy_ref as TenReference",
                                     #  "is_paused_until as BreathingSpaceEndDate",
                                     "Case when Deceased=1 then 'Y' else 'N' end as Deceased"
                                     #  "previousweekbalance"
                                     )

    accounts7 = accounts6.filter("AccountReference is not null")

    accounts8 = accounts7.distinct()

    accounts9 = add_import_time_columns(accounts8)

    # create the accounts table referenced in the other extracts
    dynamic_frame = DynamicFrame.fromDF(accounts9.repartition(1), glueContext, "target_data_to_write")

    # save out the data

    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target + '/formeraccounts', "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    # Export to .xml.gzip
    export_dynamic_frame_as_xml_gzip(dynamic_frame, s3_bucket, target_path, "formeraccounts")
    # Transactions

    ten = accounts2.select('uh_ten_ref', 'paymentreference')

    df11 = df10.filter((F.col("post_date") > date_sub(current_date(), 365)) & (F.col("post_date") < current_date()))

    df11 = df11.withColumn("TransactionID", F.monotonically_increasing_id()) \
        .withColumn("code_lookup", F.trim(F.col("trans_type"))) \
        .replace(to_replace=mapTransactions, subset=['code_lookup'])

    trans = df11.withColumn("uh_ten_ref1", F.trim(F.col("tag_ref")))

    trans = ten.join(trans, ten.uh_ten_ref == trans.uh_ten_ref1, "inner")

    trans1 = trans.withColumn("timestamp", to_timestamp("post_date", "yyyy-MM-dd HH:mm:ss.S")) \
        .withColumn("iso8601_format", date_format("timestamp", "yyyy-MM-dd'T'HH:mm:ss.SSSZ"))

    trans = trans1.selectExpr("paymentreference as AccountReference",
                              "TransactionID",
                              "iso8601_format as TransactionDate",
                              "iso8601_format as TransactionPostDate",
                              "trans_type as TransactionCode",
                              "real_value as TransactionAmount",
                              "code_lookup as TransactionDescription"
                              # "uh_ten_ref as TenReference",
                              # "import_date"
                              )

    trans = trans.distinct()
    output = trans

    trans = add_import_time_columns(trans)

    dynamic_frame = DynamicFrame.fromDF(trans.repartition(1), glueContext, "target_data_to_write")

    # save out the data
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target + '/formertransactions', "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    export_dynamic_frame_as_xml_gzip(dynamic_frame, s3_bucket, target_path, "formertransactions")

    job.commit()
