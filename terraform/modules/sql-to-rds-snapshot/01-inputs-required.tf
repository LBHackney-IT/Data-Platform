variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in a production environment for setting up automation"
  type        = bool
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "instance_name" {
  description = "Name of instance"
  type        = string
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ECS cluster ARN in which to run the task"
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "watched_bucket_name" {
  description = "Name of bucket which will be watched for new objects to convert"
  type        = string
}

variable "watched_bucket_kms_key_arn" {
  description = "KMS Key ARN for the watched bucket where new objects to convert are placed"
  type        = string
}

variable "aws_subnet_ids" {
  description = "Array of subnet IDs"
  type        = list(string)
}
