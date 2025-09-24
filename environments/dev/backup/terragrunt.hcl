# Development Backup Configuration

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "${get_path_to_repo_root()}//modules/backup"
}

# Dependencies on other modules
dependency "dynamodb" {
  config_path = "../dynamodb"
  
  mock_outputs = {
    table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/mock-table"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

dependency "s3" {
  config_path = "../s3"
  
  mock_outputs = {
    bucket_arn = "arn:aws:s3:::mock-bucket"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  # Backup configuration
  enable_cross_region_backup = true
  backup_schedule           = "cron(0 3 * * ? *)" # Daily at 3 AM
  backup_retention_days     = 7                   # Short retention for dev
  dr_backup_retention_days  = 14                  # Short DR retention for dev
  
  # DynamoDB backup settings
  enable_dynamodb_backup            = true
  enable_dynamodb_continuous_backup = true
  dynamodb_backup_retention_days    = 7
  dynamodb_table_arns              = [dependency.dynamodb.outputs.table_arn]
  
  # S3 backup settings
  enable_s3_backup = true
  s3_bucket_arns  = [dependency.s3.outputs.bucket_arn]
  
  # Notifications and monitoring
  enable_backup_notifications = true
  enable_backup_monitoring    = true
  
  # Tag-based backup selection
  backup_tag_conditions = [
    {
      key   = "BackupEnabled"
      value = "true"
    },
    {
      key   = "Environment"
      value = "dev"
    }
  ]
  
  tags = {
    Purpose = "automated-backup"
  }
}