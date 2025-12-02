# AWS Secrets Manager for storing sensitive values
# Example: GitHub token, API keys, database passwords
resource "aws_secretsmanager_secret" "github_token" {
  name                    = "${var.project_name}-github-token"
  recovery_window_in_days = 7

  tags = {
    Project = var.project_name
  }
}

resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "${var.project_name}-db-credentials"
  recovery_window_in_days = 7

  tags = {
    Project = var.project_name
  }
}

# NOTE: To add secret values, use:
# 1. AWS Secrets Manager console, OR
# 2. AWS CLI: aws secretsmanager put-secret-value --secret-id <secret-name> --secret-string '<value>', OR
# 3. Terraform: Create aws_secretsmanager_secret_version resource, OR
# 4. Store sensitive values in terraform.tfvars (add to .gitignore)

# Example (DO NOT commit to GitHub):
# terraform.tfvars
# github_token = "ghp_xxxxxxxxxxxx"
# db_password = "your-secure-password"
#
# Then reference in Terraform:
# variable "github_token" {
#   type      = string
#   sensitive = true
# }
#
# resource "aws_secretsmanager_secret_version" "github" {
#   secret_id      = aws_secretsmanager_secret.github_token.id
#   secret_string  = var.github_token
# }
