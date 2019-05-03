variable "create" {
  description = "If true, the service will be created"
  default     = true
}

variable "shared_settings" {
  description = <<EOF
    The are the settings that are typically shared between all services. If a value is present it the "settings" variable, it overrides the value here (if any). All values are REQUIRED.
    Sample:

    shared_service_settings = {
      environment_name      = "..." # The environment name, eg 'kitdev'
      lb_route53_zone_id    = "..." # The zone to add a service subdomain to
      mgmt_account          = "..." # Id of the management account containing ECR images
      region                = "..." # Region of the ECS Cluster
    }
  EOF

  type = "map"
}

variable "settings" {
  description = <<EOF
    The are the settings that are typically shared between all services. If a value is present it the "settings" variable, it overrides the value here (if any).
    Sample:

    settings = {
      name                      = "..." # The name of the project, must be unique (REQUIRED)
      bootstrap_container_image = "..." # The docker image location. Set to USE_DEFAULT or give a docker image path with version label      
      container_cpu             = "..." # Defines the needed cpu for the container
      container_memory          = "..." # Defines the hard memory limit of the container
      container_port            = "..." # Container port
      initial_capacity          = "..." # The desired amount of tasks for a service, when autoscaling is used desired_capacity is only used initially
      kms_keys                  = "..." # Comma separated list of KMS keys that the service can access
      ssm_paths                 = "..." # Comma separated list of SSM keys that the service can access
      s3_ro_paths               = "..." # Comma separated list of S3 Bucket/Prefixes that the service can access
      s3_rw_paths               = "..." # Comma separated list of S3 Bucket/Prefixes that the service can access
      load_balancing_type       = "..." # The load balancer type ("application"/"none"). Defaults to "application"
      lb_health_uri             = "..." # Load balancer health check URL
      max_capacity              = "..." # When autoscaling is activated, it sets the maximum of tasks to be available for this service
      min_capacity              = "..." # When autoscaling is activated, it sets the minimum of tasks to be available for this service
      platform                  = "..." # Either FARGATE or EC2 (uppercase)
    }
  EOF

  type = "map"
}

variable "container_healthcheck" {
  description = <<EOF
    A custom container health check. Example:
    {
      command     = "curl --fail http://localhost:8090/health || exit 1"
      interval    = 10
      retries     = 3
      startPeriod = 30
    }
    Mostly relevant for services without web interface and LB helath check.
  EOF

  default = {}
}

variable "environment_variables" {
  description = "Environment variables fed to the container"
  default     = {}
}

variable "environment_secrets" {
  description = "Environment secrets fed to the container from SSM keys"
  default     = {}
}
