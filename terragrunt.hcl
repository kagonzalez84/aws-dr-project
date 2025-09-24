# Root Terragrunt Configuration
# This file contains shared configuration for all environments
# Following Gruntwork best practices for Terragrunt configuration

# Local values for common configuration
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = "aws-dr-project"
    ManagedBy   = "terragrunt"
    Repository  = "aws-dr-project"
    IaC         = "terragrunt"
  }
  
  # AWS account ID for state bucket naming
  account_id = get_aws_account_id()
}

# Configure remote state backend
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-state-${local.account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dr-project-terraform-locks"
    
    # Enable state locking and consistency checking
    skip_bucket_versioning         = false
    skip_bucket_ssencryption      = false
    skip_bucket_root_access       = false
    skip_bucket_enforced_tls      = false
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
# Primary region provider
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "aws-dr-project"
      ManagedBy   = "terragrunt"
      Repository  = "aws-dr-project"
      IaC         = "terragrunt"
    }
  }
}

# Secondary region provider for DR
provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
  
  default_tags {
    tags = {
      Project     = "aws-dr-project"
      ManagedBy   = "terragrunt"
      Repository  = "aws-dr-project"
      IaC         = "terragrunt"
      Purpose     = "disaster-recovery"
    }
  }
}
EOF
}

# Variables are defined in individual modules
# Common inputs that will be merged with environment-specific inputs
inputs = {
  project_name = "aws-dr-project"
  enable_cross_region_replication = true
}