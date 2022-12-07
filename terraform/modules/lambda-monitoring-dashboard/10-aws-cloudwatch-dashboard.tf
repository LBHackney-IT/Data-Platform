resource "aws_cloudwatch_dashboard" "lambda_alarms" {
  dashboard_name = "${var.identifier_prefix}lambda-alarms"

  dashboard_body = <<EOF
{
     "widgets": [
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 0,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "DataPlatform", "${var.identifier_prefix}sftp-to-s3-lambda-errors" ]
                ],
                "region": "eu-west-2"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "DataPlatform", "${var.identifier_prefix}icaseworks-api-ingestion-errors" ]
                ],
                "region": "eu-west-2"
            }
        }
    ]
}
EOF
}
