resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags       = {
        Name = var.instance_name
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "pub_subnet" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.0.0/24"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "priv_subnet_a" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "priv_subnet_b" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = data.aws_availability_zones.available.names[1]
}

resource "aws_route_table" "egress_only" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }
}

resource "aws_route_table_association" "route_table_association" {
    subnet_id      = aws_subnet.pub_subnet.id
    route_table_id = aws_route_table.egress_only.id
}

resource "aws_security_group" "ecs_sg" {
    vpc_id      = aws_vpc.vpc.id

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_ecr_repository" "worker" {
    name  = "${var.instance_name}"
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name  = "${var.instance_name}"
}

data "template_file" "task_definition_template" {
  template = file("${path.module}/task_definition_template.json")
  vars = {
    REPOSITORY_URL = aws_ecr_repository.worker.repository_url
    LOG_GROUP = aws_cloudwatch_log_group.ecs.name
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.instance_name}"
  container_definitions = data.template_file.task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.fargate.arn
}

resource "aws_iam_role" "fargate" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-fargate")
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fargate_ecs_task_execution_attachment" {
  role = aws_iam_role.fargate.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  tags = var.tags

  name = "${var.instance_name}-ecs"
}

resource "aws_db_subnet_group" "default" {
  tags       = var.tags
  name       = var.instance_name
  subnet_ids = [aws_subnet.priv_subnet_a.id, aws_subnet.priv_subnet_b.id]
}

resource "aws_db_instance" "ingestion_db" {
  allocated_storage     = 5
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  identifier            = var.instance_name
  db_subnet_group_name  = aws_db_subnet_group.default.name

  // FIXME: Use something better for passwords here.
  username              = "thisisalsowhymysqlsucks"
  password              = random_password.rds_password.result
}

resource "random_password" "rds_password" {
  length           = 40
  special          = false
}

resource "aws_cloudwatch_event_target" "yada" {
  target_id = var.instance_name
  arn       = aws_ecs_cluster.ecs_cluster.arn
  rule      = aws_cloudwatch_event_rule.new_s3_object.name
  role_arn  = aws_iam_role.execute_task.arn


  ecs_target {
    task_count          = 1
    launch_type         = "FARGATE"
    task_definition_arn = aws_ecs_task_definition.task_definition.arn
    # name            = "${var.instance_name}"
    network_configuration {
        subnets          = [aws_subnet.pub_subnet.id]
        assign_public_ip = true
    }
  }
}

resource "aws_cloudwatch_event_rule" "new_s3_object" {
  name        = "${var.instance_name}-new-s3-object"
  description = "Fires when a new S3 Object is placed in a bucket"
  event_pattern = jsonencode({
    "source": [
      "aws.s3"
    ],
    "detail-type": [
      "AWS API Call via CloudTrail"
    ],
    "detail": {
      "eventSource": [
        "s3.amazonaws.com"
      ],
      "eventName": [
        "PutObject"
      ],
      "requestParameters": {
        "bucketName": [
          var.watched_bucket_name
        ]
      }
    }
  })
}

resource "aws_iam_role" "execute_task" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-execute-task")
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}
