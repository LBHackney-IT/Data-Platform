variable "department" {
  description = "Name of the department"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "policy" {
  description = "IAM policy for the department"
  type        = string
}
