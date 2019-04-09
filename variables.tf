variable "create" {
  description = "If true, the service will be created"
  default     = true
}

variable "shared_settings" {
  description = <<EOF
    The are the settings that are typically shared between all services. If a value is present it the "settings" variable, it overrides the value here (if any). All values are REQUIRED.
    Sample:

    shared_service_settings = {
      ecs_cluster_id        = "..." # The cluster to which the ECS Service will be added
      environment_name      = "..." # The environment name, eg 'kitdev'
      lb_arn                = "..." # The arn of the ALB being used
      lb_listener_arn       = "..." # The ALB listener arn for HTTP
      lb_listener_arn_https = "..." # The ALB listener arn for HTTPS
      lb_route53_zone_id    = "..." # The zone to add a service subdomain to
      lb_sg_id              = "..." # The security group for the load balancer
      lb_vpc_id             = "..." # The vpc_id for the target_group to reside in
      mgmt_account          = "..." # Id of the management account containing ECR images
      region                = "..." # Region of the ECS Cluster
      vpc_private_subnets   = "..." # Private subnets for services as a comman separated list
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
