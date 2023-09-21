variable "app_name" {
  type        = string
  description = "Name of the app"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "database_subnet_group" {
  type        = string
}

variable "private_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of private subnets CIDR blocks"
}
