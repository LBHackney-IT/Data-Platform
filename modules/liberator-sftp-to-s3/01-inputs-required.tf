variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "landing_zone_bucket_id" {
  description = "Bucket ID (Name) for the landing zone s3 bucket"
  type        = string
}

variable "landing_zone_bucket_arn" {
  description = "Bucket ARN for the landing zone s3 bucket"
  type        = string
}

variable "landing_zone_kms_key_arn" {
  description = "KMS Key ARN for the key that encrypts the landing zone s3 bucket"
  type        = string
}

