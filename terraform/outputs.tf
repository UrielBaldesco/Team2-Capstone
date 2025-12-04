output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.get_person.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.get_person.function_name
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "s3_bucket_name" {
  description = "S3 bucket for todo data"
  value       = aws_s3_bucket.todo_data.id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.react_todo.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = "terraform-state-${var.aws_account_id}"
}

output "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  value       = "terraform-lock"
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "app_https_url" {
  description = "HTTPS URL to access the React app (may show certificate warning)"
  value       = "https://${aws_lb.main.dns_name}"
}
