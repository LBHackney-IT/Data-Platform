# Local lambda set up

To deploy the lambda functions using the AWS CLI, use the following commands:

1. Compress the lambda `zip -r lambdaFunc.zip .`
2. `aws lambda update-function-code --function-name rd-export-testing_lambda --zip-file fileb://lambdaFunc.zip --profile madetech-sandbox` (update the --profile to your own if needed)
