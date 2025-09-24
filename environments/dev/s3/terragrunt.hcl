# Development S3 Configuration

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_path_to_repo_root()}//modules/s3"
}

inputs = {
  # Environment configuration
  environment                     = "dev"
  aws_region                     = "us-east-1"
  aws_secondary_region           = "us-west-2"
  enable_cross_region_replication = true
  backup_retention_days          = 7
  dr_backup_retention_days       = 14
  
  bucket_name                    = null # Will be auto-generated
  force_destroy                  = true # Allow destruction in dev
  enable_versioning             = true
  enable_mfa_delete             = false # MFA delete not needed for dev
  enable_cross_region_replication = true
  
  # Lifecycle rules for cost optimization
  lifecycle_rules = [
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
        days = 90 # Delete old versions after 90 days in dev
      }
    }
  ]

  # Notifications
  enable_notifications = true
  notification_events = [
    "s3:ObjectCreated:*",
    "s3:ObjectRemoved:*"
  ]

  tags = {
    Purpose       = "application-data"
    DataClass     = "test"
    BackupEnabled = "true"
  }
}