resource "aws_s3_bucket_object" "google_sheets_import_script" {
  tags = module.tags.values

  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key    = "scripts/google-sheets-import.py"
  acl    = "private"
  source = "../scripts/google-sheets-import.py"
  etag   = filemd5("../scripts/google-sheets-import.py")
}

data "aws_glue_script" "glue_script_template_to_raw" {
  language = "PYTHON"

  dag_edge {
    source = "DataSource0"
    target = "DataSink0"
  }

  dag_node {
    id = "DataSource0"
    node_type = "DataSource"

    args {
      name = "connection_type"
      value = "s3"
    }

    args {
      name = "format"
      value = "parquet"
    }

    args {
      name = "connection_options"
      value = "{\"paths\": [\"s3://${module.landing_zone.bucket_id}/job-template-script.csv\"], \"recurse\":True}"
    }

    args {
      name = "transformation_ctx"
      value = "DataSource0"
    }
  }

  dag_node {
    id = "DataSink0"
    node_type = "DataSink"

    args {
      name = "connection_type"
      value = "s3"
    }

    args {
      name = "format"
      value = "csv"
    }

    args {
      name = "connection_options"
      value = "{\"path\": [\"s3://${module.raw_zone.bucket_id}/job-template-script/\", \"partitionKeys\": []}"
    }

    args {
      name = "transformation_ctx"
      value = "DataSink0"
    }
  }
}

output "python_script" {
  value = data.aws_glue_script.glue_script_template_to_raw.python_script
}

