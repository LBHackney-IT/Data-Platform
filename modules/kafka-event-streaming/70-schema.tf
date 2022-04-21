resource "aws_glue_registry" "schema_registry" {
  registry_name = "${var.short_identifier_prefix}schema-registry"
  tags          = var.tags
}

resource "aws_glue_schema" "tenure_api" {
  schema_name       = "${var.short_identifier_prefix}tenure-api"
  registry_arn      = aws_glue_registry.schema_registry.arn
  data_format       = "AVRO"
  compatibility     = "NONE"
  tags              = var.tags
  schema_definition = file("${path.module}/schemas/tenure_api.json")
}

data "aws_iam_policy_document" "get_schemas_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = concat(var.cross_account_lambda_roles, local.default_arn)
      type        = "AWS"
    }
  }
}

resource "aws_iam_role" "get_schemas_role" {
  tags               = var.tags
  name               = "${var.short_identifier_prefix}get-schemas-role"
  assume_role_policy = data.aws_iam_policy_document.get_schemas_assume_role.json
}

data "aws_iam_policy_document" "get_schemas" {
  statement {
    effect = "Allow"
    actions = [
      "glue:Get*"
    ]
    resources = [
      aws_glue_registry.schema_registry.arn,
      aws_glue_schema.tenure_api.arn
    ]
  }
}

resource "aws_iam_policy" "get_schemas" {
  tags = var.tags

  name   = "${var.short_identifier_prefix}get-schemas"
  policy = data.aws_iam_policy_document.get_schemas.json
}

resource "aws_iam_role_policy_attachment" "get_schemas" {
  role       = aws_iam_role.get_schemas_role.name
  policy_arn = aws_iam_policy.get_schemas.arn
}

module "schema_registry" {
  source            = "../kafka-schema-registry"
  tags              = var.tags
  environment       = var.environment
  identifier_prefix = var.short_identifier_prefix
  project           = var.project
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids
  bootstrap_servers = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
}