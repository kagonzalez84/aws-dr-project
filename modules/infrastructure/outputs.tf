# Outputs for the unified Infrastructure module

# S3 Outputs
output "s3_bucket_id" {
  description = "The name of the primary S3 bucket"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the primary S3 bucket"
  value       = module.s3.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "The bucket domain name of the primary S3 bucket"
  value       = module.s3.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name of the primary S3 bucket"
  value       = module.s3.bucket_regional_domain_name
}

output "s3_replica_bucket_id" {
  description = "The name of the replica S3 bucket"
  value       = module.s3.replica_bucket_id
}

output "s3_replica_bucket_arn" {
  description = "The ARN of the replica S3 bucket"
  value       = module.s3.replica_bucket_arn
}

output "s3_replication_role_arn" {
  description = "The ARN of the IAM role for S3 replication"
  value       = module.s3.replication_role_arn
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

output "dynamodb_table_id" {
  description = "The ID of the DynamoDB table"
  value       = module.dynamodb.table_id
}

output "dynamodb_global_table_arn" {
  description = "The ARN of the DynamoDB Global Table"
  value       = module.dynamodb.global_table_arn
}

output "dynamodb_stream_arn" {
  description = "The ARN of the DynamoDB table stream"
  value       = module.dynamodb.table_stream_arn
}

# Backup Outputs
output "backup_vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.backup_vault_arn
}

output "backup_vault_name" {
  description = "The name of the backup vault"
  value       = module.backup.backup_vault_name
}

output "backup_plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.backup.backup_plan_arn
}

output "backup_plan_id" {
  description = "The ID of the backup plan"
  value       = module.backup.backup_plan_id
}

output "dynamodb_backup_selection_id" {
  description = "The ID of the DynamoDB backup selection"
  value       = module.backup.dynamodb_selection_id
}

output "s3_backup_selection_id" {
  description = "The ID of the S3 backup selection"  
  value       = module.backup.s3_selection_id
}

output "dr_backup_vault_arn" {
  description = "The ARN of the DR backup vault"
  value       = module.backup.dr_backup_vault_arn
}

# Combined Infrastructure Summary
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    region      = var.aws_region
    dr_region   = var.aws_secondary_region
    resources = {
      s3_bucket         = module.s3.bucket_id
      s3_replica_bucket = module.s3.replica_bucket_id
      dynamodb_table    = module.dynamodb.table_name
      backup_vault      = module.backup.backup_vault_name
    }
    disaster_recovery = {
      cross_region_replication_enabled = var.enable_cross_region_replication
      backup_retention_days           = var.backup_retention_days
      dr_backup_retention_days        = var.dr_backup_retention_days
    }
  }
}