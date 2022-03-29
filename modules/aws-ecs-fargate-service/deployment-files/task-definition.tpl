[
  {
    "name": "${OPERATION_NAME}",
    "image": "${REPOSITORY_URL}:latest",
    "environment": "${ENVIRONMENT_VARIABLES}",
    "essential": true,
    "memory": 4000,
    "cpu": 256,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${LOG_GROUP}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "${OPERATION_NAME}"
      }
    }
  }
]