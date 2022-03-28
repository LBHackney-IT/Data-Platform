locals {
  tasks = [for task in var.tasks : merge({ task_id = (task.task_prefix == null ? "" : task.task_prefix) }, task)]
}