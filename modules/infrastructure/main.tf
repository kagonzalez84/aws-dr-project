# AWS DR Project - Unified Infrastructure Module
# This module deploys S3, DynamoDB, and Backup services as a single unit

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

# S3 Module
module "s3" {
  source = "../s3"
  
  project_name                    = var.project_name
  environment                     = var.environment
  bucket_name                     = var.s3_bucket_name
  force_destroy                   = var.s3_force_destroy
  enable_versioning              = var.s3_enable_versioning
  enable_mfa_delete              = var.s3_enable_mfa_delete
  enable_cross_region_replication = var.enable_cross_region_replication
  lifecycle_rules                = var.s3_lifecycle_rules
  enable_notifications           = var.s3_enable_notifications
  notification_events            = var.s3_notification_events
  tags                           = var.tags

  providers = {
    aws.secondary = aws.secondary
  }
}

# DynamoDB Module
module "dynamodb" {
  source = "../dynamodb"
  
  project_name                      = var.project_name
  environment                       = var.environment
  aws_region                        = var.aws_region
  aws_secondary_region              = var.aws_secondary_region
  table_name                        = var.dynamodb_table_name
  hash_key                         = var.dynamodb_hash_key
  range_key                        = var.dynamodb_range_key
  attributes                       = var.dynamodb_attributes
  global_secondary_indexes         = var.dynamodb_global_secondary_indexes
  billing_mode                     = var.dynamodb_billing_mode
  enable_point_in_time_recovery    = var.dynamodb_enable_point_in_time_recovery
  enable_deletion_protection       = var.dynamodb_enable_deletion_protection
  enable_cross_region_replication  = var.enable_cross_region_replication
  enable_streams                   = var.dynamodb_enable_streams
  tags                            = var.tags

  providers = {
    aws.secondary = aws.secondary
  }
}

# Backup Module
module "backup" {
  source = "../backup"
  
  project_name                  = var.project_name
  environment                  = var.environment
  enable_cross_region_backup   = var.backup_enable_cross_region_backup
  backup_schedule              = var.backup_schedule
  backup_retention_days        = var.backup_retention_days
  dr_backup_retention_days     = var.dr_backup_retention_days
  backup_start_window          = var.backup_start_window
  backup_completion_window     = var.backup_completion_window
  tags                         = var.tags
  
  # Pass resource ARNs from other modules
  dynamodb_table_arns = [module.dynamodb.table_arn]
  s3_bucket_arns      = [module.s3.bucket_arn]

  providers = {
    aws.secondary = aws.secondary
  }

  depends_on = [
    module.s3,
    module.dynamodb
  ]
}