data "aws_iam_policy_document" "sso_trusted_relationship" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::484466746276:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AWSAdministratorAccess_2cff52f8dbae1fd6",
        "arn:aws:iam::120038763019:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AWSAdministratorAccess_89cef605035aecd1"
      ]
      type = "AWS"
    }
    actions = [
      "sts:AssumeRole",
      "sts:AssumeRoleWithSAML",
      "sts:TagSession"
    ]
  }
}

// Parking S3 Access Policy
data "aws_iam_policy_document" "parking_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "kms:ListAliases",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "KmsKeyAccess"
    effect = "Allow"
    actions = [
      //      CancelKeyDeletion
      //      ConnectCustomKeyStore
      //      CreateAlias
      //      CreateCustomKeyStore
      //      CreateGrant
      //      CreateKey
      //      Decrypt
      //      DeleteAlias
      //      DeleteCustomKeyStore
      //      DeleteImportedKeyMaterial
      //      DescribeCustomKeyStores
      //      DescribeKey
      //      DisableKey
      //      DisableKeyRotation
      //      DisconnectCustomKeyStore
      //      EnableKey
      //      EnableKeyRotation
      //      Encrypt
      //      GenerateDataKey
      //      GenerateDataKeyPair
      //      GenerateDataKeyPairWithoutPlaintext
      //      GenerateDataKeyWithoutPlaintext
      //      GenerateRandom
      //      GetKeyPolicy
      //      GetKeyRotationStatus
      //      GetParametersForImport
      //      GetPublicKey
      //      ImportKeyMaterial
      //      ListAliases
      //      ListGrants
      //      ListKeyPolicies
      //      ListKeys
      //      ListResourceTags
      //      ListRetirableGrants
      //      PutKeyPolicy
      //      ReEncryptFrom
      //      ReEncryptTo
      //      RetireGrant
      //      RevokeGrant
      //      ScheduleKeyDeletion
      //      Sign
      //      TagResource
      //      UntagResource
      //      UpdateAlias
      //      UpdateCustomKeyStore
      //      UpdateKeyDescription
      //      Verify
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      module.landing_zone.kms_key_arn,
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn,
      module.athena_storage.kms_key_arn
    ]
  }

  statement {
    sid    = "ReadAndWrite"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:GetAccelerateConfiguration",
      "s3:GetAccessPoint",
      "s3:GetAccessPointConfigurationForObjectLambda",
      "s3:GetAccessPointForObjectLambda",
      "s3:GetAccessPointPolicy",
      "s3:GetAccessPointPolicyForObjectLambda",
      "s3:GetAccessPointPolicyStatus",
      "s3:GetAccessPointPolicyStatusForObjectLambda",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetJobTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:GetReplicationConfiguration",
      "s3:GetStorageLensConfiguration",
      "s3:GetStorageLensConfigurationTagging",
      "s3:GetStorageLensDashboard",
      // "s3:ListAccessPoints",
      // "s3:ListAccessPointsForObjectLambda",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListJobs",
      "s3:ListMultipartUploadParts",
      "s3:ListStorageLensConfigurations",
      // "s3:ObjectOwnerOverrideToBucketOwner",
      // "s3:PutAccelerateConfiguration",
      // "s3:PutAccessPointConfigurationForObjectLambda",
      // "s3:PutAccessPointPolicy",
      // "s3:PutAccessPointPolicyForObjectLambda",
      // "s3:PutAccountPublicAccessBlock",
      // "s3:PutAnalyticsConfiguration",
      // "s3:PutBucketAcl",
      // "s3:PutBucketCORS",
      // "s3:PutBucketLogging",
      // "s3:PutBucketNotification",
      // "s3:PutBucketObjectLockConfiguration",
      // "s3:PutBucketOwnershipControls",
      // "s3:PutBucketPolicy",
      // "s3:PutBucketPublicAccessBlock",
      // "s3:PutBucketRequestPayment",
      // "s3:PutBucketTagging",
      // "s3:PutBucketVersioning",
      // "s3:PutBucketWebsite",
      // "s3:PutEncryptionConfiguration",
      // "s3:PutIntelligentTieringConfiguration",
      // "s3:PutInventoryConfiguration",
      // "s3:PutJobTagging",
      // "s3:PutLifecycleConfiguration",
      // "s3:PutMetricsConfiguration",
      "s3:PutObject",
      // "s3:PutObjectAcl",
      // "s3:PutObjectLegalHold",
      // "s3:PutObjectRetention",
      // "s3:PutObjectTagging",
      // "s3:PutObjectVersionAcl",
      // "s3:PutObjectVersionTagging",
      // "s3:PutReplicationConfiguration",
      // "s3:PutStorageLensConfiguration",
      // "s3:PutStorageLensConfigurationTagging",
    ]
    resources = [
      module.refined_zone.bucket_arn,
      "${module.refined_zone.bucket_arn}/parking/*",
      module.trusted_zone.bucket_arn,
      "${module.trusted_zone.bucket_arn}/parking/*",
      module.athena_storage.bucket_arn,
      "${module.athena_storage.bucket_arn}/parking/*",
      "${module.landing_zone.bucket_arn}/parking/manual/*"
    ]
  }

  statement {
    sid    = "DeleteObject"
    effect = "Allow"
    actions = [
      "s3:DeleteObject"
    ]
    resources = [
      "${module.landing_zone.bucket_arn}/parking/manual/*",
      "${module.raw_zone.bucket_arn}/parking/manual/*",
      "${module.refined_zone.bucket_arn}/parking/*"
    ]
  }

  statement {
    sid    = "ReadOnly"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/parking/*",
      module.landing_zone.bucket_arn,
      "${module.landing_zone.bucket_arn}/parking/*",
    ]
  }

  statement {
    sid    = "List"
    effect = "Allow"
    actions = [
      "s3:List*"
    ]
    resources = [
      module.glue_temp_storage.bucket_arn,
      module.glue_scripts.bucket_arn,
    ]
  }

  statement {
    sid    = "FullAccess"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${module.glue_scripts.bucket_arn}/custom/*",
    ]
  }
}

resource "aws_iam_policy" "parking_s3_access" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-parking-s3-access")
  policy = data.aws_iam_policy_document.parking_s3_access.json
}

// Read only policy for glue scripts
data "aws_iam_policy_document" "read_only_access_to_glue_scripts" {
  statement {
    sid    = "ReadOnly"
    effect = "Allow"
    actions = [
      "s3:Get*",
    ]
    resources = [
      "${module.glue_scripts.bucket_arn}/*"
    ]
  }

  statement {
    effect = "DecryptGlueScripts"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.glue_scripts.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "read_glue_scripts" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-read-glue-scripts")
  policy = data.aws_iam_policy_document.read_only_access_to_glue_scripts.json
}

//Parking glue access policy
data "aws_iam_policy_document" "power_user_parking_glue_access" {
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
      aws_iam_role.parking_glue.arn
    ]
  }

  statement {
    sid = "AllowRolePassingToGlueJobs"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.parking_glue.arn
    ]
    condition {
      test     = "StringLike"
      values   = ["glue.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }

  // Glue Access
  statement {
    sid = "AwsGlue"
    actions = [
      "glue:BatchCreatePartition",
      "glue:BatchDeleteConnection",
      "glue:BatchDeletePartition",
      "glue:BatchDeleteTable",
      "glue:BatchDeleteTableVersion",
      "glue:BatchGetCrawlers",
      "glue:BatchGetDevEndpoints",
      "glue:BatchGetJobs",
      "glue:BatchGetPartition",
      "glue:BatchGetTriggers",
      "glue:BatchGetWorkflows",
      "glue:BatchStopJobRun",
      //      "glue:CancelMLTaskRun",
      "glue:CheckSchemaVersionValidity",
      //      "glue:CreateClassifier",
      //      "glue:CreateConnection",
      //      "glue:CreateCrawler",
      "glue:CreateDag",
      //      "glue:CreateDatabase",
      //      "glue:CreateDevEndpoint",
      "glue:CreateJob",
      //      "glue:CreateMLTransform",
      //      "glue:CreatePartition",
      //      "glue:CreateRegistry",
      //      "glue:CreateSchema",
      "glue:CreateScript",
      //      "glue:CreateSecurityConfiguration",
      //      "glue:CreateTable",
      "glue:CreateTrigger",
      //      "glue:CreateUserDefinedFunction",
      //      "glue:CreateWorkflow",
      //      "glue:DeleteClassifier",
      //      "glue:DeleteConnection",
      //      "glue:DeleteCrawler",
      //      "glue:DeleteDatabase",
      //      "glue:DeleteDevEndpoint",
      "glue:DeleteJob",
      //      "glue:DeleteMLTransform",
      //      "glue:DeletePartition",
      //      "glue:DeleteRegistry",
      //      "glue:DeleteResourcePolicy",
      //      "glue:DeleteSchema",
      //      "glue:DeleteSchemaVersions",
      //      "glue:DeleteSecurityConfiguration",
      //      "glue:DeleteTable",
      //      "glue:DeleteTableVersion",
      //      "glue:DeleteTrigger",
      //      "glue:DeleteUserDefinedFunction",
      //      "glue:DeleteWorkflow",
      "glue:GetCatalogImportStatus",
      "glue:GetClassifier",
      "glue:GetClassifiers",
      "glue:GetConnection",
      "glue:GetConnections",
      "glue:GetCrawler",
      "glue:GetCrawlerMetrics",
      "glue:GetCrawlers",
      "glue:GetDag",
      "glue:GetDataCatalogEncryptionSettings",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetDataflowGraph",
      "glue:GetDevEndpoint",
      "glue:GetDevEndpoints",
      "glue:GetInferredSchema",
      "glue:GetJob",
      "glue:GetJobBookmark",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:GetJobs",
      //      "glue:GetMLTaskRun",
      //      "glue:GetMLTaskRuns",
      //      "glue:GetMLTransform",
      //      "glue:GetMLTransforms",
      "glue:GetMapping",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetPlan",
      "glue:GetRegistry",
      "glue:GetResourcePolicies",
      "glue:GetResourcePolicy",
      "glue:GetSchema",
      "glue:GetSchemaByDefinition",
      "glue:GetSchemaVersion",
      "glue:GetSchemaVersionsDiff",
      "glue:GetSecurityConfiguration",
      "glue:GetSecurityConfigurations",
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
      "glue:GetTables",
      "glue:GetTags",
      "glue:GetTrigger",
      "glue:GetTriggers",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions",
      "glue:GetWorkflow",
      "glue:GetWorkflowRun",
      "glue:GetWorkflowRunProperties",
      "glue:GetWorkflowRuns",
      //      "glue:ImportCatalogToGlue",
      "glue:ListCrawlers",
      "glue:ListDevEndpoints",
      "glue:ListJobs",
      "glue:ListMLTransforms",
      "glue:ListRegistries",
      "glue:ListSchemaVersions",
      "glue:ListSchemas",
      "glue:ListTriggers",
      "glue:ListWorkflows",
      //      "glue:PutDataCatalogEncryptionSettings",
      //      "glue:PutResourcePolicy",
      //      "glue:PutSchemaVersionMetadata",
      //      "glue:PutWorkflowRunProperties",
      //      "glue:QuerySchemaVersionMetadata",
      //      "glue:RegisterSchemaVersion",
      //      "glue:RemoveSchemaVersionMetadata",
      "glue:ResetJobBookmark",
      //      "glue:ResumeWorkflowRun",
      "glue:SearchTables",
      "glue:StartCrawler",
      "glue:StartCrawlerSchedule",
      "glue:StartExportLabelsTaskRun",
      "glue:StartImportLabelsTaskRun",
      "glue:StartJobRun",
      //      "glue:StartMLEvaluationTaskRun",
      //      "glue:StartMLLabelingSetGenerationTaskRun",
      //      "glue:StartTrigger",
      //      "glue:StartWorkflowRun",
      "glue:StopCrawler",
      "glue:StopCrawlerSchedule",
      "glue:StopTrigger",
      "glue:StopWorkflowRun",
      "glue:TagResource",
      //      "glue:UntagResource",
      //      "glue:UpdateClassifier",
      //      "glue:UpdateConnection",
      //      "glue:UpdateCrawler",
      //      "glue:UpdateCrawlerSchedule",
      "glue:UpdateDag",
      //      "glue:UpdateDatabase",
      //      "glue:UpdateDevEndpoint",
      "glue:UpdateJob",
      //      "glue:UpdateMLTransform",
      //      "glue:UpdatePartition",
      //      "glue:UpdateRegistry",
      //      "glue:UpdateSchema",
      //      "glue:UpdateTable",
      "glue:UpdateTrigger",
      //      "glue:UpdateUserDefinedFunction",
      //      "glue:UpdateWorkflow",
      //      "glue:UseMLTransforms",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "power_user_parking_glue_access" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-power-user-parking-glue-access")
  policy = data.aws_iam_policy_document.power_user_parking_glue_access.json
}

// Parking secrets policy
data "aws_iam_policy_document" "parking_secrets_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.redshift_cluster_parking_credentials.arn,
      module.department_parking.google_service_account.credentials_secret.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.secrets_manager_key.arn
    ]
  }
}

resource "aws_iam_policy" "parking_secrets_read_only" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-parking-secrets-read-only")
  policy = data.aws_iam_policy_document.parking_secrets_read_only.json
}

// Power user role + attachments
resource "aws_iam_role" "power_user_parking" {
  tags = module.tags.values

  name               = lower("${local.identifier_prefix}-power-user-parking")
  assume_role_policy = data.aws_iam_policy_document.sso_trusted_relationship.json
}

resource "aws_iam_role_policy_attachment" "power_user_parking_s3_access" {
  role       = aws_iam_role.power_user_parking.name
  policy_arn = aws_iam_policy.parking_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "power_user_parking_glue_access" {
  role       = aws_iam_role.power_user_parking.name
  policy_arn = aws_iam_policy.power_user_parking_glue_access.arn
}

resource "aws_iam_role_policy_attachment" "parking_secrets_read_only" {
  role       = aws_iam_role.power_user_parking.name
  policy_arn = aws_iam_policy.parking_secrets_read_only.arn
}

// Glue role + attachments
resource "aws_iam_role" "parking_glue" {
  tags = module.tags.values

  name               = lower("${local.identifier_prefix}-parking-glue")
  assume_role_policy = data.aws_iam_policy_document.glue_role.json
}

resource "aws_iam_role_policy_attachment" "parking_glue_s3_access" {
  role       = aws_iam_role.parking_glue.name
  policy_arn = aws_iam_policy.parking_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "parking_glue_access" {
  role       = aws_iam_role.parking_glue.name
  policy_arn = aws_iam_policy.full_glue_access.arn
}

resource "aws_iam_role_policy_attachment" "parking_glue_access_to_cloudwatch" {
  role       = aws_iam_role.parking_glue.name
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "parking_read_glue_scripts" {
  role       = aws_iam_role.parking_glue.name
  policy_arn = aws_iam_policy.read_glue_scripts.arn
}

resource "aws_iam_role_policy_attachment" "parking_glue_secrets_read_only" {
  role       = aws_iam_role.parking_glue.name
  policy_arn = aws_iam_policy.parking_secrets_read_only.arn
}