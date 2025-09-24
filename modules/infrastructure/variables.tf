# Variables for the consolidated Infrastructure module

# Common variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for disaster recovery"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "dr_backup_retention_days" {
  description = "Number of days to retain DR backups in secondary region"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# DynamoDB specific variables
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "dynamodb_hash_key" {
  description = "Hash key for the DynamoDB table"
  type        = string
}

variable "dynamodb_range_key" {
  description = "Range key for the DynamoDB table"
  type        = string
  default     = null
}

variable "dynamodb_attributes" {
  description = "List of attributes for the DynamoDB table"
  type = list(object({
    name = string
    type = string
  }))
}

variable "dynamodb_global_secondary_indexes" {
  description = "List of global secondary indexes"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
  }))
  default = []
}

variable "dynamodb_billing_mode" {
  description = "Controls how you are charged for read and write throughput"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB"
  type        = bool
  default     = true
}

variable "dynamodb_enable_deletion_protection" {
  description = "Enable deletion protection for DynamoDB"
  type        = bool
  default     = true
}

variable "dynamodb_enable_streams" {
  description = "Indicates whether DynamoDB Streams is to be enabled"
  type        = bool
  default     = false
}

variable "dynamodb_stream_view_type" {
  description = "When an item in the table is modified, what information is written to the stream"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "dynamodb_read_capacity" {
  description = "Number of read units for this table"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Number of write units for this table"
  type        = number
  default     = 5
}

variable "dynamodb_enable_autoscaling" {
  description = "Enable autoscaling for DynamoDB table"
  type        = bool
  default     = false
}

variable "dynamodb_autoscaling_read_max_capacity" {
  description = "Maximum read capacity for autoscaling"
  type        = number
  default     = 100
}

variable "dynamodb_autoscaling_read_min_capacity" {
  description = "Minimum read capacity for autoscaling"
  type        = number
  default     = 5
}

variable "dynamodb_autoscaling_read_target_value" {
  description = "Target value for read capacity autoscaling"
  type        = number
  default     = 70
}

variable "dynamodb_autoscaling_write_max_capacity" {
  description = "Maximum write capacity for autoscaling"
  type        = number
  default     = 100
}

variable "dynamodb_autoscaling_write_min_capacity" {
  description = "Minimum write capacity for autoscaling"
  type        = number
  default     = 5
}

variable "dynamodb_autoscaling_write_target_value" {
  description = "Target value for write capacity autoscaling"
  type        = number
  default     = 70
}

# S3 specific variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket (if not provided, will be generated)"
  type        = string
  default     = null
}

variable "s3_force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = false
}

variable "s3_enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_enable_mfa_delete" {
  description = "Enable MFA delete for the S3 bucket"
  type        = bool
  default     = false
}

variable "s3_kms_key_id" {
  description = "The AWS KMS master key ID used for the SSE-KMS encryption"
  type        = string
  default     = null
}

variable "s3_secondary_kms_key_id" {
  description = "The AWS KMS master key ID for the secondary region"
  type        = string
  default     = null
}

variable "s3_block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "s3_block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "s3_ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "s3_restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "s3_replication_storage_class" {
  description = "Storage class for cross-region replication"
  type        = string
  default     = "STANDARD_IA"
}

variable "s3_sns_topic_arn" {
  description = "SNS topic ARN for S3 bucket notifications"
  type        = string
  default     = null
}

variable "s3_lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket"
  type = list(object({
    id      = string
    enabled = bool
    filter = object({
      prefix = string
    })
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    noncurrent_version_transitions = list(object({
      days          = number
      storage_class = string
    }))
    noncurrent_version_expiration = object({
      days = number
    })
  }))
  default = []
}

variable "s3_enable_notifications" {
  description = "Enable S3 bucket notifications"
  type        = bool
  default     = false
}

variable "s3_notification_events" {
  description = "List of S3 events to notify on"
  type        = list(string)
  default     = []
}

# Backup specific variables
variable "backup_enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "backup_start_window" {
  description = "The amount of time in minutes before beginning a backup"
  type        = number
  default     = 60
}

variable "backup_completion_window" {
  description = "The amount of time in minutes AWS Backup attempts a backup before canceling the job"
  type        = number
  default     = 120
}

variable "backup_cold_storage_after" {
  description = "Specifies the number of days after creation that a recovery point is moved to cold storage"
  type        = number
  default     = 30
}

variable "backup_dr_cold_storage_after" {
  description = "Specifies the number of days after creation that a DR recovery point is moved to cold storage"
  type        = number
  default     = 60
}

variable "backup_enable_dynamodb_continuous_backup" {
  description = "Enable continuous backup for DynamoDB"
  type        = bool
  default     = true
}

variable "backup_dynamodb_backup_schedule" {
  description = "DynamoDB backup schedule in cron format"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "backup_dynamodb_backup_retention_days" {
  description = "Number of days to retain DynamoDB backups"
  type        = number
  default     = 35
}

variable "backup_enable_dynamodb_backup" {
  description = "Enable backup for DynamoDB tables"
  type        = bool
  default     = true
}

variable "backup_enable_s3_backup" {
  description = "Enable backup for S3 buckets"
  type        = bool
  default     = true
}

variable "backup_tag_conditions" {
  description = "Tag conditions for backup selection"
  type = list(object({
    key   = string
    value = string
  }))
  default = [
    {
      key   = "BackupEnabled"
      value = "true"
    }
  ]
}

variable "backup_enable_backup_notifications" {
  description = "Enable backup notifications"
  type        = bool
  default     = true
}

variable "backup_notification_events" {
  description = "List of backup events to notify on"
  type        = list(string)
  default = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_STARTED", 
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]
}

variable "backup_enable_backup_monitoring" {
  description = "Enable backup monitoring with CloudWatch alarms"
  type        = bool
  default     = true
}