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
  default = []
}

variable "container_docker_labels" {
  description = "Adds the key/value pairs as docker labels to the container"
  type        = "map"
  default     = {}
}
