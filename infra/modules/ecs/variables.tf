variable "project_name" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "ecs_security_group_id" {
  type = string
}
variable "target_group_arn" {
  type = string
}
variable "task_execution_role_arn" {
  type = string
}
variable "image_uri" {
  type = string
}
variable "container_port" {
  type = number
}
variable "desired_count" {
  type = number
}
variable "task_cpu" {
  type = number
}
variable "task_memory" {
  type = number
}
