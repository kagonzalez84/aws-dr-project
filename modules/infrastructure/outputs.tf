# Outputs for the consolidated Infrastructure module

# S3 Outputs
output "s3_bucket_id" {
  description = "The name of the primary S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "The ARN of the primary S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_domain_name" {
  description = "The bucket domain name of the primary S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name of the primary S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "s3_replica_bucket_id" {
  description = "The name of the replica S3 bucket"
  value       = var.enable_cross_region_replication ? aws_s3_bucket.replica[0].id : null
}

output "s3_replica_bucket_arn" {
  description = "The ARN of the replica S3 bucket"
  value       = var.enable_cross_region_replication ? aws_s3_bucket.replica[0].arn : null
}

output "s3_replication_role_arn" {
  description = "The ARN of the IAM role for S3 replication"
  value       = var.enable_cross_region_replication ? aws_iam_role.replication[0].arn : null
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.main.arn
}

output "dynamodb_table_id" {
  description = "The ID of the DynamoDB table"
  value       = aws_dynamodb_table.main.id
}

output "dynamodb_global_table_arn" {
  description = "The ARN of the DynamoDB Global Table"
  value       = var.enable_cross_region_replication ? aws_dynamodb_global_table.main[0].arn : null
}

output "dynamodb_stream_arn" {
  description = "The ARN of the DynamoDB table stream"
  value       = aws_dynamodb_table.main.stream_arn
}

# Backup Outputs
output "backup_vault_arn" {
  description = "The ARN of the backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_name" {
  description = "The name of the backup vault"
  value       = aws_backup_vault.main.name
}

output "backup_plan_arn" {
  description = "The ARN of the backup plan"
  value       = aws_backup_plan.main.arn
}

output "backup_plan_id" {
  description = "The ID of the backup plan"
  value       = aws_backup_plan.main.id
}

output "dynamodb_backup_selection_id" {
  description = "The ID of the DynamoDB backup selection"
  value       = var.backup_enable_dynamodb_backup ? aws_backup_selection.dynamodb[0].id : null
}

output "s3_backup_selection_id" {
  description = "The ID of the S3 backup selection"
  value       = var.backup_enable_s3_backup ? aws_backup_selection.s3[0].id : null
}

output "dr_backup_vault_arn" {
  description = "The ARN of the DR backup vault"
  value       = var.backup_enable_cross_region_backup ? aws_backup_vault.dr[0].arn : null
}

# Combined Infrastructure Summary
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    region      = var.aws_region
    dr_region   = var.aws_secondary_region
    resources = {
      s3_bucket         = aws_s3_bucket.main.id
      s3_replica_bucket = var.enable_cross_region_replication ? aws_s3_bucket.replica[0].id : null
      dynamodb_table    = aws_dynamodb_table.main.name
      backup_vault      = aws_backup_vault.main.name
    }
    disaster_recovery = {
      cross_region_replication_enabled = var.enable_cross_region_replication
      backup_retention_days           = var.backup_retention_days
      dr_backup_retention_days        = var.dr_backup_retention_days
    }
  }
}