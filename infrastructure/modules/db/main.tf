locals {
  db_name   = "${var.app_name}db"
  db_username = "${var.app_name}_user"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.1"

  identifier = "${var.app_name}-rds"

  engine                = "postgres"
  engine_version        = "14"
  family                = "postgres14" # DB parameter group
  major_engine_version  = "14"         # DB option group
  instance_class        = "db.t4g.small"
  allocated_storage     = 20
  max_allocated_storage = 100

  manage_master_user_password = true

  db_name   = local.db_name
  username  = local.db_username
  port      = 5432
  multi_az  = true
  db_subnet_group_name = var.database_subnet_group

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
}

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.app_name}/database/db_endpoint"
  description = "Database endpoint"
  type        = "String"
  value       = module.db.db_instance_endpoint
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.app_name}/database/db_name"
  description = "Database name"
  type        = "String"
  value       = module.db.db_instance_name
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.private_subnets_cidr_blocks
  }
}
