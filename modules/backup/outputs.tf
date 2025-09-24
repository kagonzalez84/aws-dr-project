# Outputs for AWS Backup module

output "backup_vault_name" {
  description = "Name of the primary backup vault"
  value       = aws_backup_vault.main.name
}

output "backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_kms_key_arn" {
  description = "ARN of the KMS key used for backup vault encryption"
  value       = aws_kms_key.backup.arn
}

output "dr_backup_vault_name" {
  description = "Name of the DR backup vault"
  value       = try(aws_backup_vault.dr[0].name, null)
}

output "dr_backup_vault_arn" {
  description = "ARN of the DR backup vault"
  value       = try(aws_backup_vault.dr[0].arn, null)
}

output "dr_backup_vault_kms_key_arn" {
  description = "ARN of the KMS key used for DR backup vault encryption"
  value       = try(aws_kms_key.backup_dr[0].arn, null)
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.main.id
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.main.arn
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = aws_iam_role.backup.arn
}

output "backup_notifications_topic_arn" {
  description = "ARN of the SNS topic for backup notifications"
  value       = try(aws_sns_topic.backup_notifications[0].arn, null)
}

output "dynamodb_selection_id" {
  description = "ID of the DynamoDB backup selection"
  value       = try(aws_backup_selection.dynamodb[0].id, null)
}

output "s3_selection_id" {
  description = "ID of the S3 backup selection"
  value       = try(aws_backup_selection.s3[0].id, null)
}