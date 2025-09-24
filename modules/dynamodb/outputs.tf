# Outputs for DynamoDB module

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.main.name
}

output "table_id" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.main.id
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.main.arn
}

output "table_stream_arn" {
  description = "The ARN of the Table Stream"
  value       = try(aws_dynamodb_table.main.stream_arn, null)
}

output "table_stream_label" {
  description = "A timestamp, in ISO 8601 format, for this stream"
  value       = try(aws_dynamodb_table.main.stream_label, null)
}

output "replica_table_name" {
  description = "Name of the replica DynamoDB table"
  value       = try(aws_dynamodb_table.replica[0].name, null)
}

output "replica_table_arn" {
  description = "ARN of the replica DynamoDB table"
  value       = try(aws_dynamodb_table.replica[0].arn, null)
}

output "global_table_name" {
  description = "Name of the DynamoDB Global Table"
  value       = try(aws_dynamodb_global_table.main[0].name, null)
}

output "global_table_arn" {
  description = "ARN of the DynamoDB Global Table"
  value       = try(aws_dynamodb_global_table.main[0].arn, null)
}