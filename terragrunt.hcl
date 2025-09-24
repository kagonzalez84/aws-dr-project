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
  if_exists = "overwrite"
  contents = <<EOF
# Primary region provider
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "aws-dr-project"
      Environment = "dev"
      ManagedBy   = "terragrunt"
      Repository  = "aws-dr-project"
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
      Environment = "dev"
      ManagedBy   = "terragrunt"
      Repository  = "aws-dr-project"
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