terraform {
  backend "s3" {
    bucket         = "app-terraform-bucket"
    encrypt        = true
    key            = "state/app-terraform.tfstate"
    region         = "eu-west-2"
    kms_key_id     = "alias/terraform-state-bucket-key"
    dynamodb_table = "app-terraform-state-table"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }

  required_version = ">= 1.3.1"
}

provider "aws" {}

data "aws_subnets" "public" {
  filter {
    name   = "map-public-ip-on-launch"
    values = [true]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

module "cloudwatch" {
  source      = "./cloudwatch"
  name        = var.name
  environment = var.environment
}

module "policy" {
  source                       = "./policy"
  name                         = var.name
  vpc_id                       = var.vpc_id
  environment                  = var.environment
  vpc_log                      = module.cloudwatch.vpc_log
  secret_kms_key_id            = aws_kms_key.terraform-secrets-key.key_id
  s3_bucket_id_storage_backend = aws_s3_bucket.studio-storage.id
}

module "securitygroups" {
  source         = "./securitygroups"
  name           = var.name
  vpc_id         = var.vpc_id
  environment    = var.environment
  container_port = var.container_port
}

module "alb" {
  source              = "./alb"
  name                = var.name
  vpc_id              = var.vpc_id
  subnets             = data.aws_subnets.public.ids
  environment         = var.environment
  alb_security_groups = [module.securitygroups.alb]
  health_check_path   = var.health_check_path
}

module "ecs" {
  source                             = "./ecs"
  name                               = var.name
  environment                        = var.environment
  subnets                            = data.aws_subnets.private.ids
  aws_alb_target_group_arn           = module.alb.aws_alb_target_group_arn
  ecs_service_security_groups        = [module.securitygroups.ecs_tasks]
  container_port                     = var.container_port
  container_cpu                      = var.container_cpu
  container_memory                   = var.container_memory
  worker_container_cpu               = var.container_cpu
  worker_container_memory            = var.container_memory
  service_desired_count              = var.service_desired_count
  server_log                         = module.cloudwatch.server_log
  worker_log                         = module.cloudwatch.worker_log
  websocket_client_log               = module.cloudwatch.websocket_client_log
  setup_log                          = module.cloudwatch.setup_log
  ecs_task_execution_role_arn        = module.policy.ecs_task_execution_role_arn
  ecs_task_role_arn                  = module.policy.ecs_task_role_arn
  websocket_environment              = local.websocket_environment
  websocket_secrets                  = local.websocket_secrets
  server_environment                 = local.server_environment
  server_secrets                     = local.server_secrets
  worker_environment                 = local.worker_environment
  worker_secrets                     = local.worker_secrets
  setup_environment                  = local.setup_environment
  setup_secrets                      = local.setup_secrets
  container_image                    = var.container_image
  image_tag                          = var.image_tag
  django_superuser_email             = var.pli_superuser_email
  django_superuser_username          = var.pli_superuser_username
  container_registry_credentials_arn = module.container_registry_credentials.arn
  container_registry_url             = var.container_registry_url
}
