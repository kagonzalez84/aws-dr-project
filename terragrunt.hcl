# Root Terragrunt Configuration
# This file contains shared configuration for all environments

# Configure remote state backend
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dr-project-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Primary region provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "aws-dr-project"
      Environment = var.environment
      ManagedBy   = "terragrunt"
      Repository  = "aws-dr-project"
    }
  }
}

# Secondary region provider for DR
provider "aws" {
  alias  = "secondary"
  region = var.aws_secondary_region
  
  default_tags {
    tags = {
      Project     = "aws-dr-project"
      Environment = var.environment
      ManagedBy   = "terragrunt"
      Repository  = "aws-dr-project"
      Purpose     = "disaster-recovery"
    }
  }
}

# Random provider for generating unique names
provider "random" {}
EOF
}

# Generate common variables
generate "variables" {
  path = "variables.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-dr-project"
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for disaster recovery"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "dr_backup_retention_days" {
  description = "Number of days to retain DR backups in secondary region"
  type        = number
  default     = 90
}
EOF
}

# Common inputs that will be merged with environment-specific inputs
inputs = {
  project_name = "aws-dr-project"
  enable_cross_region_replication = true
}