resource "aws_db_instance" "datahub" {
  allocated_storage    = 15
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "datahub"
  identifier           = "${var.short_identifier_prefix}datahub"
  password             = random_password.datahub_secret.result
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "default" {
  tags       = var.tags
  name       = "${var.short_identifier_prefix}datahub"
  subnet_ids = data.aws_subnet_ids.subnet_ids.ids
}