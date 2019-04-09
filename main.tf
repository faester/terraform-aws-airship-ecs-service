locals {
  combined_settings = "${merge(var.shared_settings,var.settings)}"

  bootstrap_container_image = "${lookup(local.combined_settings, "bootstrap_container_image", "USE_DEFAULT")}"
  container_cpu             = "${lookup(local.combined_settings, "container_cpu", 256)}"
  container_memory          = "${lookup(local.combined_settings, "container_memory", 512)}"
  container_port            = "${lookup(local.combined_settings, "container_port", 8080)}"
  ecs_cluster_id            = "${lookup(local.combined_settings, "ecs_cluster_id")}"
  environment_name          = "${lookup(local.combined_settings, "environment_name")}"
  initial_capacity          = "${lookup(local.combined_settings, "initial_capacity", 1)}"
  load_balancing_type       = "${lookup(local.combined_settings, "load_balancing_type", "application")}"
  lb_arn                    = "${lookup(local.combined_settings, "lb_arn")}"
  lb_health_uri             = "${lookup(local.combined_settings, "lb_health_uri", "/health")}"
  lb_listener_arn           = "${lookup(local.combined_settings, "lb_listener_arn")}"
  lb_listener_arn_https     = "${lookup(local.combined_settings, "lb_listener_arn_https")}"
  lb_route53_zone_id        = "${lookup(local.combined_settings, "lb_route53_zone_id")}"
  lb_sg_id                  = "${lookup(local.combined_settings, "lb_sg_id")}"
  lb_vpc_id                 = "${lookup(local.combined_settings, "lb_vpc_id")}"
  max_capacity              = "${lookup(local.combined_settings, "max_capacity", 2)}"
  mgmt_account              = "${lookup(local.combined_settings, "mgmt_account")}"
  min_capacity              = "${lookup(local.combined_settings, "min_capacity", 1)}"
  name                      = "${lookup(local.combined_settings, "name", "")}"
  platform                  = "${lookup(local.combined_settings, "platform", "EC2")}"
  region                    = "${lookup(local.combined_settings, "region")}"
  vpc_private_subnets       = "${split(",", lookup(local.combined_settings, "vpc_private_subnets"))}"

  docker_image = "${local.bootstrap_container_image != "USE_DEFAULT" ? 
    local.bootstrap_container_image : 
    join("",list(local.mgmt_account,".dkr.ecr.eu-west-1.amazonaws.com/",local.name,":latest"))}"
}

resource "aws_security_group" "sg" {
  count       = "${var.create && local.platform == "FARGATE" && local.load_balancing_type != "none" ? 1 : 0}"
  name        = "${local.environment_name}-${local.name}_sg"
  description = "Allow inbound traffic to port ${local.container_port} on ${local.name}"
  vpc_id      = "${local.lb_vpc_id}"

  ingress {
    from_port       = "${local.container_port}"
    to_port         = "${local.container_port}"
    protocol        = "tcp"
    security_groups = ["${local.lb_sg_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Terraform   = true
    Name        = "${local.environment_name}-${local.name}_sg"
    Environment = "${local.environment_name}"
  }
}

# TODO: Expose all terraform-aws-airship-ecs-service parameters
module "service" {
  source = "github.com/mhvelplund/terraform-aws-airship-ecs-service"

  create                    = "${var.create}"
  name                      = "${local.name}"                # TODO: Prefix with envname?
  bootstrap_container_image = "${local.docker_image}"
  container_cpu             = "${local.container_cpu}"
  container_memory          = "${local.container_memory}"
  container_port            = "${local.container_port}"
  container_envvars         = "${var.environment_variables}"
  container_healthcheck     = "${var.container_healthcheck}"

  fargate_enabled           = "${local.platform == "FARGATE" ? 1 : 0}"
  awsvpc_enabled            = "${local.platform == "FARGATE" ? 1 : 0}"
  awsvpc_security_group_ids = ["${aws_security_group.sg.*.id}"]
  awsvpc_subnets            = ["${compact(split(",", local.platform == "FARGATE" ? join(",",local.vpc_private_subnets) : ""))}"]

  capacity_properties_desired_capacity             = "${local.initial_capacity}"
  capacity_properties_desired_max_capacity         = "${local.max_capacity}"
  capacity_properties_desired_min_capacity         = "${local.min_capacity}"
  load_balancing_type                              = "${local.load_balancing_type}"
  load_balancing_properties_redirect_http_to_https = true
  load_balancing_properties_lb_listener_arn_https  = "${local.lb_listener_arn_https}"
  load_balancing_properties_lb_listener_arn        = "${local.lb_listener_arn}"
  load_balancing_properties_lb_vpc_id              = "${local.lb_vpc_id}"
  load_balancing_properties_lb_arn                 = "${local.lb_arn}"
  load_balancing_properties_route53_zone_id        = "${local.lb_route53_zone_id}"
  load_balancing_properties_health_uri             = "${local.lb_health_uri}"
  region                                           = "${local.region}"
  ecs_cluster_id                                   = "${local.ecs_cluster_id}"

  tags = {
    Terraform   = true
    Environment = "${local.environment_name}"
  }
}

data "aws_lb_target_group" "tg" {
  count = "${local.load_balancing_type != "none" ? 1 : 0}"
  arn   = "${module.service.lb_target_group_arn}"
}

data "aws_lb" "lb" {
  count = "${local.load_balancing_type != "none" ? 1 : 0}"
  arn   = "${local.lb_arn}"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy-host-alarm" {
  count               = "${local.load_balancing_type != "none" ? 1 : 0}"
  alarm_name          = "${local.name}-unhealthy-host-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 0
  treat_missing_data  = "breaching"                                      # "missing"

  dimensions = {
    LoadBalancer = "${data.aws_lb.lb.arn_suffix}"              
    TargetGroup  = "${data.aws_lb_target_group.tg.arn_suffix}" 
  }

  alarm_description = "This metric monitors unhealthy hosts in the ${local.name} service"
  alarm_actions     = []
  actions_enabled   = false
}
