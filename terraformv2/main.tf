terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
  # DO NOT hardcode credentials in code. Use environment variables or a profile.
  # access_key = "*****"
  # secret_key = "*****"
}

/* ------- S3 Bucket (App Data) ------ */
resource "aws_s3_bucket" "iamroot2_app_bucket" {
  bucket = "iamroot2-app-bucket" # S3 bucket names must be globally unique
}

resource "aws_s3_bucket_versioning" "iamroot2_app_bucket_versioning" {
  bucket = aws_s3_bucket.iamroot2_app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Note: fileset() returns a list of file paths; we should use each.value consistently
resource "aws_s3_object" "iamroot2_app_bucket_objects" {
  for_each = fileset("./jsondata/", "**")
  bucket   = aws_s3_bucket.iamroot2_app_bucket.id
  key      = each.value
  source   = "./jsondata/${each.value}"
  etag     = filemd5("./jsondata/${each.value}")
}

/* ------- ECR Repo ------ */
resource "aws_ecr_repository" "iamroot2_ecr_repo" {
  name = "iamroot2-ecr-repo"
}

/* ------- CodeBuild IAM Role ------ */
data "aws_iam_policy_document" "iamroot2_assume_codebuild_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iamroot2_codebuild_role" {
  name               = "iamroot2-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.iamroot2_assume_codebuild_policy.json
}

resource "aws_iam_role_policy" "iamroot2_codebuild_inline_policy" {
  role = aws_iam_role.iamroot2_codebuild_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.iamroot2_codepipeline_bucket.arn}",
        "${aws_s3_bucket.iamroot2_codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "iamroot2_codebuild_ecr_poweruser" {
  role       = aws_iam_role.iamroot2_codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

/* ------- CodeBuild Project ------ */
resource "aws_codebuild_project" "iamroot2_codebuild" {
  name         = "iamroot2-codebuild"
  description  = "iamroot2-codebuild-project"
  service_role = aws_iam_role.iamroot2_codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0" # updated image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "962804699607" # <-- verify
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-west-2"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.iamroot2_ecr_repo.id
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
    environment_variable {
      name  = "CLUSTER_NAME"
      value = aws_ecs_cluster.iamroot2_cluster.id
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = aws_ecs_service.iamroot2_service.id
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/UrielBaldesco/Team2-Capstone.git" # <-- verify repo
    git_clone_depth = 1
  }
}

/* ------- CodePipeline ------ */
data "aws_iam_policy_document" "iamroot2_assume_codepipeline_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iamroot2_codepipeline_role" {
  name               = "iamroot2-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.iamroot2_assume_codepipeline_policy.json
}

resource "aws_s3_bucket" "iamroot2_codepipeline_bucket" {
  bucket = "iamroot2-artifact-bucket" # must be globally unique
}

resource "aws_s3_bucket_acl" "iamroot2_codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.iamroot2_codepipeline_bucket.id
  acl    = "private"
}

resource "aws_codestarconnections_connection" "iamroot2_codestar_connection" {
  name          = "iamroot2-cs-connection"
  provider_type = "GitHub"
}

resource "aws_iam_role_policy" "iamroot2_codepipeline_policy" {
  name = "iamroot2-codepipeline-policy"
  role = aws_iam_role.iamroot2_codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.iamroot2_codepipeline_bucket.arn}",
        "${aws_s3_bucket.iamroot2_codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.iamroot2_codestar_connection.arn}"  // Use ARN, not ID
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "iamroot2_codepipeline" {
  name     = "iamroot2-codepipeline"
  role_arn = aws_iam_role.iamroot2_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.iamroot2_codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = 1
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.iamroot2_codestar_connection.arn
        FullRepositoryId = "tewqs-a/room3capstone2"  # <-- verify org/repo
        BranchName       = "master"                  # <-- verify branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.iamroot2_codebuild.id
      }
    }
  }
}

/* ------ Networking: Default VPC & Subnets ------ */
resource "aws_default_vpc" "iamroot2_default_vpc" {}

resource "aws_default_subnet" "iamroot2_default_subnet_a" {
  availability_zone = "us-west-2a"
}

resource "aws_default_subnet" "iamroot2_default_subnet_b" {
  availability_zone = "us-west-2b"
}

resource "aws_default_subnet" "iamroot2_default_subnet_c" {
  availability_zone = "us-west-2c"
}

/* ------ ECS Cluster/Task/Service ------ */
resource "aws_ecs_cluster" "iamroot2_cluster" {
  name = "iamroot2-ecs-cluster"
}

data "aws_iam_policy_document" "iamroot2_assume_ecs_task_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iamroot2_ecs_task_execution_role" {
  name               = "iamroot2-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.iamroot2_assume_ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "iamroot2_ecs_task_execution_role_attachment" {
  role       = aws_iam_role.iamroot2_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "iamroot2_task" {
  family                   = "iamroot2-task"
  container_definitions    = <<DEFINITION
[
  {
    "name": "iamroot2-task",
    "image": "${aws_ecr_repository.iamroot2_ecr_repo.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000,
        "protocol": "tcp"
      }
    ],
    "memory": 512,
    "cpu": 256
  }
]
DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.iamroot2_ecs_task_execution_role.arn
}

/* ------ Load Balancer & Target Group ------ */
resource "aws_security_group" "iamroot2_alb_sg" {
  name   = "iamroot2-alb-sg"
  vpc_id = aws_default_vpc.iamroot2_default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "iamroot2_alb" {
  name               = "iamroot2-alb"
  load_balancer_type = "application"
  subnets = [
    aws_default_subnet.iamroot2_default_subnet_a.id,
    aws_default_subnet.iamroot2_default_subnet_b.id,
    aws_default_subnet.iamroot2_default_subnet_c.id
  ]
  security_groups = [aws_security_group.iamroot2_alb_sg.id]
}

# Use port 3000 to match the container port, or add a target group health check override
resource "aws_lb_target_group" "iamroot2_tg" {
  name        = "iamroot2-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.iamroot2_default_vpc.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "iamroot2_listener" {
  load_balancer_arn = aws_alb.iamroot2_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.iamroot2_tg.arn
  }
}

/* ------ ECS Service ------ */
resource "aws_security_group" "iamroot2_service_sg" {
  name   = "iamroot2-service-sg"
  vpc_id = aws_default_vpc.iamroot2_default_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.iamroot2_alb_sg.id] # only ALB can reach service
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "iamroot2_service" {
  name            = "iamroot2-service"
  cluster         = aws_ecs_cluster.iamroot2_cluster.id
  task_definition = aws_ecs_task_definition.iamroot2_task.arn
  launch_type     = "FARGATE"
  desired_count   = 3

  load_balancer {
    target_group_arn = aws_lb_target_group.iamroot2_tg.arn
    container_name   = aws_ecs_task_definition.iamroot2_task.family
    container_port   = 3000
  }

  network_configuration {
    subnets          = [
      aws_default_subnet.iamroot2_default_subnet_a.id,
      aws_default_subnet.iamroot2_default_subnet_b.id,
      aws_default_subnet.iamroot2_default_subnet_c.id
    ]
    assign_public_ip = true
    security_groups  = [aws_security_group.iamroot2_service_sg.id]
  }

  depends_on = [aws_lb_listener.iamroot2_listener]
}
