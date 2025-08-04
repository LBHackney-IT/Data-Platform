# Use partition projection to create a table with partitions updated automatically, valid until 2045
resource "aws_glue_catalog_table" "cloudtrail_management_events" {
  name          = "cloudtrail_management_events"
  database_name = aws_glue_catalog_database.metastore.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2020,2045"
    "projection.year.interval"  = "1"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.interval" = "1"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.interval"   = "1"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${local.identifier_prefix}-cloudtrail/management-events/AWSLogs/${data.aws_caller_identity.data_platform.account_id}/CloudTrail/eu-west-2/$${year}/$${month}/$${day}/"
    "compressionType"           = "gzip"
    "classification"            = "cloudtrail"
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${local.identifier_prefix}-cloudtrail/management-events/AWSLogs/${data.aws_caller_identity.data_platform.account_id}/CloudTrail/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
    }

    columns {
      name = "eventVersion"
      type = "string"
    }

    columns {
      name = "userIdentity"
      type = "struct<type:string,principalId:string,arn:string,accountId:string,invokedBy:string,accessKeyId:string,userName:string,sessionContext:struct<attributes:struct<mfaAuthenticated:string,creationDate:string>,sessionIssuer:struct<type:string,principalId:string,arn:string,accountId:string,userName:string>,ec2RoleDelivery:string,webIdFederationData:struct<federatedprovider:string,attributes:map<string,string>>>>"
    }

    columns {
      name = "eventTime"
      type = "string"
    }

    columns {
      name = "eventSource"
      type = "string"
    }

    columns {
      name = "eventName"
      type = "string"
    }

    columns {
      name = "awsRegion"
      type = "string"
    }

    columns {
      name = "sourceIpAddress"
      type = "string"
    }

    columns {
      name = "userAgent"
      type = "string"
    }

    columns {
      name = "errorCode"
      type = "string"
    }

    columns {
      name = "errorMessage"
      type = "string"
    }

    columns {
      name = "requestParameters"
      type = "string"
    }

    columns {
      name = "responseElements"
      type = "string"
    }

    columns {
      name = "additionalEventData"
      type = "string"
    }

    columns {
      name = "requestId"
      type = "string"
    }

    columns {
      name = "eventId"
      type = "string"
    }

    columns {
      name = "resources"
      type = "array<struct<arn:string,accountid:string,type:string>>"
    }

    columns {
      name = "eventType"
      type = "string"
    }

    columns {
      name = "apiVersion"
      type = "string"
    }

    columns {
      name = "readOnly"
      type = "string"
    }

    columns {
      name = "recipientAccountId"
      type = "string"
    }

    columns {
      name = "serviceEventDetails"
      type = "string"
    }

    columns {
      name = "sharedEventID"
      type = "string"
    }

    columns {
      name = "vpcEndpointId"
      type = "string"
    }

    columns {
      name = "tlsDetails"
      type = "struct<tlsVersion:string,cipherSuite:string,clientProvidedHostHeader:string>"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_table" "glue_catalog_management_events_view" {
  name          = "glue_catalog_management_events"
  database_name = aws_glue_catalog_database.metastore.name
  table_type    = "VIRTUAL_VIEW"

  view_original_text = "/* Presto View: ${base64encode(jsonencode({
    originalSql = <<-EOF
SELECT
  eventVersion,
  userIdentity,
  eventTime,
  eventSource,
  eventName,
  awsRegion,
  sourceIpAddress,
  userAgent,
  errorCode,
  errorMessage,
  requestParameters,
  responseElements,
  additionalEventData,
  requestId,
  eventId,
  resources,
  eventType,
  apiVersion,
  readOnly,
  recipientAccountId,
  serviceEventDetails,
  sharedEventID,
  vpcEndpointId,
  tlsDetails,
  year,
  month,
  day,
  year  AS import_year,
  month AS import_month,
  day   AS import_day,
  concat(year, month, day) AS import_date,
  json_extract_scalar(requestParameters, '$.databaseName') AS database_name,
  json_extract_scalar(requestParameters, '$.tableName') AS table_name
FROM "${aws_glue_catalog_database.metastore.name}"."${aws_glue_catalog_table.cloudtrail_management_events.name}"
WHERE eventSource = 'glue.amazonaws.com'
  AND eventName IN (
    -- Database operations
    'CreateDatabase', 'GetDatabase', 'GetDatabases', 'UpdateDatabase', 'DeleteDatabase',
    -- Table operations
    'CreateTable', 'GetTable', 'GetTables', 'UpdateTable', 'DeleteTable',
    'GetTableVersion', 'GetTableVersions', 'DeleteTableVersion',
    -- Partition operations
    'CreatePartition', 'GetPartition', 'GetPartitions', 'UpdatePartition', 'DeletePartition',
    'GetPartitionIndexes', 'CreatePartitionIndex', 'DeletePartitionIndex',
    'BatchCreatePartition', 'BatchDeletePartition'
  )
EOF
    catalog     = "awsdatacatalog"
    schema      = aws_glue_catalog_database.metastore.name
    columns = [
      for col in concat(
        aws_glue_catalog_table.cloudtrail_management_events.storage_descriptor[0].columns,
        aws_glue_catalog_table.cloudtrail_management_events.partition_keys
        ) : {
        name = col.name
        type = col.type
      }
    ]
  }))} */"

  view_expanded_text = "/* Presto View */"

  storage_descriptor {
    dynamic "columns" {
      for_each = concat(
        aws_glue_catalog_table.cloudtrail_management_events.storage_descriptor[0].columns,
        aws_glue_catalog_table.cloudtrail_management_events.partition_keys
      )
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }
    columns {
      name = "import_year"
      type = "string"
    }
    columns {
      name = "import_month"
      type = "string"
    }
    columns {
      name = "import_day"
      type = "string"
    }
    columns {
      name = "import_date"
      type = "string"
    }
    columns {
      name = "database_name"
      type = "string"
    }
    columns {
      name = "table_name"
      type = "string"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
