variable "app_name" {
  type        = string
  description = "Name of the app"
}

variable "region" {
  type        = string
  description = "AWS Deployment Region"
}

variable "app_domain_name" {
  type        = string
  description = "AWS Deployment Region"
}

variable "app_container_name" {
  type        = string
  description = "App Container Name"
}

variable "app_image" {
  type        = string
  description = "App Image"
}

variable "app_port" {
  type        = number
  description = "Port that the app is listening on"
}

variable "ecs_task_count" {
  type        = number
  description = "Number of tasks to run on Fargate"
}

#See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
variable "fargate_cpu" {
  type        = number
  description = "CPU requirement for each Fargate task"
}

variable "fargate_mem" {
  type        = number
  description = "Memory requirement for each Fargate task"
}
