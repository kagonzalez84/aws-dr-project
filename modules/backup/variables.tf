# Variables for AWS Backup module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM
}

variable "backup_start_window" {
  description = "The amount of time in minutes before beginning a backup"
  type        = number
  default     = 60
}

variable "backup_completion_window" {
  description = "The amount of time in minutes AWS Backup attempts a backup before canceling the job"
  type        = number
  default     = 480
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "backup_cold_storage_after" {
  description = "Number of days after creation that a recovery point is moved to cold storage"
  type        = number
  default     = 30
}

variable "dr_backup_retention_days" {
  description = "Number of days to retain DR backups in secondary region"
  type        = number
  default     = 90
}

variable "dr_backup_cold_storage_after" {
  description = "Number of days after creation that a DR recovery point is moved to cold storage"
  type        = number
  default     = 60
}

variable "enable_dynamodb_backup" {
  description = "Enable backup for DynamoDB tables"
  type        = bool
  default     = true
}

variable "enable_dynamodb_continuous_backup" {
  description = "Enable continuous backup for DynamoDB tables"
  type        = bool
  default     = true
}

variable "dynamodb_backup_schedule" {
  description = "Cron expression for DynamoDB backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM
}

variable "dynamodb_backup_retention_days" {
  description = "Number of days to retain DynamoDB backups"
  type        = number
  default     = 35 # Keep point-in-time recovery for 35 days
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs to backup"
  type        = list(string)
  default     = []
}

variable "enable_s3_backup" {
  description = "Enable backup for S3 buckets"
  type        = bool
  default     = true
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs to backup"
  type        = list(string)
  default     = []
}

variable "backup_tag_conditions" {
  description = "Tag-based conditions for backup selection"
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

variable "enable_backup_notifications" {
  description = "Enable SNS notifications for backup events"
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

variable "enable_backup_monitoring" {
  description = "Enable CloudWatch monitoring for backup jobs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}