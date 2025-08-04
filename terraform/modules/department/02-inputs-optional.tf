variable "google_group_display_name" {
  description = <<EOF
    The name of the google group that the departments permission set will be attached to.
    This permission set will hold a policy giving access to the departments relevent data and resources in the Data Platform.
    People in the department who need access to these resources can be added via the Google Groups interface.
    When creating a google group syncing with AWS SSO groups can take up to 2 hours.
    So after creation you need to wait before deploying this department module with the new group.
    If this isn't provided then this module won't setup an SSO permission set for the department.
  EOF
  type        = string
  default     = null
}

variable "google_group_admin_display_name" {
  description = <<EOF
    The google group display name for the admin group.
    If google_group_display_name is not set then this must be set.
    This will then be used to send emails to the admin group when the departments glue jobs fail.
  EOF
  type        = string
  default     = null
}

variable "notebook_instance" {
  description = "Include this block if you wish to setup a notebook instance for this department"
  type = object({
    github_repository = string
    extra_python_libs = string
    extra_jars        = string
  })
  default = null
}

variable "departmental_airflow_user" {
  description = "Flag to create departmental Airflow user"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "additional_s3_access" {
  description = <<EOF
    Additional s3 access to grant to the department.
    To grant access to specific paths, provide a list of strings for 'paths'.
    If 'paths' is null or an empty list, access will be granted to the entire bucket.
  EOF
  type = list(object({
    bucket_arn  = string
    kms_key_arn = string
    actions     = list(string)
    paths       = list(string)
  }))
  default = []
}

variable "cloudtrail_bucket" {
  description = "CloudTrail storage S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
  default = null
}
