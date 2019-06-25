output "ecs_taskrole_name" {
  description = "The TaskRole for the service"
  value       = "${module.service.ecs_taskrole_name}"
}

output "environment_variables" {
  description = "The final environment vars passed to the task. Useful for debugging."
  value       = "${local.combined_environment_variables}"
}

output "settings" {
  description = "The final settings passed to Airship. Useful for debugging."
  value       = "${local.combined_settings}"
}

output "aws_ecs_task_definition_arn" {
  value = "${module.service.aws_ecs_task_definition_arn}"
}

output "aws_ecs_task_definition_family" {
  value = "${module.service.aws_ecs_task_definition_family}"
}

output "ecs_taskrole_arn" {
  value = "${module.service.ecs_taskrole_arn}"
}

output "has_changed" {
  value = "${module.service.has_changed}"
}

output "lb_target_group_arn" {
  value = "${module.service.lb_target_group_arn}"
}

output "task_execution_role_arn" {
  value = "${module.service.task_execution_role_arn}"
}
