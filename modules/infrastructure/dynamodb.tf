# =============================================
# DYNAMODB RESOURCES
# =============================================

# Primary region DynamoDB table
resource "aws_dynamodb_table" "main" {
  name           = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = var.dynamodb_hash_key
  range_key      = var.dynamodb_range_key
  
  # Read and write capacity for provisioned mode
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  # Enable Point-in-Time Recovery for disaster recovery
  point_in_time_recovery {
    enabled = var.dynamodb_enable_point_in_time_recovery
  }

  # Enable deletion protection to prevent accidental deletion
  deletion_protection_enabled = var.dynamodb_enable_deletion_protection

  # Define attributes
  dynamic "attribute" {
    for_each = var.dynamodb_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.dynamodb_global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
      
      # Capacity settings for provisioned mode
      read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Stream configuration for replication
  stream_enabled   = var.dynamodb_enable_streams
  stream_view_type = var.dynamodb_enable_streams ? var.dynamodb_stream_view_type : null

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}"
      BackupEnabled = "true"
      Environment = var.environment
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Cross-region replica table for disaster recovery
resource "aws_dynamodb_table" "replica" {
  count = var.enable_cross_region_replication ? 1 : 0
  
  provider = aws.secondary
  
  name           = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = var.dynamodb_hash_key
  range_key      = var.dynamodb_range_key
  
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  # Enable Point-in-Time Recovery
  point_in_time_recovery {
    enabled = var.dynamodb_enable_point_in_time_recovery
  }

  deletion_protection_enabled = var.dynamodb_enable_deletion_protection

  # Define attributes
  dynamic "attribute" {
    for_each = var.dynamodb_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.dynamodb_global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
      
      read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}-replica"
      Purpose = "disaster-recovery"
      Environment = var.environment
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Global table configuration for cross-region replication
resource "aws_dynamodb_global_table" "main" {
  count = var.enable_cross_region_replication ? 1 : 0
  
  name = aws_dynamodb_table.main.name

  replica {
    region_name = var.aws_region
  }

  replica {
    region_name = var.aws_secondary_region
  }

  depends_on = [
    aws_dynamodb_table.main,
    aws_dynamodb_table.replica[0]
  ]
}

# Application autoscaling for read capacity
resource "aws_appautoscaling_target" "read_target" {
  count = var.dynamodb_billing_mode == "PROVISIONED" && var.dynamodb_enable_autoscaling ? 1 : 0
  
  max_capacity       = var.dynamodb_autoscaling_read_max_capacity
  min_capacity       = var.dynamodb_autoscaling_read_min_capacity
  resource_id        = "table/${aws_dynamodb_table.main.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  count = var.dynamodb_billing_mode == "PROVISIONED" && var.dynamodb_enable_autoscaling ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.dynamodb_autoscaling_read_target_value
  }
}

# Application autoscaling for write capacity
resource "aws_appautoscaling_target" "write_target" {
  count = var.dynamodb_billing_mode == "PROVISIONED" && var.dynamodb_enable_autoscaling ? 1 : 0
  
  max_capacity       = var.dynamodb_autoscaling_write_max_capacity
  min_capacity       = var.dynamodb_autoscaling_write_min_capacity
  resource_id        = "table/${aws_dynamodb_table.main.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy" {
  count = var.dynamodb_billing_mode == "PROVISIONED" && var.dynamodb_enable_autoscaling ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.dynamodb_autoscaling_write_target_value
  }
}