variable "env" {
  type        = string
  description = "Environment"
}

variable "app_name" {
  type        = string
  description = "Name of the app"
}

variable "region" {
  type        = string
  description = "Region name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "db_master_user_secret_arn" {
  type        = string
  description = "Master user secret arn"
}

variable "db_ssm_path" {
  type        = string
  description = "Start of path of SSM parameters"
}

variable "public_subnets" {
  type        = list(string)
  description = "IDs of public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "IDs of private subnets"
}

variable "ecs_task_count" {
  type        = number
  description = "Desired number of ECS tasks"
}

variable "ecs_container_name" {
  type        = string
  description = "Container name"
}

variable "ecs_container_image" {
  type        = string
  description = "Container image"
}
