# Common Environment Configuration
# This file contains shared configuration values that can be reused across environments
# Following Gruntwork best practices for DRY configuration

locals {
  # Common DynamoDB configuration
  common_dynamodb_config = {
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
    billing_mode                   = "PAY_PER_REQUEST"
    enable_point_in_time_recovery  = true
    enable_streams                 = false
  }

  # Common S3 configuration
  common_s3_config = {
    enable_versioning = true
    enable_notifications = true
    notification_events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*"
    ]
  }

  # Common backup configuration
  common_backup_config = {
    enable_cross_region_backup = true
    start_window              = 60
    completion_window         = 480
  }

  # Common project configuration
  common_project_config = {
    project_name                   = "aws-dr-project"
    enable_cross_region_replication = true
    aws_region                     = "us-east-1"
    aws_secondary_region           = "us-west-2"
  }
}