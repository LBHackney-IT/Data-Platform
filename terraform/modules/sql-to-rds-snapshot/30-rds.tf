resource "aws_db_subnet_group" "default" {
  tags       = var.tags
  name       = var.instance_name
  subnet_ids = var.aws_subnet_ids
}

resource "aws_db_instance" "ingestion_db" {
  allocated_storage       = 15
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  identifier              = var.instance_name
  db_subnet_group_name    = aws_db_subnet_group.default.name

  username                = "dataplatform"
  password                = random_password.rds_password.result
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.snapshot_db.id]
  apply_immediately       = false
}

resource "random_password" "rds_password" {
  length  = 40
  special = false
}
