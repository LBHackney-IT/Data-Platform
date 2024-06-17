data "aws_secretsmanager_secret" "redshift_serverless_connection" {
  name = "/data-and-insight/redshift-serverless-connection"
}

data "aws_secretsmanager_secret_version" "redshift_serverless_connection" {
  secret_id = data.aws_secretsmanager_secret.redshift_serverless_connection.id
}

locals {
  redshift_serverless_credentials = jsondecode(data.aws_secretsmanager_secret_version.redshift_serverless_connection.secret_string)
}

# Option 1: using existing module, it works well, but launch so many other resources
# module "database_ingestion_via_jdbc_connection" {
#   count                        = local.is_live_environment && !local.is_production_environment ? 1 : 0
#   tags                         = module.tags.values
#   source                       = "../modules/database-ingestion-via-jdbc-connection"
#   name                         = "redshift-serverless-connection"
#   jdbc_connection_url          = "jdbc:redshift://${local.redshift_serverless_credentials["host"]}:${local.redshift_serverless_credentials["port"]}/${local.redshift_serverless_credentials["database_name"]}"
#   jdbc_connection_description  = "JDBC connection for Redshift Serverless"
#   jdbc_connection_subnet       = data.aws_subnet.network[local.instance_subnet_id]
#   database_secret_name         = "/data-and-insight/redshift-serverless-connection"
#   identifier_prefix            = local.short_identifier_prefix
# }


# option 2: tailored for this module
resource "aws_glue_connection" "database_ingestion_via_jdbc_connection" {
  count       = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name        = "${local.short_identifier_prefix}redshift-serverless-connection-${data.aws_subnet.network[local.instance_subnet_id].availability_zone}"
  description = "JDBC connection for Redshift Serverless"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:redshift://${local.redshift_serverless_credentials["host"]}:${local.redshift_serverless_credentials["port"]}/${local.redshift_serverless_credentials["database_name"]}"
    PASSWORD            = local.redshift_serverless_credentials["password"]
    USERNAME            = local.redshift_serverless_credentials["username"]
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.network[local.instance_subnet_id].availability_zone
    security_group_id_list = [aws_security_group.ingestion_database_connection.id]
    subnet_id              = data.aws_subnet.network[local.instance_subnet_id].id
  }

}

resource "aws_security_group" "ingestion_database_connection" {
  name   = "${local.short_identifier_prefix}redshift-serverless-glue-connection"
  vpc_id = data.aws_subnet.network[local.instance_subnet_id].vpc_id
  tags   = module.tags.values
}

resource "aws_security_group_rule" "ingestion_database_connection_allow_tcp_ingress" {
  type              = "ingress"
  description       = "Self referencing rule"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.ingestion_database_connection.id
  self              = true
}

resource "aws_security_group_rule" "ingestion_database_connection_allow_tcp_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ingestion_database_connection.id
}


module "load_all_academy_data_into_redshift" {
  count                          = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags                           = module.tags.values
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  job_name                       = "${local.short_identifier_prefix}load_all_academy_data_into_redshift"
  script_s3_object_key           = aws_s3_object.load_all_academy_data_into_redshift.key
  pydeequ_zip_key                = aws_s3_object.pydeequ.key
  helper_module_key              = aws_s3_object.helpers.key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  glue_version                   = "4.0"
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 2
  glue_job_timeout               = 220
  schedule                       = "cron(15 7 ? * MON-FRI *)"
  # jdbc_connections                = [module.database_ingestion_via_jdbc_connection[0].name]
  jdbc_connections = [aws_glue_connection.database_ingestion_via_jdbc_connection[0].name]
  job_parameters = {
    "--additional-python-modules" = "botocore==1.27.59, redshift_connector==2.1.0"
    "--environment"               = var.environment
    # This is the ARN of the IAM role used by Redshift Serverless. We have count in redshift-serverless module so index 0 is to get the ARN.
    "--role_arn"            = try(module.redshift_serverless[0].redshift_serverless_role_arn, "")
    "--enable-auto-scaling" = "false"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--base_s3_url"         = "${module.raw_zone.bucket_url}/revenues/"
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}