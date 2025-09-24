# Development Environment Configuration
# This file contains all configuration for the dev environment infrastructure
# Following Gruntwork best practices for environment-specific configuration

# Local values for dev environment
locals {
  # Load common configuration
  common_config = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  # Environment-specific configuration
  env_name = "dev"
  
  # Environment-specific settings
  dev_settings = {
    backup_retention_days    = 7   # Shorter retention for dev
    dr_backup_retention_days = 14  # Shorter DR retention for dev
    force_destroy           = true # Allow destruction in dev
    enable_deletion_protection = false
    enable_mfa_delete       = false
    enable_streams          = false # Streams not needed in dev
  }
  
  # Merge common tags with environment-specific tags
  env_tags = {
    Environment   = local.env_name
    Purpose       = "aws-dr-demo"
    DataClass     = "test"
    BackupEnabled = "true"
  }
}

# Include root configuration with deep merge strategy
include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

# Terraform module source configuration
terraform {
  source = "${get_path_to_repo_root()}//modules/infrastructure"
}

# Environment-specific inputs following best practices
inputs = {
  # Environment configuration using common config
  environment                     = local.env_name
  aws_region                     = local.common_config.locals.common_project_config.aws_region
  aws_secondary_region           = local.common_config.locals.common_project_config.aws_secondary_region
  project_name                   = local.common_config.locals.common_project_config.project_name
  enable_cross_region_replication = local.common_config.locals.common_project_config.enable_cross_region_replication
  backup_retention_days          = local.dev_settings.backup_retention_days
  dr_backup_retention_days       = local.dev_settings.dr_backup_retention_days

  # DynamoDB configuration using common config with dev overrides
  dynamodb_table_name = local.common_config.locals.common_dynamodb_config.table_name
  dynamodb_hash_key   = local.common_config.locals.common_dynamodb_config.hash_key
  dynamodb_range_key  = local.common_config.locals.common_dynamodb_config.range_key
  dynamodb_attributes = local.common_config.locals.common_dynamodb_config.attributes
  dynamodb_global_secondary_indexes = local.common_config.locals.common_dynamodb_config.global_secondary_indexes
  dynamodb_billing_mode                   = local.common_config.locals.common_dynamodb_config.billing_mode
  dynamodb_enable_point_in_time_recovery  = local.common_config.locals.common_dynamodb_config.enable_point_in_time_recovery
  dynamodb_enable_deletion_protection     = local.dev_settings.enable_deletion_protection
  dynamodb_enable_streams                 = local.dev_settings.enable_streams

  # S3 configuration
  s3_bucket_name                    = "aws-dr-project-${local.env_name}-h44yuml9" # Use existing bucket
  s3_force_destroy                  = local.dev_settings.force_destroy
  s3_enable_versioning             = local.common_config.locals.common_s3_config.enable_versioning
  s3_enable_mfa_delete             = local.dev_settings.enable_mfa_delete
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
  s3_enable_notifications = local.common_config.locals.common_s3_config.enable_notifications
  s3_notification_events = local.common_config.locals.common_s3_config.notification_events

  # Backup configuration using common config with dev overrides
  backup_enable_cross_region_backup = local.common_config.locals.common_backup_config.enable_cross_region_backup
  backup_schedule                   = "cron(0 3 * * ? *)" # Daily at 3 AM for dev
  backup_start_window              = local.common_config.locals.common_backup_config.start_window
  backup_completion_window         = local.common_config.locals.common_backup_config.completion_window

  # Tags merged with environment-specific values
  tags = local.env_tags
}