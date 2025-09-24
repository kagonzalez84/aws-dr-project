# Development DynamoDB Configuration

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_path_to_repo_root()}//modules/dynamodb"
}

# Prevent destroy for safety
prevent_destroy = false

inputs = {
  # Environment configuration
  environment                     = "dev"
  aws_region                     = "us-east-1"
  aws_secondary_region           = "us-west-2"
  enable_cross_region_replication = true
  backup_retention_days          = 7
  dr_backup_retention_days       = 14
  
  table_name = "users"
  hash_key   = "user_id"
  range_key  = "created_at"

  attributes = [
    {
      name = "user_id"
      type = "S"
    },
    {
      name = "created_at"
      type = "S"
    },
    {
      name = "email"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "email-index"
      hash_key        = "email"
      projection_type = "ALL"
    }
  ]

  # Development-specific settings
  billing_mode                   = "PAY_PER_REQUEST" # More cost-effective for dev
  enable_point_in_time_recovery  = true
  enable_deletion_protection     = false            # Allow deletion in dev
  enable_cross_region_replication = true
  enable_streams                 = false            # Disable streams in dev unless needed
  
  tags = {
    Purpose     = "user-management"
    DataClass   = "test"
    BackupEnabled = "true"
  }
}