variable "role_arns_to_share_access_with" {
  description = "A list of role arns to enable cross account access"
  type        = list(string)
  default     = []
}

variable "bucket_policy_statements" {
  description = "A list of statements to be added to the bucket policy"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
    principals = object({
      type        = string
      identifiers = list(string)
    })
  }))

  validation {
    condition = length([
      for o in var.bucket_policy_statements : true
      if o.sid != null && o.sid != ""
    ]) == length(var.bucket_policy_statements)
    error_message = "Sid is required"
  }

  validation {
    condition = length([
      for o in var.bucket_policy_statements : true
      if contains(["Allow", "Deny"], o.effect)
    ]) == length(var.bucket_policy_statements)
    error_message = "Effect must be either Allow or Deny"
  }

  validation {
    condition = length([
      for o in var.bucket_policy_statements : true
      if length(o.actions) > 0
    ]) == length(var.bucket_policy_statements)
    error_message = "Actions list cannot be empty"
  }

  validation {
    condition = length([
      for o in var.bucket_policy_statements : true
      if length(o.resources) > 0
    ]) == length(var.bucket_policy_statements)
    error_message = "Resources cannot be empty"
  }

  validation {
    condition = length([
      for o in var.bucket_policy_statements : true
      if length(o.principals.identifiers) > 0
    ]) == length(var.bucket_policy_statements)
    error_message = "Principal identifiers must be provided"
  }

  validation {
    condition = length([
      for o in var.bucket_policy_statements : true
       if o.principals.type != null && o.principals.type != ""
    ]) == length(var.bucket_policy_statements)
    error_message = "Principal type must be provided"
  }
  #other principals object related checks are covered by default Terraform behaviour

  default = []
}

variable "bucket_key_policy_statements" {
  description = "A list of statements to be added to the bucket policy"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    principals = object({
      type        = string
      identifiers = list(string)
    })
  }))

  validation {
    condition = length([
      for o in var.bucket_key_policy_statements : true
      if o.sid != null && o.sid != ""
    ]) == length(var.bucket_key_policy_statements)
    error_message = "Sid is required"
  }

  validation {
    condition = length([
      for o in var.bucket_key_policy_statements : true
      if contains(["Allow", "Deny"], o.effect)
    ]) == length(var.bucket_key_policy_statements)
    error_message = "Effect must be either Allow or Deny"
  }

  validation {
    condition = length([
      for o in var.bucket_key_policy_statements : true
      if length(o.actions) > 0
    ]) == length(var.bucket_key_policy_statements)
    error_message = "Actions list cannot be empty"
  }

  validation {
    condition = length([
      for o in var.bucket_key_policy_statements : true
      if length(o.principals.identifiers) > 0
    ]) == length(var.bucket_key_policy_statements)
    error_message = "Principal identifiers must be provided"
  }

  validation {
    condition = length([
      for o in var.bucket_key_policy_statements : true
       if o.principals.type != null && o.principals.type != ""
    ]) == length(var.bucket_key_policy_statements)
    error_message = "Principal type must be provided"
  }
  #other principals object related checks are covered by default Terraform behaviour

  default = []
}


variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "expire_objects_days" {
  description = "Number of days after which to expire objects. Set to null to disable."
  type        = number
  default     = null
}


variable "expire_noncurrent_objects_days" {
  description = "Number of days after which to permanently delete noncurrent versions of objects, set to null to disable by default"
  type        = number
  default     = null
}

variable "abort_multipart_days" {
  description = "Number of days after which to abort incomplete multipart uploads, set to null to disable by default"
  type        = number
  default     = null
}

