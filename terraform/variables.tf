variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "react-todo"
}

variable "todo_bucket_name" {
  description = "S3 bucket name containing todo-data.json (from Phase 1 - GRACE)"
  type        = string
}

variable "ecr_repository_uri" {
  description = "ECR repository URI (from Phase 2 - YOHAN)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name (from Phase 2 - YOHAN)"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name (from Phase 2 - YOHAN)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}
