variable "create" {
  description = "If true, the service will be created"
  default     = true
}

variable "name" {
  description = "The name of the project, must be unique and match"
}

variable "shared_settings" {
  description = <<EOF
    The are the settings that are typically shared between all services. If a value is present it the "settings" variable, it overrides the value here (if any). All values are REQUIRED.
    Sample:

    shared_service_settings = {
      environment_name   # The environment name, eg 'kitdev'
      lb_route53_zone_id # The zone to add a service subdomain to
      mgmt_account       # Id of the management account containing ECR images
      region             # Region of the ECS Cluster
    }
  EOF

  type = "map"
}

variable "settings" {
  description = <<EOF
    The are the settings that are typically shared between all services. If a value is present it the "settings" variable, it overrides the value here (if any).
    Sample:

    settings = {
      bootstrap_container_image # The docker image location. Set to USE_DEFAULT or give a docker image path with version label
      cloud_watch_metrics       # If true, expose Micrometer metrics in CloudWatch (default is false)      
      container_cpu             # Defines the needed cpu for the container (default is 256)
      container_memory          # Defines the hard memory limit of the container (default is 512)
      container_port            # Container port (default is 8080)
      image_version             # Docker image version (default is "latest"). This is only relavant if "bootstrap_container_image" is not set
      initial_capacity          # The desired amount of tasks for a service, when autoscaling is used desired_capacity is only used initially (default is 1)
      kms_keys                  # Comma separated list of KMS keys that the service can access (default is "")
      lb_health_uri             # Load balancer health check URL  (default is "/health")
      lb_healthy_threshold      # The number of consecutive successful health checks required before considering an unhealthy target healthy (default is 3)
      lb_redirect_http_to_https # Redirect all HTTP requests to HTTPS (default is true)
      lb_unhealthy_threshold    # The number of consecutive successful health checks required before considering an healthy target unhealthy (default is 3)
      load_balancing_type       # The load balancer type ("application"/"none"). (Default is "application")
      max_capacity              # When autoscaling is activated, it sets the maximum of tasks to be available for this service (default is 2)
      min_capacity              # When autoscaling is activated, it sets the minimum of tasks to be available for this service (default is 1)
      platform                  # Either FARGATE or EC2 (default is "FARGATE")
      s3_ro_paths               # Comma separated list of S3 Bucket/Prefixes that the service can access (default is "")
      s3_rw_paths               # Comma separated list of S3 Bucket/Prefixes that the service can access (default is "")
      ssm_paths                 # Comma separated list of SSM keys that the service can access (default is "")
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

variable "container_docker_labels" {
  description = "Adds the key/value pairs as docker labels to the container"
  type        = "map"
  default     = {}
}
