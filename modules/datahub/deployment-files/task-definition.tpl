[
  {
    "name": "${OPERATION_NAME}",
    "image": "${REPOSITORY_URL}:latest",
    "essential": true,
    "memory": 2048,
    "cpu": 256,
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
        "containerPort": 9002,
        "hostPort": 9002,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "PORT",
        "value": "9002"
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