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

data "aws_availability_zones" "available" {}

locals {
  vpc_cidr          = "10.0.0.0/16"
  azs               = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name  = "${var.app_name}-${var.env}-vpc"
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
  env       = var.env
  app_name  = var.app_name

  database_subnet_group = module.vpc.database_subnet_group
}

module "ecs" {
  source    = "./modules/ecs"
  env       = var.env
  app_name  = var.app_name
  region    = var.region
  vpc_id    = module.vpc.vpc_id

  db_master_user_secret_arn = module.db.db_master_user_secret_arn

  db_ssm_path = module.db.db_ssm_path

  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  ecs_container_name  = "ecr-repository"
  ecs_container_image = "${aws_ecr_repository.ecr_repository.repository_url}:latest"

  ecs_task_count = 6
}

resource "aws_ecr_repository" "ecr_repository" {
  name = "ecr-repository"
  image_tag_mutability = "MUTABLE"
}
