# AWS DR Project - Consolidated Infrastructure Module
# This module contains all S3, DynamoDB, and Backup resources in a single module

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.secondary]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
