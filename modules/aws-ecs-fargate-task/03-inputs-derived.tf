locals {
  default_task_details = defaults(var.tasks, {
    task_prefix = ""
  })
}