variable "workgroup_base_capacity" {
  description = "Base capacity of the workgroup in Redshift Processing Units (RPUs)"
  type        = number
  default     = 32
}


# variable "maximimum_query_execution_time" {
#   description = "Max query execution time (in seconds)"
#   type        = number
#   default     = 3600
# }
