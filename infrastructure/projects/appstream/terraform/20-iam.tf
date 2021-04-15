# AppStream Infrastructure

## AppStream Infrastructure - Policy Attachments
resource "aws_iam_role_policy_attachment" "appstream_autoscaling_service_access_attach" {
  provider = aws.appstream

  role       = aws_iam_role.appstream_autoscaling_service_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ApplicationAutoScalingForAmazonAppStreamAccess"
}

resource "aws_iam_role_policy_attachment" "appstream_service_access_attach" {
  provider = aws.appstream

  role       = aws_iam_role.appstream_service_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAppStreamServiceAccess"
}

## AppStream Infrastructure - IAM Roles
resource "aws_iam_role" "appstream_autoscaling_service_access" {
  provider = aws.appstream

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "appstream.amazonaws.com"
        }
      },
    ]
  })
  name = "ApplicationAutoScalingForAmazonAppStreamAccess"
  path = "/service-role/"

  tags = module.tags.tags
}

resource "aws_iam_role" "appstream_service_access" {
  provider = aws.appstream

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "appstream.amazonaws.com"
        }
      },
    ]
  })
  name = "AmazonAppStreamServiceAccess"
  path = "/service-role/"

  tags = module.tags.tags
}

## AppStream Infrastructure - IAM Service Linked Roles
resource "aws_iam_service_linked_role" "appstream_autoscaling_appstream_fleet" {
  provider = aws.appstream

  aws_service_name = "appstream.application-autoscaling.amazonaws.com"
}
