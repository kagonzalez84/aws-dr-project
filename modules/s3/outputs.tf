# Outputs for S3 module

output "bucket_id" {
  description = "The name of the primary bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the primary bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "replica_bucket_id" {
  description = "The name of the replica bucket"
  value       = try(aws_s3_bucket.replica[0].id, null)
}

output "replica_bucket_arn" {
  description = "The ARN of the replica bucket"
  value       = try(aws_s3_bucket.replica[0].arn, null)
}

output "replication_role_arn" {
  description = "The ARN of the replication IAM role"
  value       = try(aws_iam_role.replication[0].arn, null)
}