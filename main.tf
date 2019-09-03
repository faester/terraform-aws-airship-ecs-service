/**
 * # terraform-ecs-service
 * 
 * Terraform module that wraps the [Airship's ECS service module](https://registry.terraform.io/modules/blinkist/airship-ecs-service/aws).
 * 
 * It hides some of the less useful features, and provides a way to share common settings between multiple services.
 * 
 * All of the following examples assume that there is a local `shared_service_settings` map variable. 
 * 
 * In the shared settings example below, the following variables are assumed to exist:
 * 
 * + **`module.base-network`**: an instance of the [base-network](https://git.rootdom.dk/KIT-ITL/kit.aws.infrastructure/tree/master/terraform/modules/base-network) module
 * + **`module.ecs-cluster`**: an instance of the [terraform-ecs-cluster](https://git.rootdom.dk/KIT-ITL/terraform-ecs-cluster) module
 * + **`var.environment_name`**: an enviroment name, e.g. 'kitdev'
 * + **`var.mgmt_account`**: the account number for the management account
 * + **`var.region`**: the region where the cluster is deployed
 * + **`aws_route53_zone.main`**: the Route 53 zone where services are registered
 * 
 * Example:
 * 
 * ```hcl
 * locals {
 *   shared_service_settings = {
 *     environment_name      = "${var.environment_name}"
 *     lb_route53_zone_id    = "${aws_route53_zone.main.zone_id}"
 *     mgmt_account          = "${var.mgmt_account}"
 *     region                = "${var.region}"
 *   }
 * }
 * ```
 * 
 * Services are deployed by defining a module that combines a set of shared settings with some service specific `settings` settings. Finally the container can be deployed with a set of predefined environment variables.
 * Env vars can be either injected directly using the `environment_variables` map, or placed in SSM and injected as key references using the `ssm_vars` list.
 * 
 * ## Simple example
 * 
 * An example of an NGinx server with injected environment vars:
 * 
 * ```hcl
 * module "linkmobility" {
 *   source = "git::https://git:<ACCESS_TOKEN>@git.rootdom.dk/KIT-ITL/terraform-ecs-service.git?ref=1.5.0"
 * 
 *   shared_settings = "${local.shared_service_settings}"
 *   name            = "dummy-service"
 * 
 *   settings = {
 *     bootstrap_container_image = "nginx:stable"
 *     container_port            = 80
 *   }
 *   environment_variables = {
 *     deployed_by = "Mads Hvelplund <mads.hvelplund@jppol.dk>"
 *   }
 *   ssm_vars = ["db_password"]
 * }
 * ```
 * 
 * ## Required values for `shared_settings`
 * 
 * | Name | Description |
 * |------|-------------|
 * | environment_name   | The environment name, eg 'kitdev' |
 * | lb_route53_zone_id | The zone to add a service subdomain to |
 * | mgmt_account       | Id of the management account containing ECR images |
 * | region             | Region of the ECS Cluster |
 * 
 * In addition, any value from `settings` can be a shared setting.
 * 
 * ## Valid values for `settings`
 * 
 * | Name | Description | Default |
 * |------|-------------|:-----:|
 * | api_gateway               | The service uses API gateway as an interface | `false` |
 * | bootstrap_container_image | The docker image location. | "USE_DEFAULT" |
 * | cloud_watch_metrics       | If true, expose Micrometer metrics in CloudWatch | `false` |
 * | container_cpu             | Defines the needed cpu for the container | `256` |
 * | container_memory          | Defines the hard memory limit of the container | `512` |
 * | container_port            | Container port | `8080` |
 * | force_bootstrap_container_image | Force a new taskdefintion with the image in the 'bootstrap_container_image' | false |
 * | image_version             | Docker image version. This is only relavant if "bootstrap_container_image" is not set | "latest" |
 * | initial_capacity          | The desired amount of tasks for a service, when autoscaling is used desired_capacity is only used initially | `1` |
 * | kms_keys                  | Comma separated list of KMS keys that the service can access | "" |
 * | lb_health_uri             | Load balancer health check URL | "/actuator/health" |
 * | lb_healthy_threshold      | The number of consecutive successful health checks required before considering an unhealthy target healthy | `3` |
 * | lb_redirect_http_to_https | Redirect all HTTP requests to HTTPS | `true` |
 * | lb_unhealthy_threshold    | The number of consecutive successful health checks required before considering an healthy target unhealthy | `3` |
 * | load_balancing_type       | The load balancer type. Set to "none", or leave blank to determine dynamically | "" |
 * | max_capacity              | When autoscaling is activated, it sets the maximum of tasks to be available for this service | `2` |
 * | min_capacity              | When autoscaling is activated, it sets the minimum of tasks to be available for this service | `1` |
 * | nlb_port                  | The port on the NLB dedicated to the service. Does not have to match the `container_port`, but *must be unique on the NLB*. | `container_port` |
 * | platform                  | Either FARGATE or EC2 | "FARGATE" |
 * | s3_ro_paths               | Comma separated list of S3 Bucket/Prefixes that the service can access | "" |
 * | s3_rw_paths               | Comma separated list of S3 Bucket/Prefixes that the service can access | "" |
 * | ssm_paths                 | Comma separated list of SSM keys that the service can access. If there are 'ssm_vars' they automatically get added to the list | "" |
 * 
 * ## Sample `container_healthcheck`
 * 
 * Mostly relevant for services without web interface and LB health check.
 * 
 * ```hcl
 * {
 *   command     = "curl --fail http://localhost:8090/health || exit 1"
 *   interval    = 10
 *   retries     = 3
 *   startPeriod = 30
 * }
 * ```
 *
 * ## Scaling
 * Provide scaling rules to override default scaling. There are more details at
 * https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html
 * and specifically https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html
 *
 * ## Doc generation
 * 
 * Documentation should be modified within `main.tf` and generated using [terraform-docs](https://github.com/segmentio/terraform-docs).
 * Generate them like so:
 * 
 * ```bash
 * terraform-docs md . > README.md
 * ```
 * In powershell 
 * ```
 * terraform-docs md . |Out-File -Encoding utf8 -filepath README.md
 * ```
 */
