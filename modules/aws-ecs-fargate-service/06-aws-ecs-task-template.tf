data "template_file" "task_definition_template" {
  template = jsonencode([
    {
      name : local.broker_properties.container_name,
      image : local.broker_properties.image_name,
      essential : true,
      memory : local.broker_properties.memory,
      cpu : local.broker_properties.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.datahub.name,
          awslogs-region : "eu-west-2",
          awslogs-stream-prefix : "${var.operation_name}${local.broker_properties.container_name}"
        }
      },
      portMappings : [
        {
          containerPort : local.broker_properties.port,
          hostPort : local.broker_properties.port,
          protocol : "tcp"
        }
      ],
      environment : local.broker_properties.environment_variables
    },
    {
      name : local.datahub_actions.container_name,
      image : local.datahub_actions.image_name,
      essential : true,
      memory : local.datahub_actions.memory,
      cpu : local.datahub_actions.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.datahub.name,
          awslogs-region : "eu-west-2",
          awslogs-stream-prefix : "${var.operation_name}${local.datahub_actions.container_name}"
        }
      },
      portMappings : [
        {
          containerPort : local.datahub_actions.port,
          hostPort : local.datahub_actions.port,
          protocol : "tcp"
        }
      ],
      environment : local.datahub_actions.environment_variables
    },
    {
      name : local.datahub_frontend_react_properties.container_name,
      image : local.datahub_frontend_react_properties.image_name,
      essential : true,
      memory : local.datahub_frontend_react_properties.memory,
      cpu : local.datahub_frontend_react_properties.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.datahub.name,
          awslogs-region : "eu-west-2",
          awslogs-stream-prefix : "${var.operation_name}${local.datahub_frontend_react_properties.container_name}"
        }
      },
      portMappings : [
        {
          containerPort : local.datahub_frontend_react_properties.port,
          hostPort : local.datahub_frontend_react_properties.port,
          protocol : "tcp"
        }
      ],
      environment : local.datahub_frontend_react_properties.environment_variables
    },
    {
      name : local.datahub_gms.container_name,
      image : local.datahub_gms.image_name,
      essential : true,
      memory : local.datahub_gms.memory,
      cpu : local.datahub_gms.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.datahub.name,
          awslogs-region : "eu-west-2",
          awslogs-stream-prefix : "${var.operation_name}${local.datahub_gms.container_name}"
        }
      },
      portMappings : [
        {
          containerPort : local.datahub_gms.port,
          hostPort : local.datahub_gms.port,
          protocol : "tcp"
        }
      ],
      environment : local.datahub_gms.environment_variables
    },
    {
      name : local.zookeeper.container_name,
      image : local.zookeeper.image_name,
      essential : true,
      memory : local.zookeeper.memory,
      cpu : local.zookeeper.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.datahub.name,
          awslogs-region : "eu-west-2",
          awslogs-stream-prefix : "${var.operation_name}${local.zookeeper.container_name}"
        }
      },
      portMappings : [
        {
          containerPort : local.zookeeper.port,
          hostPort : local.zookeeper.port,
          protocol : "tcp"
        }
      ],
      environment : local.zookeeper.environment_variables
    }
  ])
}