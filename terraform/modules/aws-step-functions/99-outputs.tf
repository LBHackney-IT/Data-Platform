output "arn" {
  description = "value of the step function arn"
  value       = aws_sfn_state_machine.step_function.arn
}