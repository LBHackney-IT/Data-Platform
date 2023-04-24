data "aws_iam_policy_document" "department_data_and_insight_all_zones_read_access_policy" {
  statement {
    sid    = "AllowReadAccessToAllZones"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      module.landing_zone.bucket_arn,
      "${module.landing_zone.bucket_arn}/*",
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/*",
      module.refined_zone.bucket_arn,
      "${module.refined_zone.bucket_arn}/*",
      module.trusted_zone.bucket_arn,
      "${module.trusted_zone.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "department_data_and_insight_all_zones_read_access_policy" {
  tags = module.tags.values

  name   = "${local.identifier_prefix}-department-data-and-insight-all-zones-read-access"
  policy = data.aws_iam_policy_document.department_data_and_insight_all_zones_read_access_policy.json
}

resource "aws_iam_policy_attachment" "department_data_and_insight_all_zones_read_access_policy" {
  name       = "${local.identifier_prefix}-department-data-and-insight-all-zones-read-access-policy"
  roles      = [module.department_data_and_insight.glue_role_name]
  policy_arn = aws_iam_policy.department_data_and_insight_all_zones_read_access_policy.arn
}
