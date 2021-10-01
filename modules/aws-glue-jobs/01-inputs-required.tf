variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "department" {
  description = "The department with all its properties"
  type        = string
}

variable "job_name" {
  description = "Name of the AWS glue job"
  type        = string
}

variable "job_description" {
  description = "A description of the AWS glue job"
  type        = string
}
