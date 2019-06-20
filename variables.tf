variable "create" {
  description = "If true, the service will be created"
  default     = true
}

variable "name" {
  description = "The name of the project, must be unique and match"
}

variable "shared_settings" {
  description = "These are the settings that are shared between all services"
  type        = "map"
}

variable "settings" {
  description = "If a value is present it the `settings` variable, it overrides the value from `shared_settings`"
  type        = "map"
}

variable "container_healthcheck" {
  description = "A custom container health check."
  default     = {}
}

variable "environment_variables" {
  description = "Environment variables fed to the container"
  default     = {}
}

variable "ssm_vars" {
  description = "A list of SSM variables that will be wired in as environment vars. Names should be lowercase, and use underscores instead of dots"
  default     = []
}

variable "container_docker_labels" {
  description = "Adds the key/value pairs as docker labels to the container"
  type        = "map"
  default     = {}
}

variable "scaling_rules" {
  description = " Autoscaling is enabled by default. It will scale based on average CPU consumption. Scale up look at cpu consumption in two consecutive observations with 5 minutes intervals. Scale down requires 4 consecutive observices with 4 minute * intervals. Default scale up threshold is 89 % cpu usage, while scale down threshold is 10 %. Scaling adds or removes 1 instance for each scaling event."

  default = [
    {
      type               = "CPUUtilization"
      direction          = "up"
      evaluation_periods = "2"
      observation_period = "300"
      statistic          = "Average"
      threshold          = "89"
      cooldown           = "900"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = "1"
    },
    {
      type               = "CPUUtilization"
      direction          = "down"
      evaluation_periods = "4"
      observation_period = "300"
      statistic          = "Average"
      threshold          = "10"
      cooldown           = "300"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = "-1"
    },
  ]

  type = "list"
}
