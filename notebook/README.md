# Jupyter Notebook

## Prerequisites
- [Docker Desktop](https://docs.docker.com/desktop/#download-and-install)

## Run the Container

If you have make and aws-vault installed and setup with credentials for `hackney-dataplatform-development` already you can follow option 1, otherwise use the second option. The first option has the advantage that you don't have to change your credentials each day as they get rotated.

To install and setup aws-vault follow the instructions in step 3 of the [setup section in the project README](https://github.com/LBHackney-IT/Data-Platform/blob/main/README.md#set-up).

### Option 1. Using make and aws-vault (Preferred)
Run
```sh
make run-notebook
```

### Option 2. Using access keys and docker
1. Navigate to [the hackney SSO](https://hackney.awsapps.com/start#/), click on the account you want to use then click "Command line or programmatic access".
2. Copy the aws access key, aws secret access key and aws session token into the file `/aws-config/credentials`.
3. Run 
```sh
docker compose up notebook
```

## Open Jupyter Notebook
- Navigate to [http://localhost:8888](http://localhost:8888)

## Test connection to AWS

1. Within the notebook open `test-s3-connection`.
1. Change the `s3_url` variable to be a s3 bucket that exists in the AWS account you are using.
1. Click "Run"
1. You should get some data back from the s3 bucket and no errors.

## Spark SQL read–eval–print loop

1. Follow the instructions for "Run your container" above.
1. Run `make thrift-server`, and wait for the command to finish, you should get a message similar to the below.
   ```
   starting org.apache.spark.sql.hive.thriftserver.HiveThriftServer2, logging to /home/spark-2.4.3-bin-spark-2.4.3-bin-hadoop2.8/logs/spark--org.apache.spark.sql.hive.thriftserver.HiveThriftServer2-1-aa00aa00aa00.out
   ```
1. Wait around 10 seconds for the server to finish starting
1. Run `make spark-sql`, and wait for a SQL prompt to appear
   ```
   0: jdbc:hive2://localhost:10000/default>
   ```
1. Test your console is working by copy & pasting the following SQL
   ```sql
   SELECT lpi_key, uprn, longitude, latitude, import_year, import_month, import_day, import_date
   FROM `dataplatform-stg-raw-zone-unrestricted-address-api`.`unrestricted_address_api_dbo_hackney_address` LIMIT 10;
   ```

# Notebook Exporter Script
Included is a script `export_notebook.py` that will take Jupyter Notebook from the scripts directory and export them as
python files.

This is accomplished using a notebook reading and export python library combined with a Google developed code formatter.
The notebooks are read, and cells tagged with "remove" are dropped from the output. The resulting python is run through
the code formatter and exported to a file with the same name in an export directory.

To run the script you will need to `pip` install the following libraries
* nbconvert
* yapf

To run the script, pass the script to python.