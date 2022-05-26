data "aws_iam_policy_document" "jdbc_connection_crawler_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "jdbc_connection_crawler_role" {
  tags = var.tags

  name               = "${var.identifier_prefix}${local.iam_role_name}-crawler-can-access-jdbc-connection"
  assume_role_policy = data.aws_iam_policy_document.jdbc_connection_crawler_role.json
}

resource "aws_iam_role_policy_attachment" "crawler_can_access_jdbc_connection" {
  role       = aws_iam_role.jdbc_connection_crawler_role.name
  policy_arn = aws_iam_policy.crawler_can_access_jdbc_connection.arn
}
