# Production Environment Configuration
# This file contains all configuration for the production environment infrastructure
# Following Gruntwork best practices for environment-specific configuration

# Local values for production environment
locals {
  # Load common configuration
  common_config = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  # Environment-specific configuration
  env_name = "prod"
  
  # Production-specific settings (more conservative)
  prod_settings = {
    backup_retention_days    = 30  # Longer retention for prod
    dr_backup_retention_days = 90  # Longer DR retention for prod
    force_destroy           = false # Prevent accidental destruction in prod
    enable_deletion_protection = true
    enable_mfa_delete       = true # Enable MFA delete for prod
    enable_streams          = true # Enable streams for prod
  }
  
  # Merge common tags with environment-specific tags
  env_tags = {
    Environment   = local.env_name
    Purpose       = "aws-dr-production"
    DataClass     = "production"
    BackupEnabled = "true"
    Compliance    = "required"
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

# Production-specific inputs following best practices
inputs = {
  # Environment configuration using common config
  environment                     = local.env_name
  aws_region                     = local.common_config.locals.common_project_config.aws_region
  aws_secondary_region           = local.common_config.locals.common_project_config.aws_secondary_region
  project_name                   = local.common_config.locals.common_project_config.project_name
  enable_cross_region_replication = local.common_config.locals.common_project_config.enable_cross_region_replication
  backup_retention_days          = local.prod_settings.backup_retention_days
  dr_backup_retention_days       = local.prod_settings.dr_backup_retention_days

  # DynamoDB configuration using common config with prod overrides
  dynamodb_table_name = local.common_config.locals.common_dynamodb_config.table_name
  dynamodb_hash_key   = local.common_config.locals.common_dynamodb_config.hash_key
  dynamodb_range_key  = local.common_config.locals.common_dynamodb_config.range_key
  dynamodb_attributes = local.common_config.locals.common_dynamodb_config.attributes
  dynamodb_global_secondary_indexes = local.common_config.locals.common_dynamodb_config.global_secondary_indexes
  dynamodb_billing_mode                   = local.common_config.locals.common_dynamodb_config.billing_mode
  dynamodb_enable_point_in_time_recovery  = local.common_config.locals.common_dynamodb_config.enable_point_in_time_recovery
  dynamodb_enable_deletion_protection     = local.prod_settings.enable_deletion_protection
  dynamodb_enable_streams                 = local.prod_settings.enable_streams

  # S3 configuration (production settings)
  s3_bucket_name                    = "aws-dr-project-${local.env_name}" # Production bucket name
  s3_force_destroy                  = local.prod_settings.force_destroy
  s3_enable_versioning             = local.common_config.locals.common_s3_config.enable_versioning
  s3_enable_mfa_delete             = local.prod_settings.enable_mfa_delete
  s3_lifecycle_rules = [
    {
      id      = "prod_lifecycle"
      enabled = true
      filter = {
        prefix = ""
      }
      transitions = [
        {
          days          = 60  # Longer transitions for prod
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      noncurrent_version_transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 365 # Keep old versions longer in prod
      }
    }
  ]
  s3_enable_notifications = local.common_config.locals.common_s3_config.enable_notifications
  s3_notification_events = local.common_config.locals.common_s3_config.notification_events

  # Backup configuration using common config with prod overrides
  backup_enable_cross_region_backup = local.common_config.locals.common_backup_config.enable_cross_region_backup
  backup_schedule                   = "cron(0 2 * * ? *)" # Daily at 2 AM for prod
  backup_start_window              = local.common_config.locals.common_backup_config.start_window
  backup_completion_window         = local.common_config.locals.common_backup_config.completion_window

  # Tags merged with environment-specific values
  tags = local.env_tags
}