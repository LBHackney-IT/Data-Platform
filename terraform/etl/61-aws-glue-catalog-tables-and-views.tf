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
      name = "eventversion"
      type = "string"
    }

    columns {
      name = "useridentity"
      type = "struct<type:string,principalid:string,arn:string,accountid:string,invokedby:string,accesskeyid:string,username:string,sessioncontext:struct<attributes:struct<mfaauthenticated:string,creationdate:string>,sessionissuer:struct<type:string,principalid:string,arn:string,accountid:string,username:string>,ec2roledelivery:string,webidfederationdata:struct<federatedprovider:string,attributes:map<string,string>>>>"
    }

    columns {
      name = "eventtime"
      type = "string"
    }

    columns {
      name = "eventsource"
      type = "string"
    }

    columns {
      name = "eventname"
      type = "string"
    }

    columns {
      name = "awsregion"
      type = "string"
    }

    columns {
      name = "sourceipaddress"
      type = "string"
    }

    columns {
      name = "useragent"
      type = "string"
    }

    columns {
      name = "errorcode"
      type = "string"
    }

    columns {
      name = "errormessage"
      type = "string"
    }

    columns {
      name = "requestparameters"
      type = "string"
    }

    columns {
      name = "responseelements"
      type = "string"
    }

    columns {
      name = "additionaleventdata"
      type = "string"
    }

    columns {
      name = "requestid"
      type = "string"
    }

    columns {
      name = "eventid"
      type = "string"
    }

    columns {
      name = "resources"
      type = "array<struct<arn:string,accountid:string,type:string>>"
    }

    columns {
      name = "eventtype"
      type = "string"
    }

    columns {
      name = "apiversion"
      type = "string"
    }

    columns {
      name = "readonly"
      type = "string"
    }

    columns {
      name = "recipientaccountid"
      type = "string"
    }

    columns {
      name = "serviceeventdetails"
      type = "string"
    }

    columns {
      name = "sharedeventid"
      type = "string"
    }

    columns {
      name = "vpcendpointid"
      type = "string"
    }

    columns {
      name = "tlsdetails"
      type = "struct<tlsversion:string,ciphersuite:string,clientprovidedhostheader:string>"
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
  eventversion,
  useridentity,
  eventtime,
  eventsource,
  eventname,
  awsregion,
  sourceipaddress,
  useragent,
  errorcode,
  errormessage,
  requestparameters,
  responseelements,
  additionaleventdata,
  requestid,
  eventid,
  resources,
  eventtype,
  apiversion,
  readonly,
  recipientaccountid,
  serviceeventdetails,
  sharedeventid,
  vpcendpointid,
  tlsdetails,
  year,
  month,
  day,
  year  AS import_year,
  month AS import_month,
  day   AS import_day,
  concat(year, month, day) AS import_date,
  json_extract_scalar(requestparameters, '$.databasename') AS database_name,
  json_extract_scalar(requestparameters, '$.tablename') AS table_name
FROM "${aws_glue_catalog_database.metastore.name}"."${aws_glue_catalog_table.cloudtrail_management_events.name}"
WHERE eventsource = 'glue.amazonaws.com'
  AND eventname IN (
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