locals {
  default_settings = {
    api_gateway                     = false
    bootstrap_container_image       = "USE_DEFAULT"
    container_cpu                   = 256
    container_memory                = 512
    container_port                  = 8080
    cloud_watch_metrics             = false
    force_bootstrap_container_image = false
    image_version                   = "latest"
    initial_capacity                = 1
    min_capacity                    = 1
    max_capacity                    = 2
    lb_health_uri                   = "/actuator/health"
    lb_unhealthy_threshold          = 3
    lb_healthy_threshold            = 3
    lb_redirect_http_to_https       = true
    load_balancing_type             = ""
    kms_keys                        = ""
    nlb_port                        = -1
    ssm_paths                       = ""
    s3_ro_paths                     = ""
    s3_rw_paths                     = ""
    platform                        = "FARGATE"
  }

  combined_settings = "${merge(local.default_settings,var.shared_settings,var.settings)}"

  kms_keys = "${compact(split(",", local.combined_settings["kms_keys"]))}"

  ssm_vars_path = "${local.combined_settings["ssm_paths"]},${length(var.ssm_vars) == 0 ? "${local.environment_name}/placeholder" : "${local.environment_name}/${var.name}"}"
  ssm_paths     = "${compact(distinct(split(",", local.ssm_vars_path)))}"

  s3_ro_paths = "${compact(split(",", local.combined_settings["s3_ro_paths"]))}"
  s3_rw_paths = "${compact(split(",", local.combined_settings["s3_rw_paths"]))}"

  is_fargate = "${local.combined_settings["platform"] == "FARGATE"}"
  has_lb     = "${local.combined_settings["load_balancing_type"] != "none"}"

  nlb_port = "${local.combined_settings["nlb_port"] == -1 ? local.combined_settings["container_port"] : local.combined_settings["nlb_port"]}"

  docker_image = "${local.combined_settings["bootstrap_container_image"] != "USE_DEFAULT" ? 
    local.combined_settings["bootstrap_container_image"] : 
    join("",list(local.combined_settings["mgmt_account"],".dkr.ecr.eu-west-1.amazonaws.com/",var.name,":",local.combined_settings["image_version"]))}"

  environment_name = "${local.combined_settings["environment_name"]}"

  lb_name            = "${local.combined_settings["api_gateway"] ? "${local.environment_name}-ecs-internal": "${local.environment_name}-ecs-external"}"
  cloudwatch_enabled = "${local.combined_settings["cloud_watch_metrics"]}"

  # "cloudwatch_env" overwrites the environment provides by the variables. This ensures that cut and paste can't mess with the namespace names for CloudWatch.
  # This is a workaround because TF 0.11 doesn't support conditionals with maps or lists :(
  # The code essentially sets:
  #    cloudwatch_env = local.cloudwatch_enabled ? {
  #      CLOUD_AWS_REGION_STATIC                        = "${local.combined_settings["region"]}"
  #      MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_NAMESPACE = "Service/${var.name}"
  #      MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_ENABLED   = "true"                
  #    } : {}
  # 0.12 fixes this

  cloudwatch_env = "${   zipmap(
    compact(split(",", local.cloudwatch_enabled != 1 ? "" :  "CLOUD_AWS_REGION_STATIC,MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_NAMESPACE,MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_ENABLED" )),
    compact(split(",", local.cloudwatch_enabled != 1 ? "" :  "${local.combined_settings["region"]},Service/${var.name},true" ))
  )}"
  combined_environment_variables = "${merge(var.environment_variables, local.cloudwatch_env)}"
}

