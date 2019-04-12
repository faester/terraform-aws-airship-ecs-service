# ECS service

Terraform module that wraps the [Airship's ECS service module](https://registry.terraform.io/modules/blinkist/airship-ecs-service/aws/0.9.3).

It hides some of the less useful features, and provides a way to share common settings between multiple services.

All of the following examples assume that there is a local `shared_service_settings` map variable. 

In the shared settings example below, the following variables are assumed to exist:

* **`module.base-network`**: an instance of the [base-network](https://git.rootdom.dk/KIT-ITL/kit.aws.infrastructure/tree/master/terraform/modules/base-network)
* **`module.ecs-cluster`**: an instance of the [airship-ecs-cluster](https://registry.terraform.io/modules/blinkist/airship-ecs-cluster/aws)- or 
  [terraform-ecs-cluster](https://git.rootdom.dk/KIT-ITL/terraform-ecs-cluster) modules.
* **`var.environment_name`**: an enviroment name, e.g. 'kitdev'
* **`var.mgmt_account`**: the account number for the management account
* **`var.region`**: the region where the cluster is deployed
* **`aws_route53_zone.main`**: the Route 53 zone where services are registered

Example:

```hcl
locals {
  shared_service_settings = {
    ecs_cluster_id        = "${module.ecs-cluster.cluster_id}"
    environment_name      = "${var.environment_name}"
    lb_arn                = "${module.ecs-cluster.load_balancer_id}"
    lb_listener_arn       = "${element(module.ecs-cluster.http_tcp_listener_arns,0)}"
    lb_listener_arn_https = "${element(module.ecs-cluster.https_tcp_listener_arns,0)}"
    lb_route53_zone_id    = "${aws_route53_zone.main.zone_id}"
    lb_sg_id              = "${module.ecs-cluster.lb_sg_id}"
    lb_vpc_id             = "${module.base-network.vpc_id}"
    mgmt_account          = "${var.mgmt_account}"
    region                = "${var.region}"
    vpc_private_subnets   = "${join(",", module.base-network.vpc_private_subnets)}"
  }
}
```

Services are deployed by defining a module that combines a set of shared settings with some service specific `settings` settings. Finally the container can be deployed with a set of predefined environment variables.
Env vars can be either injected directly using the `environment_variables` map, or placed in SSM and injected as key references using the `environment_secrets` map.

## Simple example

An example of an NGinx server with injected environment vars:

```hcl
module "linkmobility" {
  source = "git::https://git:<ACCESS_TOKEN>@git.rootdom.dk/KIT-ITL/terraform-ecs-service.git?ref=0.6.0"

  shared_settings = "${local.shared_service_settings}"

  settings {
    name                      = "dummy-service"
    bootstrap_container_image = "nginx:stable"
    container_port            = 80
    ssm_paths                 = "dummy-service"
  }
  environment_variables {
    deployed_by = "Mads Hvelplund <mads.hvelplund@jppol.dk>"
  }
  environment_secrets {
    PASSWORD = "/dummy-service/password"
  }
}
```