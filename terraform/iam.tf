# Lambda Execution Role (for reading from S3)
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy: Allow Lambda to read from S3
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name   = "${var.project_name}-lambda-s3-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.todo_data.arn,
          "${aws_s3_bucket.todo_data.arn}/*"
        ]
      }
    ]
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_exec_role" {
  name = "${var.project_name}-ecs-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for app to access AWS services if needed)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodeBuild Service Role (for CI/CD pipeline)
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodeBuild Policy: ECR permissions
resource "aws_iam_role_policy" "codebuild_ecr_policy" {
  name   = "${var.project_name}-codebuild-ecr-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Policy: ECS permissions
resource "aws_iam_role_policy" "codebuild_ecs_policy" {
  name   = "${var.project_name}-codebuild-ecs-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTaskAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Policy: S3 permissions (for Terraform state)
resource "aws_iam_role_policy" "codebuild_s3_policy" {
  name   = "${var.project_name}-codebuild-s3-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketVersioning",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Policy: DynamoDB permissions (for Terraform state locking)
resource "aws_iam_role_policy" "codebuild_dynamodb_policy" {
  name   = "${var.project_name}-codebuild-dynamodb-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Policy: Terraform/IAM/Lambda permissions
resource "aws_iam_role_policy" "codebuild_infra_policy" {
  name   = "${var.project_name}-codebuild-infra-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:*",
          "apigateway:*",
          "iam:*",
          "eks:*",
          "ec2:*",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Logs policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_logs_policy" {
  name   = "${var.project_name}-codebuild-logs-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