####################################################################################################
# <Data Sources>
####################################################################################################

data "aws_ssm_parameter" "parameters" {
  count = "${length(var.ssm_vars)}"
  name  = "/${local.environment_name}/${var.name}/${var.ssm_vars[count.index]}"
}

data "aws_ssm_parameter" "placeholder_parameter" {
  name  = "/${local.environment_name}/placeholder/placeholder"
}

data "null_data_source" "parameters" {
  count = "${length(var.ssm_vars)}"

  inputs = {
    key   = "${upper(var.ssm_vars[count.index])}"
    value = "${element(data.aws_ssm_parameter.parameters.*.arn, count.index)}"
  }
}

locals {
  _ssm_keys   = "${join(",", data.null_data_source.parameters.*.outputs.key)}"
  _ssm_values = "${join(",", data.null_data_source.parameters.*.outputs.value)}"

  # This is a work around to ensure that a task execution role is generated even when there are no secrets and we run in EC2
  _place_holder_key   = "${local.is_fargate || length(var.ssm_vars) > 0 ? "" : "PLACEHOLDER"}"
  _place_holder_value = "${local.is_fargate || length(var.ssm_vars) > 0 ? "" : "${data.aws_ssm_parameter.placeholder_parameter.arn}"}"
  _combined_keys      = "${compact(split(",","${local._ssm_keys},${local._place_holder_key}"))}"
  _combined_values    = "${compact(split(",","${local._ssm_values},${local._place_holder_value}"))}"
  environment_secrets = "${zipmap(local._combined_keys, local._combined_values)}"
}

data "aws_caller_identity" "current" {}

data "aws_security_group" "lb_sg" {
  tags = {
    Environment = "${local.environment_name}"
    Name        = "${local.environment_name}-ecs-lb-sg"
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_security_group.lb_sg.vpc_id}"

  tags = {
    Environment = "${local.environment_name}"
    Tier        = "ServiceBusPrivate"
  }
}

# Create a list of network interfaces associated with an ELB in the private subnets, which is always an NLB
data "aws_network_interface" "nlb" {
  count = "${local.combined_settings["api_gateway"] ? length(data.aws_subnet_ids.private.ids) : 0}"

  filter = {
    name   = "description"
    values = ["ELB ${data.aws_lb.lb.arn_suffix}"]
  }

  filter = {
    name   = "subnet-id"
    values = ["${element(data.aws_subnet_ids.private.ids, count.index)}"]
  }
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "${local.environment_name}"
}

