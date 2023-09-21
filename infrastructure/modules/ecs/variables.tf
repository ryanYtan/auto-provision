variable "app_name" {
  type        = string
  description = "Application name"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnets" {
  type        = list(string)
  description = "IDs of public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "IDs of private subnets"
}

variable "app_port" {
  type        = number
  description = "Port that the application is listening on"
}

variable "ecs_task_count" {
  type        = number
  description = "Desired number of ECS tasks"
}

variable "fargate_cpu" {
  type        = number
  description = "CPU speed in MHz"
  default     = 1024
}

variable "fargate_mem" {
  type        = number
  description = "Memory in MB"
  default     = 2048
}

variable "app_container_name" {
  type        = string
  description = "Container name"
}

variable "app_image" {
  type        = string
  description = "Container image"
}

variable "target_domain" {
  type        = string
  description = "Domain of the web application"
}

variable "db_dependency" {
  type        = any
  description = "A value that ensures that the ECS Service depends on the creation of the RDS database"
  default     = []
}
