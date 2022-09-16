1. run `docker-compose up` in this directory
    a. This will start the Kafka backend, the schema registry and the schema registry UI
    b. Schema registry UI will be available from http://localhost:8000
    c. Terminal output is often useful for seeing details on why things might be taking a while or are failing

2. Run the update_schemas_in_schema_registry.sh to update all schemas in the schema registry

3. Methods in local_test.py file can be run locally to validate new and existing schemas and test messages

4. main.py will be deployed as source for the test Lambda function. These files need to be developed further to remove some unnecessary repetition of code 

5. topic schemas in this folder are copies of the schemas stored in the schema registry terraform module. This ensures test scripts can be run both locally and on AWS

TODO:
Add kafka ui
