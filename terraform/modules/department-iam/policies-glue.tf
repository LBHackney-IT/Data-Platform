// =============================================================================
// GLUE ACCESS POLICIES  
// =============================================================================

// Glue read only access policy
data "aws_iam_policy_document" "read_only_glue_access" {
  statement {
    effect = "Allow"
    actions = [
      "athena:*",
      "logs:DescribeLogGroups",
      "tag:GetResources",
      "iam:ListRoles",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }

  // Glue Access
  statement {
    sid       = "AwsGlueGlobal"
    actions   = local.glue_global_actions
    resources = ["*"]
  }

  statement {
    sid       = "DepartmentalGlueDbReadOnly"
    effect    = "Allow"
    actions   = local.glue_database_read_actions
    resources = local.glue_departmental_resources
  }
}

resource "aws_iam_policy" "read_only_glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-read-only-glue-access")
  policy = data.aws_iam_policy_document.read_only_glue_access.json
}

// Departmental Glue access policy
data "aws_iam_policy_document" "glue_access" {
  statement {
    effect = "Allow"
    actions = [
      "athena:*",
      "logs:DescribeLogGroups",
      "tag:GetResources",
      "iam:ListRoles",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }

  statement {
    sid    = "RolePermissions"
    effect = "Allow"
    actions = [
      "iam:GetRole",
    ]
    resources = [
      aws_iam_role.glue_agent.arn
    ]
  }

  statement {
    sid = "AllowRolePassingToGlueJobs"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.glue_agent.arn
    ]
    condition {
      test     = "StringLike"
      values   = ["glue.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }

  // Glue Access
  statement {
    sid = "AwsGlueGlobal"
    actions = concat(local.glue_global_actions, [
      "glue:CreateDevEndpoint",
      "glue:CreateJob",
      "glue:CreateScript",
      "glue:CreateSession",
      "glue:DeleteDevEndpoint",
      "glue:DeleteJob",
      "glue:DeleteTrigger",
      "glue:ResetJobBookmark",
      "glue:StartCrawler",
      "glue:StartCrawlerSchedule",
      "glue:StartExportLabelsTaskRun",
      "glue:StartImportLabelsTaskRun",
      "glue:StartJobRun",
      "glue:StartWorkflowRun",
      "glue:StopCrawler",
      "glue:StopCrawlerSchedule",
      "glue:StopTrigger",
      "glue:StopWorkflowRun",
      "glue:TagResource",
      "glue:UpdateDevEndpoint",
      "glue:UpdateJob"
    ])
    resources = ["*"]
  }

  statement {
    sid       = "DepartmentalGlueDbReadWrite"
    effect    = "Allow"
    actions   = concat(local.glue_database_read_actions, local.glue_database_write_actions)
    resources = local.glue_departmental_resources
  }
}

resource "aws_iam_policy" "glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-glue-access")
  policy = data.aws_iam_policy_document.glue_access.json
}

// Glue Agent full access
data "aws_iam_policy_document" "full_glue_access" {
  statement {
    effect = "Allow"
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "full_glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-full-glue-access")
  policy = data.aws_iam_policy_document.full_glue_access.json
}

//Glue agent policy needed for dev endpoint
data "aws_iam_policy_document" "full_s3_access_to_glue_resources" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::crawler-public*",
      "arn:aws:s3:::aws-glue*"
    ]
  }
}

resource "aws_iam_policy" "full_s3_access_to_glue_resources" {
  tags = var.tags

  name   = "${var.identifier_prefix}-${var.department_identifier}-full-s3-access-to-glue-resources"
  policy = data.aws_iam_policy_document.full_s3_access_to_glue_resources.json
}

// Crawler can access JDBC Glue connection
data "aws_iam_policy_document" "crawler_can_access_jdbc_connection" {
  statement {
    effect = "Allow"
    actions = [
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
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["aws-glue-service-resource"]
    }
    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:instance/*",
    ]
  }
}

resource "aws_iam_policy" "crawler_can_access_jdbc_connection" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-crawler-can-access-jdbc-connection")
  policy = data.aws_iam_policy_document.crawler_can_access_jdbc_connection.json
}

// Glue Agent write to cloudwatch policy
data "aws_iam_policy_document" "glue_can_write_to_cloudwatch" {
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

resource "aws_iam_policy" "glue_can_write_to_cloudwatch" {
  tags = var.tags

  name   = "${var.identifier_prefix}-${var.department_identifier}-glue-cloudwatch"
  policy = data.aws_iam_policy_document.glue_can_write_to_cloudwatch.json
}

//glue-watermarks dynamodb access
data "aws_iam_policy_document" "glue_access_to_watermarks_table" {
  statement {
    sid    = "ListAndDescribe"
    effect = "Allow"
    actions = [
      "dynamodb:List*",
      "dynamodb:DescribeReservedCapacity*",
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "SpecificTable"
    effect = "Allow"
    actions = [
      "dynamodb:BatchGet*",
      "dynamodb:DescribeStream",
      "dynamodb:DescribeTable",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWrite*",
      "dynamodb:CreateTable",
      #"dynamodb:Delete*",
      "dynamodb:Update*",
      "dynamodb:PutItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.short_identifier_prefix}glue-watermarks"]
  }
}

resource "aws_iam_policy" "glue_access_to_watermarks_table" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-glue-can-access-wartermarks-table")
  policy = data.aws_iam_policy_document.glue_access_to_watermarks_table.json
}

// Glue Agent Read only policy for glue scripts and mwaa bucket and run athena
data "aws_iam_policy_document" "read_glue_scripts_and_mwaa_and_athena" {
  statement {
    sid    = "GlueAthenaAccess"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:ListDatabases",
      "athena:ListTableMetadata",
      "athena:GetTableMetadata",
      "athena:GetWorkGroup",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GlueScriptsReadOnly"
    effect = "Allow"
    actions = [
      "s3:Get*"
    ]
    resources = [
      "${var.bucket_configs.glue_scripts_bucket.bucket_arn}/*"
    ]
  }

  statement {
    sid    = "DecryptGlueScripts"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.bucket_configs.glue_scripts_bucket.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "read_glue_scripts_and_mwaa_and_athena" {
  name        = lower("${var.identifier_prefix}-${var.department_identifier}-read-glue-scripts-and-mwaa-and-athena")
  description = "IAM policy for Glue scripts read-only, specific Athena actions, and read access to MWAA S3 bucket"
  tags        = var.tags

  policy = data.aws_iam_policy_document.read_glue_scripts_and_mwaa_and_athena.json
}