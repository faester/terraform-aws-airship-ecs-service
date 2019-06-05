# terraform-ecs-service

Terraform module that wraps the [Airship's ECS service module](https://registry.terraform.io/modules/blinkist/airship-ecs-service/aws/0.9.3).

It hides some of the less useful features, and provides a way to share common settings between multiple services.

All of the following examples assume that there is a local `shared_service_settings` map variable.

In the shared settings example below, the following variables are assumed to exist:

+ **`module.base-network`**: an instance of the [base-network](https://git.rootdom.dk/KIT-ITL/kit.aws.infrastructure/tree/master/terraform/modules/base-network) module
+ **`module.ecs-cluster`**: an instance of the [terraform-ecs-cluster](https://git.rootdom.dk/KIT-ITL/terraform-ecs-cluster) module
+ **`var.environment_name`**: an enviroment name, e.g. 'kitdev'
+ **`var.mgmt_account`**: the account number for the management account
+ **`var.region`**: the region where the cluster is deployed
+ **`aws_route53_zone.main`**: the Route 53 zone where services are registered

Example:

```hcl
locals {
  shared_service_settings = {
    environment_name      = "${var.environment_name}"
    lb_route53_zone_id    = "${aws_route53_zone.main.zone_id}"
    mgmt_account          = "${var.mgmt_account}"
    region                = "${var.region}"
  }
}
```

Services are deployed by defining a module that combines a set of shared settings with some service specific `settings` settings. Finally the container can be deployed with a set of predefined environment variables.
Env vars can be either injected directly using the `environment_variables` map, or placed in SSM and injected as key references using the `environment_secrets` map.

## Simple example

An example of an NGinx server with injected environment vars:

```hcl
module "linkmobility" {
  source = "git::https://git:<ACCESS_TOKEN>@git.rootdom.dk/KIT-ITL/terraform-ecs-service.git?ref=1.2.0"

  shared_settings = "${local.shared_service_settings}"
  name            = "dummy-service"

  settings {
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

## Required values for `shared_settings`

| Name | Description |
|------|-------------|
| environment_name   | The environment name, eg 'kitdev' |
| lb_route53_zone_id | The zone to add a service subdomain to |
| mgmt_account       | Id of the management account containing ECR images |
| region             | Region of the ECS Cluster |

In addtion, any value from `settings` can be a shared setting.

## Valid values for `settings`

| Name | Description | Default |
|------|-------------|:-----:|
| bootstrap_container_image | The docker image location. Set to USE_DEFAULT or give a docker image path with version label | "" |
| cloud_watch_metrics       | If true, expose Micrometer metrics in CloudWatch | `false |
| container_cpu             | Defines the needed cpu for the container | `256` |
| container_memory          | Defines the hard memory limit of the container | `512` |
| container_port            | Container port | `8080` |
| image_version             | Docker image version. This is only relavant if "bootstrap_container_image" is not set | "latest" |
| initial_capacity          | The desired amount of tasks for a service, when autoscaling is used desired_capacity is only used initially | `1` |
| kms_keys                  | Comma separated list of KMS keys that the service can access | "" |
| lb_name                   | The name of the loadbalancer to attach to | "${shared_settings.environment_name}-ecs-external" |
| lb_health_uri             | Load balancer health check URL | "/health" |
| lb_healthy_threshold      | The number of consecutive successful health checks required before considering an unhealthy target healthy | `3` |
| lb_redirect_http_to_https | Redirect all HTTP requests to HTTPS | `true` |
| lb_unhealthy_threshold    | The number of consecutive successful health checks required before considering an healthy target unhealthy | `3` |
| load_balancing_type       | The load balancer type. Set to "none", or leave blank to determine dynamically | "" |
| max_capacity              | When autoscaling is activated, it sets the maximum of tasks to be available for this service | `2` |
| min_capacity              | When autoscaling is activated, it sets the minimum of tasks to be available for this service | `1` |
| platform                  | Either FARGATE or EC2 | "FARGATE" |
| s3_ro_paths               | Comma separated list of S3 Bucket/Prefixes that the service can access | "" |
| s3_rw_paths               | Comma separated list of S3 Bucket/Prefixes that the service can access | "" |
| ssm_paths                 | Comma separated list of SSM keys that the service can access | "" |

## Sample `container_healthcheck`

Mostly relevant for services without web interface and LB health check.

```hcl
{
  command     = "curl --fail http://localhost:8090/health || exit 1"
  interval    = 10
  retries     = 3
  startPeriod = 30
}
```

## Doc generation

Documentation should be modified within `main.tf` and generated using [terraform-docs](https://github.com/segmentio/terraform-docs).
Generate them like so:

```bash
terraform-docs md . > README.md
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| container\_docker\_labels | Adds the key/value pairs as docker labels to the container | map | `<map>` | no |
| container\_healthcheck | A custom container health check. | map | `<map>` | no |
| create | If true, the service will be created | string | `"true"` | no |
| environment\_secrets | Environment secrets fed to the container from SSM keys | map | `<map>` | no |
| environment\_variables | Environment variables fed to the container | map | `<map>` | no |
| name | The name of the project, must be unique and match | string | n/a | yes |
| settings | If a value is present it the `settings` variable, it overrides the value from `shared_settings` | map | n/a | yes |
| shared\_settings | These are the settings that are shared between all services | map | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs\_taskrole\_name | The TaskRole for the service |
| environment\_variables | The final environment vars passed to the task. Useful for debugging. |
| settings | The final settings passed to Airship. Useful for debugging. |

