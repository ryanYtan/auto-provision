variable "env" {
  type        = string
  default     = "prod"
  description = "Infrastructure environment"
}

variable "app_name" {
  type        = string
  default     = "redwood"
  description = "Name of the app"
}

variable "region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS Deployment Region"
}
