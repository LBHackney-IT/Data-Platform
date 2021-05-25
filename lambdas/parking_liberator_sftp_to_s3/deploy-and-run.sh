SFTP_HOST=
SFTP_USERNAME=
SFTP_PASSWORD=
S3_BUCKET=


# create execution role for lambda
# aws-vault exec hackney-dataplatform-development -- aws iam create-role --role-name test-emmacorbett-lambda-ex --assume-role-policy-document file://policies/trust-policy.json
# aws-vault exec hackney-dataplatform-development -- aws iam attach-role-policy --role-name test-emmacorbett-lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole


# Create new function
# zip -r parking_liberator_file_upload_lambda.zip .

# aws-vault exec hackney-dataplatform-development -- aws lambda create-function --function-name parking-liberator-data-file-upload \
# --zip-file fileb://parking_liberator_file_upload_lambda.zip --handler index.handler --runtime nodejs12.x \
# --role arn:aws:iam::484466746276:role/test-emmacorbett-lambda-ex


#Update existing function
zip -r parking_liberator_file_upload_lambda.zip .
aws-vault exec hackney-dataplatform-development -- aws lambda update-function-code --function-name parking-liberator-data-file-upload --zip-file fileb://parking_liberator_file_upload_lambda.zip 
aws-vault exec hackney-dataplatform-development -- aws lambda update-function-configuration --function-name parking-liberator-data-file-upload \
    --environment "Variables={SFTP_HOST=$SFTP_HOST,SFTP_USERNAME=$SFTP_USERNAME,SFTP_PASSWORD=$SFTP_PASSWORD,S3_BUCKET=$S3_BUCKET}" \
    --timeout 10

# invoke lambda
aws-vault exec hackney-dataplatform-development -- aws lambda invoke --function-name parking-liberator-data-file-upload out

# aws lambda delete-function --function-name my-function
