variable "app_name" {
  type        = string
  description = "Name of the app"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS Name of the Application Load Balancer"
}

variable "alb_zone_id" {
  type        = string
  description = "Zone ID of the Application Load Balancer"
}
