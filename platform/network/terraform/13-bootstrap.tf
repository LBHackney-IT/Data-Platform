#************************************************************************************
# CREATE 2 S3 BUCKETS FOR FW1 & FW2
#************************************************************************************
resource "random_string" "randomstring" {
  provider = random
  length      = 25
  min_lower   = 15
  min_numeric = 10
  special     = false
}

resource "aws_s3_bucket" "bootstrap_bucket_fw_a" {
  provider = aws.ss_primary
  bucket        =  format("fw-a-bootstrap-%s-%s", lower(var.environment), random_string.randomstring.result)
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags = merge(
  module.tags.values,
  {
    "Name" = format("fw-a-bootstrap-%s-%s", lower(var.environment), random_string.randomstring.result)
  }
  )
}

resource "aws_s3_bucket" "bootstrap_bucket_fw_b" {
  provider = aws.ss_primary
  bucket        = format("fw-b-bootstrap-%s-%s", lower(var.environment), random_string.randomstring.result)
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags = merge(
  module.tags.values,
  {
    "Name" = format("fw-b-bootstrap-%s-%s", lower(var.environment), random_string.randomstring.result)
  }
  )
}

#************************************************************************************
# Download bootstrap from secret manager for FW1 and FW2
#************************************************************************************
data "aws_secretsmanager_secret" "fw_a_bootstrap_1_secret" {
  provider = aws.ss_primary
  name = "fw-a-bootstrap-1"
}

data "aws_secretsmanager_secret" "fw_a_bootstrap_2_secret" {
  count    =  var.extended_bootstrap ? 1 : 0
  provider = aws.ss_primary
  name     = "fw-a-bootstrap-2"
}

data "aws_secretsmanager_secret_version" "fw_a_bootstrap_1_secret_version" {
  provider = aws.ss_primary
  secret_id = data.aws_secretsmanager_secret.fw_a_bootstrap_1_secret.id
}

data "aws_secretsmanager_secret_version" "fw_a_bootstrap_2_secret_version" {
  count    =  var.extended_bootstrap ? 1 : 0
  provider = aws.ss_primary
  secret_id = element(data.aws_secretsmanager_secret.fw_a_bootstrap_2_secret.*.id, count.index)
}

resource "local_file" "fw_a_bootstrap_xml_1" {
  count    =  var.extended_bootstrap ? 1 : 0
  content = data.aws_secretsmanager_secret_version.fw_a_bootstrap_1_secret_version.secret_string
  filename = "fw_a_bootstrap_joined.xml"

}

resource "local_file" "fw_a_bootstrap_xml_2" {
  count    =  var.extended_bootstrap ? 1 : 0
  content = element(data.aws_secretsmanager_secret_version.fw_a_bootstrap_2_secret_version.*.secret_string, count.index)
  filename = "fw_a_bootstrap_joined_1.xml"
}

resource "null_resource" "fw_a_bootstrap_merge" {
  count    =  var.extended_bootstrap ? 1 : 0
  provisioner "local-exec" {
    command = "cat fw_a_bootstrap_joined_1.xml >> fw_a_bootstrap_joined.xml"
  }
}

resource "local_file" "fw_a_bootstrap_xml" {
  count    =  var.extended_bootstrap ? 0 : 1
  content = data.aws_secretsmanager_secret_version.fw_a_bootstrap_1_secret_version.secret_string
  filename = "fw_a_bootstrap.xml"
}


### FW B
data "aws_secretsmanager_secret" "fw_b_bootstrap_1_secret" {
  provider = aws.ss_primary
  name = "fw-b-bootstrap-1"
}

data "aws_secretsmanager_secret" "fw_b_bootstrap_2_secret" {
  count    =  var.extended_bootstrap ? 1 : 0
  provider = aws.ss_primary
  name = "fw-b-bootstrap-2"
}

data "aws_secretsmanager_secret_version" "fw_b_bootstrap_1_secret_version" {
  provider = aws.ss_primary
  secret_id = data.aws_secretsmanager_secret.fw_b_bootstrap_1_secret.id
}

data "aws_secretsmanager_secret_version" "fw_b_bootstrap_2_secret_version" {
  count    =  var.extended_bootstrap ? 1 : 0
  provider = aws.ss_primary
  secret_id = element(data.aws_secretsmanager_secret.fw_b_bootstrap_2_secret.*.id, count.index)
}

resource "local_file" "fw_b_bootstrap_xml_1" {
  count    =  var.extended_bootstrap ? 1 : 0
  content = data.aws_secretsmanager_secret_version.fw_b_bootstrap_1_secret_version.secret_string
  filename = "fw_b_bootstrap_joined.xml"
}

resource "local_file" "fw_b_bootstrap_xml_2" {
  count    =  var.extended_bootstrap ? 1 : 0
  content = element(data.aws_secretsmanager_secret_version.fw_b_bootstrap_2_secret_version.*.secret_string, count.index)
  filename = "fw_b_bootstrap_joined_1.xml"
}

resource "null_resource" "fw_b_bootstrap_merge" {
  count    =  var.extended_bootstrap ? 1 : 0
  provisioner "local-exec" {
    command = "cat fw_b_bootstrap_joined_1.xml >> fw_b_bootstrap_joined.xml"
  }
}


resource "local_file" "fw_b_bootstrap_xml" {
  count    =  var.extended_bootstrap ? 0 : 1
  content = data.aws_secretsmanager_secret_version.fw_b_bootstrap_1_secret_version.secret_string
  filename = "fw_b_bootstrap.xml"
}

#************************************************************************************
# Update init-cfg for each instance
#************************************************************************************

