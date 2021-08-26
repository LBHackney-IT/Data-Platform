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