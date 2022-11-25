import os
import main

s3_bucket = 'dataplatform-stg-landing-zone'
output_folder_name = 'huu_test'
glue_trigger_name = "TRIGGER_NAME"

API_TO_CALL = "stats"
TABLE_TO_CALL = "interactions"

secret_name = "vonage-key"

os.environ["TARGET_S3_BUCKET_NAME"] = s3_bucket
os.environ["OUTPUT_FOLDER"] = output_folder_name
os.environ["TRIGGER_NAME"] = glue_trigger_name
os.environ["SECRET_NAME"] = secret_name

os.environ["API_TO_CALL"] = API_TO_CALL
os.environ["TABLE_TO_CALL"] = TABLE_TO_CALL


main.lambda_handler("","")