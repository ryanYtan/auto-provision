terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.1.0"
    }
  }

  backend "s3" {
    bucket = "redwood-tfstate"
    key = "app.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

locals {
  vpc_cidr          = "10.0.0.0/16"
  azs               = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name  = "${var.app_name}-vpc"
  cidr  = local.vpc_cidr
  azs   = local.azs

  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true

  public_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = true
}

module "db" {
  source    = "./modules/db"
  app_name  = var.app_name
  vpc_id    = module.vpc.vpc_id

  database_subnet_group = module.vpc.database_subnet_group

  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "ecs" {
  source    = "./modules/ecs"
  app_name  = var.app_name
  vpc_id    = module.vpc.vpc_id
  region    = var.region

  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  app_port = var.app_port
  ecs_task_count = var.ecs_task_count

  fargate_cpu = var.fargate_cpu
  fargate_mem = var.fargate_mem

  app_container_name  = var.app_container_name
  app_image           = var.app_image

  target_domain = var.app_domain_name

  db_dependency = module.db.db_master_user_secret_arn
}

resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/ecs/${var.app_name}-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "app_log_stream" {
  name           = "${var.app_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.app_log_group.name
}
