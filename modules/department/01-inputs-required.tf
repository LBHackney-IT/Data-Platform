variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "landing_zone_bucket_id" {
  description = "Landing zone S3 bucket id"
  type        = string
}

variable "raw_zone_bucket_id" {
  description = "Raw zone S3 bucket id"
  type        = string
}

variable "refined_zone_bucket_id" {
  description = "Refined zone S3 bucket id"
  type        = string
}

variable "trusted_zone_bucket_id" {
  description = "Trusted zone S3 bucket id"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "identifier" {
  description = "A url safe, lowercase identifier for the department"
  type = string
}

