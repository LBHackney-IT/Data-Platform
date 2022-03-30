[
  {
    "name": "${OPERATION_NAME}",
    "image": "${REPOSITORY_URL}:latest",
    "essential": true,
    "memory": "${MEMORY}",
    "cpu": "${CPU}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${LOG_GROUP}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "${OPERATION_NAME}"
      }
    },
    "portMappings": [
      {
        "containerPort": "${PORT}",
        "hostPort": "${PORT}",
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "PORT",
        "value": "${PORT}"
      }
    ],
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 65536,
        "hardLimit": 65536
      }
    ],
    "mountPoints": [],
    "volumesFrom": []
  }
]