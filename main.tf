locals {
  default_settings = {
    bootstrap_container_image = "USE_DEFAULT"
    container_cpu             = 256
    container_memory          = 512
    container_port            = 8080
    initial_capacity          = 1
    min_capacity              = 1
    max_capacity              = 2
    lb_health_uri             = "/health"
    load_balancing_type       = "application"
    kms_keys                  = ""
    ssm_paths                 = ""
    s3_ro_paths               = ""
    s3_rw_paths               = ""
    platform                  = "EC2"
  }

  combined_settings = "${merge(local.default_settings,var.shared_settings,var.settings)}"

  kms_keys            = "${compact(split(",", local.combined_settings["kms_keys"]))}"
  ssm_paths           = "${compact(split(",", local.combined_settings["ssm_paths"]))}"
  s3_ro_paths         = "${compact(split(",", local.combined_settings["s3_ro_paths"]))}"
  s3_rw_paths         = "${compact(split(",", local.combined_settings["s3_rw_paths"]))}"
  vpc_private_subnets = "${split(",", lookup(local.combined_settings, "vpc_private_subnets"))}"

  is_fargate = "${local.combined_settings["platform"] == "FARGATE"}"
  has_lb     = "${local.combined_settings["load_balancing_type"] != "none"}"

  docker_image = "${local.combined_settings["bootstrap_container_image"] != "USE_DEFAULT" ? 
    local.combined_settings["bootstrap_container_image"] : 
    join("",list(local.combined_settings["mgmt_account"],".dkr.ecr.eu-west-1.amazonaws.com/",local.combined_settings["name"],":latest"))}"
}

resource "aws_security_group" "sg" {
  count       = "${var.create && local.is_fargate && local.has_lb ? 1 : 0}"
  name        = "${local.combined_settings["environment_name"]}-${local.combined_settings["name"]}_sg"
  description = "Allow inbound traffic to port ${local.combined_settings["container_port"]} on ${local.combined_settings["name"]}"
  vpc_id      = "${local.combined_settings["lb_vpc_id"]}"

  ingress {
    from_port       = "${local.combined_settings["container_port"]}"
    to_port         = "${local.combined_settings["container_port"]}"
    protocol        = "tcp"
    security_groups = ["${local.combined_settings["lb_sg_id"]}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Terraform   = true
    Name        = "${local.combined_settings["environment_name"]}-${local.combined_settings["name"]}_sg"
    Environment = "${local.combined_settings["environment_name"]}"
  }
}

# TODO: Expose all terraform-aws-airship-ecs-service parameters
module "service" {
  source = "github.com/mhvelplund/terraform-aws-airship-ecs-service?ref=support_container_secrets"  
  #source = "../terraform-aws-airship-ecs-service"

  create                    = "${var.create}"
  name                      = "${local.combined_settings["name"]}"             # TODO: Prefix with envname?
  bootstrap_container_image = "${local.docker_image}"
  container_cpu             = "${local.combined_settings["container_cpu"]}"
  container_memory          = "${local.combined_settings["container_memory"]}"
  container_port            = "${local.combined_settings["container_port"]}"
  container_envvars         = "${var.environment_variables}"
  container_secrets         = "${var.environment_secrets}"
  container_healthcheck     = "${var.container_healthcheck}"

  fargate_enabled           = "${local.is_fargate ? 1 : 0}"
  awsvpc_enabled            = "${local.is_fargate ? 1 : 0}"
  awsvpc_security_group_ids = ["${aws_security_group.sg.*.id}"]
  awsvpc_subnets            = ["${compact(split(",", local.is_fargate ? join(",",local.vpc_private_subnets) : ""))}"]

  capacity_properties_desired_capacity             = "${local.combined_settings["initial_capacity"]}"
  capacity_properties_desired_max_capacity         = "${local.combined_settings["max_capacity"]}"
  capacity_properties_desired_min_capacity         = "${local.combined_settings["min_capacity"]}"
  load_balancing_type                              = "${local.combined_settings["load_balancing_type"]}"
  load_balancing_properties_redirect_http_to_https = true
  load_balancing_properties_lb_listener_arn_https  = "${local.combined_settings["lb_listener_arn_https"]}"
  load_balancing_properties_lb_listener_arn        = "${local.combined_settings["lb_listener_arn"]}"
  load_balancing_properties_lb_vpc_id              = "${local.combined_settings["lb_vpc_id"]}"
  load_balancing_properties_lb_arn                 = "${local.combined_settings["lb_arn"]}"
  load_balancing_properties_route53_zone_id        = "${local.combined_settings["lb_route53_zone_id"]}"
  load_balancing_properties_health_uri             = "${local.combined_settings["lb_health_uri"]}"
  region                                           = "${local.combined_settings["region"]}"
  ecs_cluster_id                                   = "${local.combined_settings["ecs_cluster_id"]}"

  kms_enabled = "${length(local.kms_keys) > 0}"
  kms_keys    = ["${local.kms_keys}"]

  ssm_enabled = "${length(local.ssm_paths) > 0}"
  ssm_paths   = ["${local.ssm_paths}"]

  s3_rw_paths = ["${local.s3_rw_paths}"]
  s3_ro_paths = ["${local.s3_ro_paths}"]

  tags = {
    Terraform   = true
    Environment = "${local.combined_settings["environment_name"]}"
  }
}

data "aws_lb_target_group" "tg" {
  count = "${local.has_lb ? 1 : 0}"
  arn   = "${module.service.lb_target_group_arn}"
}

data "aws_lb" "lb" {
  count = "${local.has_lb ? 1 : 0}"
  arn   = "${local.combined_settings["lb_arn"]}"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy-host-alarm" {
  count               = "${local.has_lb ? 1 : 0}"
  alarm_name          = "${local.combined_settings["name"]}-unhealthy-host-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 0
  treat_missing_data  = "breaching"                                               # "missing"

  dimensions = {
    LoadBalancer = "${data.aws_lb.lb.arn_suffix}"
    TargetGroup  = "${data.aws_lb_target_group.tg.arn_suffix}"
  }

  alarm_description = "This metric monitors unhealthy hosts in the ${local.combined_settings["name"]} service"
  alarm_actions     = []
  actions_enabled   = false
}
