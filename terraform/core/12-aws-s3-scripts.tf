resource "aws_s3_bucket_object" "helpers" {
  bucket      = module.glue_scripts.bucket_id
  key         = "python-modules/data_platform_glue_job_helpers-1.0-py3-none-any.whl"
  acl         = "private"
  source      = "../../scripts/lib/data_platform_glue_job_helpers-1.0-py3-none-any.whl"
  source_hash = filemd5("../../scripts/lib/data_platform_glue_job_helpers-1.0-py3-none-any.whl")
}

resource "aws_s3_bucket_object" "jars" {
  bucket      = module.glue_scripts.bucket_id
  key         = "jars/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
  acl         = "private"
  source      = "../../external-lib/target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
  source_hash = filemd5("../../external-lib/target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar")
}

resource "aws_s3_bucket_object" "convertbng" {
  bucket      = module.glue_scripts.bucket_id
  key         = "python-modules/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
  acl         = "private"
  source      = "../../scripts/lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
  source_hash = filemd5("../../scripts/lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
}

resource "aws_s3_bucket_object" "pydeequ" {
  bucket      = module.glue_scripts.bucket_id
  key         = "python-modules/pydeequ-1.0.1.zip"
  acl         = "private"
  source      = "../../external-lib/target/pydeequ-1.0.1.zip"
  source_hash = filemd5("../../external-lib/target/pydeequ-1.0.1.zip")
}

resource "aws_s3_bucket_object" "deeque_jar" {
  bucket      = module.glue_scripts.bucket_id
  key         = "jars/deequ-1.0.3.jar"
  acl         = "private"
  source      = "../../external-lib/target/deequ-1.0.3.jar"
  source_hash = filemd5("../../external-lib/target/deequ-1.0.3.jar")
}

resource "aws_s3_bucket_object" "copy_tables_landing_to_raw" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/copy_tables_landing_to_raw.py"
  acl         = "private"
  source      = "../../scripts/jobs/copy_tables_landing_to_raw.py"
  source_hash = filemd5("../../scripts/jobs/copy_tables_landing_to_raw.py")
}

resource "aws_s3_bucket_object" "ingest_database_tables_via_jdbc_connection" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/ingest_database_tables_via_jdbc_connection.py"
  acl         = "private"
  source      = "../../scripts/jobs/ingest_database_tables_via_jdbc_connection.py"
  source_hash = filemd5("../../scripts/jobs/ingest_database_tables_via_jdbc_connection.py")
}

resource "aws_s3_bucket_object" "dynamodb_tables_ingest" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/ingest_tables_from_dynamo_db.py"
  acl         = "private"
  source      = "../../scripts/jobs/ingest_tables_from_dynamo_db.py"
  source_hash = filemd5("../../scripts/jobs/ingest_tables_from_dynamo_db.py")
}

resource "aws_s3_bucket_object" "copy_json_data_landing_to_raw" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/copy_json_data_landing_to_raw.py"
  acl         = "private"
  source      = "../../scripts/jobs/copy_json_data_landing_to_raw.py"
  source_hash = filemd5("../../scripts/jobs/copy_json_data_landing_to_raw.py")
}
  
resource "aws_s3_bucket_object" "hackney_bank_holiday" {
  bucket      = module.raw_zone.bucket_id
  key         = "unrestricted/util/hackney_bank_holiday.csv"
  acl         = "private"
  source      = "../../scripts/jobs/planning/hackney_bank_holiday.csv"
  source_hash = filemd5("../../scripts/jobs/planning/hackney_bank_holiday.csv")
}

