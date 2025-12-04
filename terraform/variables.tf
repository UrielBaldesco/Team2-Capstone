variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloud9-react-todo"
}

variable "project_name_lower" {
  description = "Lowercase project name for ECR compatibility"
  type        = string
  default     = "cloud9-react-todo"
}

variable "todo_bucket_name" {
  description = "S3 bucket name containing todo-data.json (from Phase 1 - GRACE)"
  type        = string
}

variable "ecr_repository_uri" { 
  description = "ECR repository URI (from Phase 2 - YOHAN)"
  type        = string
  default     = "cloud9-react-todo"
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

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}
