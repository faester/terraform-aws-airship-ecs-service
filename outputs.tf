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
