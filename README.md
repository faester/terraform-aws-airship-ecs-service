# ECS service

Terraform module that wraps the Airship's ECS service module.

Usage examples:

```hcl
locals {
  # The values are shared between all services. Individual services can overwrite values in their own settings.
  shared_service_settings = {
    ecs_cluster_id        = "${module.ecs-cluster.cluster_id}"
    environment_name      = "${module.globals.environment_name}"
    lb_arn                = "${module.ecs-cluster.load_balancer_id}"
    lb_listener_arn       = "${element(module.ecs-cluster.http_tcp_listener_arns,0)}"
    lb_listener_arn_https = "${element(module.ecs-cluster.https_tcp_listener_arns,0)}"
    lb_route53_zone_id    = "${aws_route53_zone.main.zone_id}"
    lb_sg_id              = "${module.ecs-cluster.lb_sg_id}"
    lb_vpc_id             = "${module.base-network.vpc_id}"
    mgmt_account          = "${module.globals.mgmt_account}"
    region                = "${module.globals.region}"
    vpc_private_subnets   = "${join(",", module.base-network.vpc_private_subnets)}"
  }
}

module "linkmobility" {
  source = "git::https://git:<ACCESS_TOKEN>@git.rootdom.dk/KIT-ITL/terraform-ecs-service.git?ref=0.1.0"

  shared_settings = "${local.shared_service_settings}"

  settings = {
    name           = "linkmobility"
    container_port = 8090
    platform       = "FARGATE"
  }
}

module "dummy" {
  source = "git::https://git:<ACCESS_TOKEN>@git.rootdom.dk/KIT-ITL/terraform-ecs-service.git?ref=0.1.0"

  create          = false                              # DISABLED
  shared_settings = "${local.shared_service_settings}"

  settings = {
    name                      = "dummy"
    bootstrap_container_image = "nginx:stable"
    lb_health_uri             = "/"
    container_port            = 80
    initial_capacity          = 2
    max_capacity              = 4
  }
}
```