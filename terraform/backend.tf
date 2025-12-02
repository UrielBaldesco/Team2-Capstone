terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Update these values before running terraform init
    bucket         = "iam-root-terraform-state"
    key            = "capstone/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "iam-root-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region
}
