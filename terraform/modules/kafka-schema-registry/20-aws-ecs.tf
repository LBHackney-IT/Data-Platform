locals {
  taskCommand = <<COMMAND
curl $ECS_CONTAINER_METADATA_URI_V4 > ecs.json;
export HOST_IP=$(python -c "import json; f = open('ecs.json').read(); data = json.loads(f); print(data['Networks'][0]['IPv4Addresses'][0])");
export HOST_PORT=$(python -c "import json; f = open('ecs.json').read(); data = json.loads(f); print(data['Ports'][0]['HostPort'])");
export SCHEMA_REGISTRY_HOST_NAME=$HOSTNAME;
export SCHEMA_REGISTRY_LISTENERS="http://$HOST_IP:8081";
/etc/confluent/docker/run
COMMAND
}

resource "aws_ecs_cluster" "schema_registry" {
  name = "${var.identifier_prefix}kafka-schema-registry"
  tags = var.tags
}

data "aws_iam_policy_document" "schema_registry" {
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

resource "aws_iam_role" "schema_registry" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}kafka-schema-registry")
  assume_role_policy = data.aws_iam_policy_document.schema_registry.json
}

resource "aws_iam_role_policy_attachment" "schema_registry" {
  role       = aws_iam_role.schema_registry.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "schema_registry" {
  family                   = "${var.identifier_prefix}kafka-schema-registry"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 1024
  //task_role_arn            = aws_iam_role.schema_registry.arn
  execution_role_arn = aws_iam_role.schema_registry.arn

  container_definitions = jsonencode([
    {
      name       = "schema-registry"
      image      = "confluentinc/cp-schema-registry:5.3.0"
      essential  = true
      entryPoint = ["sh", "-c"]
      command    = [local.taskCommand]
      environment = [
        { name = "SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_METHODS", value = "GET,POST,PUT,OPTIONS" },
        { name = "SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_ORIGIN", value = "*" },
        { name = "SCHEMA_REGISTRY_DEBUG", value = "true" },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS", value = var.bootstrap_servers },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_SECURITY_PROTOCOL", value = "SSL" }
      ]
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.kafka_schema_registry.name,
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_security_group" "schema_registry_service" {
  name                   = "${var.identifier_prefix}schema-registry-service"
  description            = "Restricts access to the Schema Registry ECS Service"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "Allows inbound traffic from Datahub Generalized Metadata Service (GMS)"
    from_port       = 8081
    to_port         = 8081
    protocol        = "TCP"
    security_groups = [var.datahub_gms_security_group_id]
  }

  ingress {
    description     = "Allows inbound traffic from Datahub Metadata Audit Event (MAE)"
    from_port       = 8081
    to_port         = 8081
    protocol        = "TCP"
    security_groups = [var.datahub_mae_consumer_security_group_id]
  }

  ingress {
    description     = "Allows inbound traffic from Datahub Metadata Change Event (MCE)"
    from_port       = 8081
    to_port         = 8081
    protocol        = "TCP"
    security_groups = [var.datahub_mce_consumer_security_group_id]
  }

  ingress {
    description     = "Allows inbound traffic from Kafka"
    from_port       = 8081
    to_port         = 8081
    protocol        = "TCP"
    security_groups = [var.kafka_security_group_id]
  }

  ingress {
    description     = "Allow inbound traffic from schema registry ALB"
    from_port       = 8081
    to_port         = 8081
    protocol        = "TCP"
    security_groups = [var.schema_registry_alb_security_group_id]
  } 

  tags = merge(var.tags, {
    "Name" : "Schema Registry ECS Service"
  })
}

resource "aws_ecs_service" "schema_registry" {
  name            = "${var.identifier_prefix}kafka-schema-registry"
  cluster         = aws_ecs_cluster.schema_registry.id
  task_definition = aws_ecs_task_definition.schema_registry.arn
  desired_count   = 2
  //iam_role        = aws_iam_role.schema_registry.arn

  launch_type = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnet.subnets.*.id
    security_groups  = [aws_security_group.schema_registry_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.schema_registry.arn
    container_name   = "schema-registry"
    container_port   = 8081
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
