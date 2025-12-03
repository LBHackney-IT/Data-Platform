variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Prefix"
  type        = string
}

variable "subnet_ids_list" {
  description = "List of subnet ids"
  type        = list(string)
}

variable "vpc_id" {
  description = "Id of vpc"
  type        = string
}

variable "landing_zone_bucket_arn" {
  description = "ARN of landing zone bucket"
  type        = string
}

variable "refined_zone_bucket_arn" {
  description = "ARN of refined zone bucket"
  type        = string
}

variable "trusted_zone_bucket_arn" {
  description = "ARN of trusted zone bucket"
  type        = string
}

variable "raw_zone_bucket_arn" {
  description = "ARN of raw zone bucket"
  type        = string
}

variable "landing_zone_kms_key_arn" {
  description = "ARN of landing zone KMS key"
  type        = string
}

variable "refined_zone_kms_key_arn" {
  description = "ARN of refined zone KMS key"
  type        = string
}

variable "trusted_zone_kms_key_arn" {
  description = "ARN of trusted zone KMS key"
  type        = string
}

variable "raw_zone_kms_key_arn" {
  description = "ARN of raw zone KMS key"
  type        = string
}

variable "secrets_manager_key" {
  description = "ARN of secrets manager KMS key"
  type        = string
}

variable "user_uploads_bucket_arn" {
  description = "ARN of user uploads bucket"
  type        = string
}

variable "user_uploads_kms_key_arn" {
  description = "ARN of user uploads KMS key"
  type        = string
}