data "aws_lb" "lb" {
  name = "${local.lb_name}"
}

locals {
  load_balancing_type = "${length(local.combined_settings["load_balancing_type"]) == 0 ? "${data.aws_lb.lb.load_balancer_type}": "${local.combined_settings["load_balancing_type"]}"}"
}

data "aws_lb_listener" "http" {
  load_balancer_arn = "${data.aws_lb.lb.arn}"
  port              = 80
}

data "aws_lb_listener" "https" {
  load_balancer_arn = "${data.aws_lb.lb.arn}"
  port              = 443
}

data "aws_lb_target_group" "tg" {
  count = "${local.has_lb ? 1 : 0}"
  arn   = "${module.service.lb_target_group_arn}"
}

####################################################################################################
# </Data Sources>
####################################################################################################

####################################################################################################
# <Security Groups>
# -----------------
# AWSVPC specific SG, i.e. only for Fargate services.
####################################################################################################

resource "aws_security_group" "sg" {
  count       = "${var.create && local.is_fargate && local.has_lb ? 1 : 0}"
  name        = "${local.environment_name}-${var.name}_sg"
  description = "Allow inbound traffic to port ${local.combined_settings["container_port"]} on ${var.name}"
  vpc_id      = "${data.aws_security_group.lb_sg.vpc_id}"

  tags = {
    Terraform   = true
    Name        = "${local.environment_name}-${var.name}_sg"
    Environment = "${local.environment_name}"
  }
}

resource "aws_security_group_rule" "allow_nlb" {
  count             = "${(var.create && local.is_fargate) && length(data.aws_network_interface.nlb.*.private_ips) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = "${local.combined_settings["container_port"]}"
  to_port           = "${local.combined_settings["container_port"]}"
  protocol          = "tcp"
  cidr_blocks       = ["${formatlist("%s/32",flatten(data.aws_network_interface.nlb.*.private_ips))}"]
  description       = "Permit connection from NLB"
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_alb" {
  count                    = "${var.create && local.is_fargate ? 1 : 0}"
  type                     = "ingress"
  from_port                = "${local.combined_settings["container_port"]}"
  to_port                  = "${local.combined_settings["container_port"]}"
  protocol                 = "tcp"
  source_security_group_id = "${data.aws_security_group.lb_sg.id}"
  description              = "Permit connection from ALB"
  security_group_id        = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_all_egress" {
  count             = "${var.create && local.is_fargate ? 1 : 0}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Permit all traffic out"
  security_group_id = "${aws_security_group.sg.id}"
}

####################################################################################################
# </Security Groups>
####################################################################################################

####################################################################################################
# <Service Definition>
####################################################################################################

module "service" {
  #source  = "blinkist/airship-ecs-service/aws"  #version = "~> 0.9.0"
  #source = "../terraform-aws-airship-ecs-service"
  #source = "github.com/mhvelplund/terraform-aws-airship-ecs-service?ref=scheduled_task_support"
  source  = "git::https://git:05e876c88cb3da6fe133a3dab4c01c7da39e952b@git.rootdom.dk/KIT-ITL/terraform-aws-airship-ecs-service?ref=1.0.0"

