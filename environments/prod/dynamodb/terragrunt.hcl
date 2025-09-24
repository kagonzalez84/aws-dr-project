# Production DynamoDB Configuration

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "${get_path_to_repo_root()}//modules/dynamodb"
}

# Prevent destroy for production safety
prevent_destroy = true

inputs = {
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
      name               = "email-index"
      hash_key           = "email"
      projection_type    = "ALL"
      read_capacity      = 10
      write_capacity     = 5
    }
  ]

  # Production-specific settings
  billing_mode                   = "PROVISIONED" # More predictable costs for prod
  read_capacity                  = 20
  write_capacity                 = 10
  enable_autoscaling             = true
  autoscaling_read_min_capacity  = 20
  autoscaling_read_max_capacity  = 100
  autoscaling_write_min_capacity = 10
  autoscaling_write_max_capacity = 50
  
  enable_point_in_time_recovery  = true
  enable_deletion_protection     = true  # Prevent accidental deletion
  enable_cross_region_replication = true
  enable_streams                 = true  # Enable streams for prod
  stream_view_type              = "NEW_AND_OLD_IMAGES"
  
  tags = {
    Purpose       = "user-management"
    DataClass     = "production"
    Compliance    = "required"
    BackupEnabled = "true"
  }
}