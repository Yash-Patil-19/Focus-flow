variable "aws_region" {
  type        = string
  description = "AWS region for project resources"
  default     = "eu-west-1"
}
variable "project_name" {
  type        = string
  description = "Short resource prefix"
  default     = "focusflow"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "owner_tag" {
  type    = string
  default = "replace-with-your-name"
}
variable "container_port" {
  type    = number
  default = 8080
}
variable "image_tag" {
  type        = string
  description = "Existing image tag in ECR"
  default     = "bootstrap"
}
variable "desired_count" {
  type    = number
  default = 1
}
variable "task_cpu" {
  type    = number
  default = 256
}
variable "task_memory" {
  type    = number
  default = 512
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "availability_zones" {
  type        = list(string)
  description = "Two AZs in aws_region"
  default     = ["eu-west-1a", "eu-west-1b"]
}
