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

variable "redshift_cidr_ingress_rules_for_bi_tools" {
  description = "Array of CIDR based ingress rules for Redshift security group allowing access from BI tools"
  type        = list
  sensitive   = true
}

# variable "redshift_cidr_ingress_rules_for_qlik" {
#   description = "Array of CIDR based ingress rules for Redshift security group allowing access from Qlik EC2 instance"
#   type        = list
#   sensitive   = true
# }

# variable "redshift_sg_ingress_rules_for_qlik" {
#   description = "Array of security group based ingress rules for Redshift security group allowing access from Qlik EC2 instance"
#   type        = list
#   sensitive   = true
# }