resource "local_file" "fw-a-init-cfg-tpl" {
  content = templatefile("../bootstrap_files/fw1/init-cfg.tpl", {
    fw_host = format("hub-%s-a", lower(var.environment))
  })
  filename = "fw_a_init-cfg.txt"
}

resource "local_file" "fw-b-init-cfg-tpl" {
  content = templatefile("../bootstrap_files/fw1/init-cfg.tpl", {
    fw_host = format("hub-%s-b", lower(var.environment))
  })
  filename = "fw_b_init-cfg.txt"
}

#************************************************************************************
# Generate and store password for the instances
#************************************************************************************

resource "random_string" "fw_password" {
  provider = random
  length      = 25
  min_lower   = 10
  min_numeric = 10
  min_upper   = 3
  min_special = 2
  special     = true
}

resource "aws_secretsmanager_secret" "pa_credentials" {
  provider = aws.ss_primary
  name = format("%s_%s_admin_password", var.application, var.environment)
  tags = module.tags.values
}

resource "aws_secretsmanager_secret_version" "pa_credentials" {
  provider = aws.ss_primary

  secret_id     = aws_secretsmanager_secret.pa_credentials.id
  secret_string = random_string.fw_password.result
}

#************************************************************************************
# CREATE FW1 DIRECTORIES & UPLOAD FILES FROM /bootstrap_files/fw1 DIRECTORY
#************************************************************************************
resource "aws_s3_bucket_object" "bootstrap_xml_joined_a" {
  count    =  var.extended_bootstrap ? 1 : 0
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_a.id
  acl    = "private"
  key    = "config/bootstrap.xml"
  source = "fw_a_bootstrap_joined.xml"
  etag   = md5(format("%s\r%s", data.aws_secretsmanager_secret_version.fw_a_bootstrap_1_secret_version.secret_string, element(data.aws_secretsmanager_secret_version.fw_a_bootstrap_2_secret_version.*.secret_string, count.index)))
}

resource "aws_s3_bucket_object" "bootstrap_xml_a" {
  count    =  var.extended_bootstrap ? 0 : 1
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_a.id
  acl    = "private"
  key    = "config/bootstrap.xml"
  source = "fw_a_bootstrap.xml"
  etag   = md5(data.aws_secretsmanager_secret_version.fw_a_bootstrap_1_secret_version.secret_string)
}

resource "aws_s3_bucket_object" "init-cft_txt_a" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_a.id
  acl    = "private"
  key    = "config/init-cfg.txt"
  source = "fw_a_init-cfg.txt"
  etag   = md5(local_file.fw-a-init-cfg-tpl.content)
}

resource "aws_s3_bucket_object" "software_a" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_a.id
  acl    = "private"
  key    = "software/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "license_a" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_a.id
  acl    = "private"
  key    = "license/authcodes"
  source = "../bootstrap_files/fw1/authcodes"
  etag   = filemd5("../bootstrap_files/fw2/authcodes")
}

resource "aws_s3_bucket_object" "conten_a" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_a.id
  acl    = "private"
  key    = "content/"
  source = "/dev/null"
}


#************************************************************************************
# CREATE FW2 DIRECTORIES & UPLOAD FILES FROM /bootstrap_files/fw2 DIRECTORY
#************************************************************************************
resource "aws_s3_bucket_object" "bootstrap_xml_joined_b" {
  count    =  var.extended_bootstrap ? 1 : 0
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_b.id
  acl    = "private"
  key    = "config/bootstrap.xml"
  source = "fw_b_bootstrap_joined.xml"
  etag   = md5(format("%s\r%s", data.aws_secretsmanager_secret_version.fw_b_bootstrap_1_secret_version.secret_string, element(data.aws_secretsmanager_secret_version.fw_b_bootstrap_2_secret_version.*.secret_string, count.index)))

}

resource "aws_s3_bucket_object" "bootstrap_xml_b" {
  count    =  var.extended_bootstrap ? 0 : 1
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_b.id
  acl    = "private"
  key    = "config/bootstrap.xml"
  source = "fw_b_bootstrap.xml"
  etag   = md5(data.aws_secretsmanager_secret_version.fw_b_bootstrap_1_secret_version.secret_string)

}

resource "aws_s3_bucket_object" "init-cft_txt_b" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_b.id
  acl    = "private"
  key    = "config/init-cfg.txt"
  source = "fw_b_init-cfg.txt"
  etag   = md5(local_file.fw-b-init-cfg-tpl.content)
}

resource "aws_s3_bucket_object" "software_b" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_b.id
  acl    = "private"
  key    = "software/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "license_b" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_b.id
  acl    = "private"
  key    = "license/authcodes"
  source = "../bootstrap_files/fw2/authcodes"
  etag   = filemd5("../bootstrap_files/fw2/authcodes")

}

resource "aws_s3_bucket_object" "content_b" {
  provider = aws.ss_primary
  bucket = aws_s3_bucket.bootstrap_bucket_fw_b.id
  acl    = "private"
  key    = "content/"
  source = "/dev/null"
}


#************************************************************************************
# CREATE & ASSIGN IAM ROLE, POLICY, & INSTANCE PROFILE
#************************************************************************************
resource "aws_iam_role" "bootstrap_role" {
  provider = aws.ss_primary
  name = "ngfw_bootstrap_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = module.tags.values

}

resource "aws_iam_role_policy" "bootstrap_policy" {
  provider = aws.ss_primary
  name = "ngfw_bootstrap_policy"
  role = aws_iam_role.bootstrap_role.id

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap_bucket_fw_a.id}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap_bucket_fw_a.id}/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap_bucket_fw_b.id}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap_bucket_fw_b.id}/*"
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "bootstrap_profile" {
  provider = aws.ss_primary
  name = "ngfw_bootstrap_profile"
  role = aws_iam_role.bootstrap_role.name
  path = "/"
}
