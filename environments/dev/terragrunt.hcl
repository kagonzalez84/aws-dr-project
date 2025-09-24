# Development Environment Configuration
# This file contains all configuration for the dev environment infrastructure

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_path_to_repo_root()}//modules/infrastructure"
}

# Environment-specific inputs
inputs = {
  # Environment configuration
  environment                     = "dev"
  aws_region                     = "us-east-1"
  aws_secondary_region           = "us-west-2"
  project_name                   = "aws-dr-project"
  enable_cross_region_replication = true
  backup_retention_days          = 7  # Shorter retention for dev
  dr_backup_retention_days       = 14 # Shorter DR retention for dev

  # DynamoDB configuration
  dynamodb_table_name = "users"
  dynamodb_hash_key   = "user_id"
  dynamodb_range_key  = "created_at"
  dynamodb_attributes = [
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
  dynamodb_global_secondary_indexes = [
    {
      name            = "email-index"
      hash_key        = "email"
      projection_type = "ALL"
    }
  ]
  dynamodb_billing_mode                   = "PAY_PER_REQUEST"
  dynamodb_enable_point_in_time_recovery  = true
  dynamodb_enable_deletion_protection     = false
  dynamodb_enable_streams                 = false

  # S3 configuration
  s3_bucket_name                    = "aws-dr-project-dev-h44yuml9" # Use existing bucket
  s3_force_destroy                  = true # Allow destruction in dev
  s3_enable_versioning             = true
  s3_enable_mfa_delete             = false
  s3_lifecycle_rules = [
    {
      id      = "dev_lifecycle"
      enabled = true
      filter = {
        prefix = ""
      }
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]
  s3_enable_notifications = true
  s3_notification_events = [
    "s3:ObjectCreated:*",
    "s3:ObjectRemoved:*"
  ]

  # Backup configuration
  backup_enable_cross_region_backup = true
  backup_schedule                   = "cron(0 3 * * ? *)" # Daily at 3 AM
  backup_start_window              = 60
  backup_completion_window         = 480

  # Tags
  tags = {
    Purpose       = "aws-dr-demo"
    DataClass     = "test"
    BackupEnabled = "true"
  }
}