  create                                           = "${var.create}"
  name                                             = "${var.name}"                                                                                   # TODO: Prefix with envname?
  bootstrap_container_image                        = "${local.docker_image}"
  container_cpu                                    = "${local.combined_settings["container_cpu"]}"
  container_memory                                 = "${local.combined_settings["container_memory"]}"
  container_port                                   = "${local.combined_settings["container_port"]}"
  container_envvars                                = "${local.combined_environment_variables}"
  container_secrets                                = "${local.environment_secrets}"
  container_healthcheck                            = "${var.container_healthcheck}"
  container_secrets_enabled                        = "${length(keys(local.environment_secrets)) > 0}"
  fargate_enabled                                  = "${local.is_fargate ? 1 : 0}"
  force_bootstrap_container_image                  = "${local.combined_settings["force_bootstrap_container_image"]}"
  awsvpc_enabled                                   = "${local.is_fargate ? 1 : 0}"
  awsvpc_security_group_ids                        = ["${aws_security_group.sg.*.id}"]
  awsvpc_subnets                                   = ["${compact(split(",", local.is_fargate ? join(",", data.aws_subnet_ids.private.ids ) : ""))}"]
  capacity_properties_desired_capacity             = "${local.combined_settings["initial_capacity"]}"
  capacity_properties_desired_max_capacity         = "${local.combined_settings["max_capacity"]}"
  capacity_properties_desired_min_capacity         = "${local.combined_settings["min_capacity"]}"
  load_balancing_type                              = "${local.load_balancing_type}"
  load_balancing_properties_nlb_listener_port      = "${local.nlb_port}"
  load_balancing_properties_redirect_http_to_https = "${local.combined_settings["lb_redirect_http_to_https"]}"
  load_balancing_properties_lb_listener_arn_https  = "${data.aws_lb_listener.https.arn}"
  load_balancing_properties_lb_listener_arn        = "${data.aws_lb_listener.http.arn}"
  load_balancing_properties_lb_vpc_id              = "${data.aws_security_group.lb_sg.vpc_id}"
  load_balancing_properties_lb_arn                 = "${data.aws_lb.lb.arn}"
  load_balancing_properties_route53_zone_id        = "${local.combined_settings["lb_route53_zone_id"]}"
  load_balancing_properties_health_uri             = "${local.combined_settings["lb_health_uri"]}"
  load_balancing_properties_unhealthy_threshold    = "${local.combined_settings["lb_unhealthy_threshold"]}"
  load_balancing_properties_healthy_threshold      = "${local.combined_settings["lb_healthy_threshold"]}"
  region                                           = "${local.combined_settings["region"]}"
  ecs_cluster_id                                   = "${data.aws_ecs_cluster.cluster.arn}"
  kms_enabled                                      = "${length(local.kms_keys) > 0}"
  kms_keys                                         = ["${local.kms_keys}"]
  ssm_enabled                                      = "${length(local.ssm_paths) > 0}"
  ssm_paths                                        = ["${local.ssm_paths}"]
  s3_rw_paths                                      = ["${local.s3_rw_paths}"]
  s3_ro_paths                                      = ["${local.s3_ro_paths}"]

  tags = {
    Terraform   = true
    Environment = "${local.environment_name}"
  }

  scaling_properties = "${var.scaling_rules}"
  host_path_volumes  = "${var.host_path_volumes}"
  mountpoints        = "${var.mountpoints}"

  is_scheduled_task         = "${length(var.scheduled_task_expression) == 0 ? false : true}"
  scheduled_task_expression = "${var.scheduled_task_expression}"
  scheduled_task_count      = "${var.scheduled_task_count}"
}

# Default alarm when the number of unhealthy hosts exceed 0
resource "aws_cloudwatch_metric_alarm" "unhealthy-host-alarm" {
  count               = "${local.has_lb ? 1 : 0}"
  alarm_name          = "${local.environment_name}-${var.name}-unhealthy-host-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/${local.combined_settings["api_gateway"] ? "Network" : "Application"}ELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 0
  treat_missing_data  = "breaching"                                                                    # "missing"

  dimensions = {
    LoadBalancer = "${data.aws_lb.lb.arn_suffix}"
    TargetGroup  = "${data.aws_lb_target_group.tg.arn_suffix}"
  }

  alarm_description = "This metric monitors unhealthy hosts in the ${var.name} service"
  alarm_actions     = []
  actions_enabled   = false
}

# Grant access to CloudWatch metrics
resource "aws_iam_role_policy_attachment" "cloudwatch-metrics-access" {
  count      = "${local.cloudwatch_enabled ? 1 : 0}"
  role       = "${module.service.ecs_taskrole_name}"
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.environment_name}-cloudwatch-metrics-access"
}

####################################################################################################
# </Service Definition>
####################################################################################################

