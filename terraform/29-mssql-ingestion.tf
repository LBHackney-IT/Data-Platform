locals {
  glue_connection_url = "jdbc:sqlserver://mssql-ingestion-spike-db.cvtofzh2smx4.eu-west-2.rds.amazonaws.com:1433;databaseName=testDB"
  name = "rds-mssql"
  description = "JDBC connection to MS SQL database"
  subnet_id = "subnet-0c1bd8eaff9d7fd96" // how to get this programmatically
//  security_group_ids = ["sg-0820f868c8b40f01b"]
  db_availability_zone = "eu-west-2a"
  database_name = "testDB"
  subnet_ids_string = join(",", data.aws_subnet_ids.all.ids)
  subnet_ids_list_mssql = split(",", local.subnet_ids_string)
}

// jdbc:sqlserver://10.120.30.77:1433;databaseName=LBHATestDB

// tested deployed connection - currently failing - need to investigate
// ALSO THE TEST RDS GLUE CONNECTION (CREATED IN CONSOLE) TO THE RDS INSTANCE FAILS

// add to outputs: aws_glue_connection.mssql.name (for consumption by Glue job) using connection

// username & password from parameter store

resource "aws_glue_connection" "mssql" {
  tags = module.tags.values

  name = "${local.short_identifier_prefix}${local.name}-connection"
  description = local.description
  connection_properties = {
    JDBC_CONNECTION_URL = local.glue_connection_url
    PASSWORD            = var.test_db_password
    USERNAME            = var.test_db_username
  }

  physical_connection_requirements {
    availability_zone      = local.db_availability_zone
    security_group_id_list = [aws_security_group.mssql_connection.id]
    subnet_id              = local.subnet_ids_list[local.subnet_ids_random_index]
  }
}

// ms sql database needs to accept traffic from this sg (academy insight db already grants access)
// tested connection and it works

resource "aws_security_group" "mssql_connection" {
  tags = module.tags.values

  name = "${local.short_identifier_prefix}mssql-connection-sg"
  vpc_id = data.aws_vpc.network.id
}

resource "aws_security_group_rule" "mssql_allow_tcp_ingress" {
  type              = "ingress"
  description       = "Self referencing rule"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.mssql_connection.id // Which group to attach it to
  self              = true
}

resource "aws_security_group_rule" "mssql_allow_tcp_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.mssql_connection.id
}

resource "aws_glue_catalog_database" "mssql_catalog_db" {
  name = "${local.short_identifier_prefix}${local.name}-catalog-database"
}

resource "aws_glue_crawler" "mssql_connection" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.mssql_catalog_db.name
  name          = "${local.short_identifier_prefix}${local.name}-crawler"
  role          = aws_iam_role.glue_connection_crawler_role.arn

  jdbc_target {
    connection_name = aws_glue_connection.mssql.name
    path            = "${local.database_name}/%"
  }
  table_prefix = "${local.name}_"

  depends_on = [
    aws_glue_connection.mssql
  ]
}

data "aws_iam_policy_document" "glue_connection_crawler_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "glue_connection_crawler_role" {
  tags = module.tags.values

  name               = "${local.identifier_prefix}-glue-connection-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.glue_connection_crawler_role.json
}

// get vpc subnet ids
data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.network.id
}
// trying to give crawler access to each subnet
// data.aws_subnet.selected[each.key]

data "aws_subnet" "each" {
  count = length(local.subnet_ids_list)
  id    = local.subnet_ids_list[count.index]
}

data "aws_iam_policy_document" "crawler_can_access_glue_catalog_database" {
  statement {
    effect = "Allow"
    actions = [
      "glue:CreateTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",
      // "glue:DeleteTable", // do we want this?
      "glue:GetConnection",
      "glue:GetConnections",
      "glue:UpdateConnection",
      "glue:UpdateDatabase",
      "glue:UpdatePartition",
      "glue:UpdateTable",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVPCs",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = [
      aws_glue_catalog_database.mssql_catalog_db.arn,
      "${aws_glue_catalog_database.mssql_catalog_db.arn}/*",
      aws_glue_connection.mssql.arn,
      "${data.aws_vpc.network.arn}/*",
      data.aws_vpc.network.arn,
      data.aws_subnet.each[0].arn,
      data.aws_subnet.each[1].arn,
      data.aws_subnet.each[2].arn,
      aws_security_group.mssql_connection.arn,
      aws_glue_connection.mssql.arn,
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:instance/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    condition {
      test = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["aws-glue-service-resource"]
    }
    condition { // might not be needed
      test = "ForAllValues:StringEquals"
      variable = "aws:sourceVpc"
      values = [data.aws_vpc.network.id]
    }
    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
      aws_security_group.mssql_connection.arn,
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:instance/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "crawler_can_access_glue_catalog_database" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-crawler-can-access-glue-catalog-database")
  policy = data.aws_iam_policy_document.crawler_can_access_glue_catalog_database.json
}

resource "aws_iam_role_policy_attachment" "crawler_can_access_glue_catalog_database" {
  role       = aws_iam_role.glue_connection_crawler_role.name
  policy_arn = aws_iam_policy.crawler_can_access_glue_catalog_database.arn
}