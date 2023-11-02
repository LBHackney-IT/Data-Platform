"""
Script for splitting OS ABP files into their distinct type records CSVs in the raw zone.
These files are then used in the job addressbasepremium_create_national_address_table to create a national_address table in the Glue catalogue.
This code mainly comes from OS Github repository
"""

import sys
import csv
import s3fs
import boto3
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME','raw_bucket','raw_prefix','processed_data_path'])
    
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger.info(f'The job is starting.')

    # browse folder and list raw files
    boto_client = boto3.client('s3')
    response = boto_client.list_objects(
        Bucket= args['raw_bucket'],
        Prefix= args['raw_prefix']
    )

    csvfileList = []
    csvfileCount = 0
    
    for obj in response['Contents']:
        filename = obj['Key']
        if filename.endswith(".csv"):
            csvfileCount = csvfileCount+1
            csvfileList.append(filename)
    
    logger.info(f'Number of CSV files to read: {csvfileCount}')
    
    # Header lines for the new CSV files these are used later to when writing the header to the new CSV files
    headings10=["RECORD_IDENTIFIER","CUSTODIAN_NAME","LOCAL_CUSTODIAN_NAME","PROCESS_DATE","VOLUME_NUMBER","ENTRY_DATE","TIME_STAMP","VERSION","FILE_TYPE"]
    headings11=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","USRN","RECORD_TYPE","SWA_ORG_REF_NAMING","STATE","STATE_DATE","STREET_SURFACE","STREET_CLASSIFICATION","VERSION","STREET_START_DATE","STREET_END_DATE","LAST_UPDATE_DATE","RECORD_ENTRY_DATE","STREET_START_X","STREET_START_Y","STREET_START_LAT","STREET_START_LONG","STREET_END_X","STREET_END_Y","STREET_END_LAT","STREET_END_LONG","STREET_TOLERANCE"]
    headings15=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","USRN","STREET_DESCRIPTION","LOCALITY_NAME","TOWN_NAME","ADMINSTRATIVE_AREA","LANGUAGE","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE"]
    headings21=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","LOGICAL_STATUS","BLPU_STATE","BLPU_STATE_DATE","PARENT_UPRN","X_COORDINATE","Y_COORDINATE","LATITUDE","LONGITUDE","RPC","LOCAL_CUSTODIAN_CODE","COUNTRY","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE","ADDRESSBASE_POSTAL","POSTCODE_LOCATOR","MULTI_OCC_COUNT"]
    headings23=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","XREF_KEY","CROSS_REFERENCE","VERSION","SOURCE","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE"]
    headings24=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","LPI_KEY","LANGUAGE","LOGICAL_STATUS","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE","SAO_START_NUMBER","SAO_START_SUFFIX","SAO_END_NUMBER","SAO_END_SUFFIX","SAO_TEXT","PAO_START_NUMBER","PAO_START_SUFFIX","PAO_END_NUMBER","PAO_END_SUFFIX","PAO_TEXT","USRN","USRN_MATCH_INDICATOR","AREA_NAME","LEVEL","OFFICIAL_FLAG"]
    headings28=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","UDPRN","ORGANISATION_NAME","DEPARTMENT_NAME","SUB_BUILDING_NAME","BUILDING_NAME","BUILDING_NUMBER","DEPENDENT_THOROUGHFARE","THOROUGHFARE","DOUBLE_DEPENDENT_LOCALITY","DEPENDENT_LOCALITY","POST_TOWN","POSTCODE","POSTCODE_TYPE","DELIVERY_POINT_SUFFIX","WELSH_DEPENDENT_THOROUGHFARE","WELSH_THOROUGHFARE","WELSH_DOUBLE_DEPENDENT_LOCALITY","WELSH_DEPENDENT_LOCALITY","WELSH_POST_TOWN","PO_BOX_NUMBER","PROCESS_DATE","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE"]
    headings29=["RECORD_IDENTIFIER","GAZ_NAME","GAZ_SCOPE","TER_OF_USE","LINKED_DATA","GAZ_OWNER","NGAZ_FREQ","CUSTODIAN_NAME","CUSTODIAN_UPRN","LOCAL_CUSTODIAN_CODE","CO_ORD_SYSTEM","CO_ORD_UNIT","META_DATE","CLASS_SCHEME","GAZ_DATE","LANGUAGE","CHARACTER_SET"]
    headings30=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","SUCC_KEY","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE","SUCCESSOR"]
    headings31=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","ORG_KEY","ORGANISATION","LEGAL_NAME","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE"]
    headings32=["RECORD_IDENTIFIER","CHANGE_TYPE","PRO_ORDER","UPRN","CLASS_KEY","CLASSIFICATION_CODE","CLASS_SCHEME","SCHEME_VERSION","START_DATE","END_DATE","LAST_UPDATE_DATE","ENTRY_DATE"]
    headings99=["RECORD_IDENTIFIER","NEXT_VOLUME_NUMBER","RECORD_COUNT","ENTRY_DATE","TIME_STAMP"]
    
    # Prepares empty CSV files with headers

    s3 = s3fs.S3FileSystem(anon=False)
    
    header_10 = s3.open(args['processed_data_path'] + 'ID10_Header_Records.csv', 'w', encoding='utf-8')
    write10 = csv.writer(header_10, delimiter=',', quotechar='"', lineterminator='\n')
    write10.writerow(headings10)
    
    street_11 = s3.open(args['processed_data_path'] + 'ID11_Street_Records.csv', 'w', encoding='utf-8')
    write11 = csv.writer(street_11, delimiter=',', quotechar='"', lineterminator='\n')
    write11.writerow(headings11)
    
    streetdesc_15 = s3.open(args['processed_data_path'] + 'ID15_StreetDesc_Records.csv', 'w', encoding='utf-8')
    write15 = csv.writer(streetdesc_15, delimiter=',', quotechar='"', lineterminator='\n')
    write15.writerow(headings15)
    
    blpu_21 = s3.open(args['processed_data_path'] + 'ID21_BLPU_Records.csv', 'w')
    write21 = csv.writer(blpu_21, delimiter=',', quotechar='"', lineterminator='\n')
    write21.writerow(headings21)
	
    xref_23 = s3.open(args['processed_data_path'] + 'ID23_XREF_Records.csv', 'w')
    write23 = csv.writer(xref_23, delimiter=',', quotechar='"', lineterminator='\n')
    write23.writerow(headings23)
	
    lpi_24 = s3.open(args['processed_data_path'] + 'ID24_LPI_Records.csv', 'w')
    write24 = csv.writer(lpi_24, delimiter=',', quotechar='"', lineterminator='\n')
    write24.writerow(headings24)
	
    org_31 = s3.open(args['processed_data_path'] + 'ID31_Org_Records.csv', 'w')
    write31 = csv.writer(org_31, delimiter=',', quotechar='"', lineterminator='\n')
    write31.writerow(headings31)
	
    class_32 = s3.open(args['processed_data_path'] + 'ID32_Class_Records.csv', 'w')
    write32 = csv.writer(class_32, delimiter=',', quotechar='"', lineterminator='\n')
    write32.writerow(headings32)

    # The following counters are used to keep track of how many records of each Record Identifier type are found
    counter10 = 0
    counter11 = 0
    counter15 = 0
    counter21 = 0
    counter23 = 0
    counter24 = 0
    counter31 = 0
    counter32 = 0
    
    # Counter to keep track of the number of files processed
    processed = 0
    # There is a different routine for processing CSV files compared to ZIP files
    # This sections processes the CSV files using the Python CSV reader and write modules
    # It used the first value of the row to determine which CSV file that row should be written to.
    if csvfileCount > 0:
        for filepath in csvfileList:
        # for i in range (0,3):
        #     filepath = csvfileList[i]
            processed += 1
            logger.info("Processing file number " + str(processed) + " out of " + str(csvfileCount))
            s3_object = boto_client.get_object(Bucket='dataplatform-stg-raw-zone', Key=filepath)
            data = s3_object['Body'].read().decode('utf-8').splitlines()
            csvreader = csv.reader(data)
            try:
                for row in csvreader:
                    abtype = row[0]  
                    if "10" in abtype:
                        write10.writerow(row)
                        counter10 += 1
                    elif "11" in abtype:
                        write11.writerow(row)
                        counter11 += 1
                    elif "15" in abtype:
                        write15.writerow(row)
                        counter15 += 1
                    elif "21" in abtype:
                        write21.writerow(row)
                        counter21 += 1
                    elif "23" in abtype:
                        write23.writerow(row)
                        counter23 += 1
                    elif "24" in abtype:
                        write24.writerow(row)
                        counter24 += 1
                    elif "31" in abtype:
                        write31.writerow(row)
                        counter31 += 1
                    elif "32" in abtype:
                        write32.writerow(row)
                        counter32 += 1
                    # else:
                    #     pass
            except KeyError as e:
                pass
        header_10.close()
        street_11.close()
        streetdesc_15.close()
        blpu_21.close()
        xref_23.close()
        lpi_24.close()
        org_31.close()
        class_32.close()
    else:
        pass
    
    logger.info (f'Number of type 10 records: {counter10}') 
    logger.info (f'Number of type 11 records (street): {counter11}')
    logger.info (f'Number of type 15 records (streetdesc): {counter15}')
    logger.info (f'Number of type 21 records (blpu): {counter21}')
    logger.info (f'Number of type 23 records (xref): {counter23}')
    logger.info (f'Number of type 24 records (LPI): {counter24}')
    logger.info (f'Number of type 31 records (orgs): {counter31}')
    logger.info (f'Number of type 32 records (class): {counter32}')
    job.commit()
