# =============================================
# S3 RESOURCES
# =============================================

locals {
  s3_bucket_name = var.s3_bucket_name != null ? var.s3_bucket_name : "${var.project_name}-${var.environment}-${random_string.bucket_suffix[0].result}"
}

# Random string for unique bucket naming (only when bucket_name is not provided)
resource "random_string" "bucket_suffix" {
  count   = var.s3_bucket_name == null ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Primary S3 bucket
resource "aws_s3_bucket" "main" {
  bucket        = local.s3_bucket_name
  force_destroy = var.s3_force_destroy

  tags = merge(
    var.tags,
    {
      Name        = local.s3_bucket_name
      Environment = var.environment
      Purpose     = "primary"
    }
  )
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status     = var.s3_enable_versioning ? "Enabled" : "Suspended"
    mfa_delete = var.s3_enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_kms_key_id
      sse_algorithm     = var.s3_kms_key_id != null ? "aws:kms" : "AES256"
    }
    bucket_key_enabled = var.s3_kms_key_id != null ? true : false
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.s3_block_public_acls
  block_public_policy     = var.s3_block_public_policy
  ignore_public_acls      = var.s3_ignore_public_acls
  restrict_public_buckets = var.s3_restrict_public_buckets
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = length(var.s3_lifecycle_rules) > 0 ? 1 : 0

  bucket     = aws_s3_bucket.main.id
  depends_on = [aws_s3_bucket_versioning.main]

  dynamic "rule" {
    for_each = var.s3_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          prefix = filter.value.prefix
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions != null ? rule.value.noncurrent_version_transitions : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# Cross-region replication bucket (for disaster recovery)
resource "aws_s3_bucket" "replica" {
  count = var.enable_cross_region_replication ? 1 : 0

  provider      = aws.secondary
  bucket        = "${local.s3_bucket_name}-replica"
  force_destroy = var.s3_force_destroy

  tags = merge(
    var.tags,
    {
      Name        = "${local.s3_bucket_name}-replica"
      Environment = var.environment
      Purpose     = "disaster-recovery"
    }
  )
}

# Versioning for replica bucket
resource "aws_s3_bucket_versioning" "replica" {
  count = var.enable_cross_region_replication ? 1 : 0

  provider = aws.secondary
  bucket   = aws_s3_bucket.replica[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for replica bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  count = var.enable_cross_region_replication ? 1 : 0

  provider = aws.secondary
  bucket   = aws_s3_bucket.replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_secondary_kms_key_id
      sse_algorithm     = var.s3_secondary_kms_key_id != null ? "aws:kms" : "AES256"
    }
    bucket_key_enabled = var.s3_secondary_kms_key_id != null ? true : false
  }
}

# Public access block for replica
resource "aws_s3_bucket_public_access_block" "replica" {
  count = var.enable_cross_region_replication ? 1 : 0

  provider = aws.secondary
  bucket   = aws_s3_bucket.replica[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  name = "${var.project_name}-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for replication
resource "aws_iam_policy" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  name = "${var.project_name}-${var.environment}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.replica[0].arn}/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "main" {
  count = var.enable_cross_region_replication ? 1 : 0

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "replicate-everything"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica[0].arn
      storage_class = var.s3_replication_storage_class

      dynamic "encryption_configuration" {
        for_each = var.s3_secondary_kms_key_id != null ? [1] : []
        content {
          replica_kms_key_id = var.s3_secondary_kms_key_id
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# Notification configuration for monitoring
resource "aws_s3_bucket_notification" "main" {
  count = var.s3_enable_notifications ? 1 : 0

  bucket = aws_s3_bucket.main.id

  dynamic "topic" {
    for_each = var.s3_sns_topic_arn != null ? [var.s3_sns_topic_arn] : []
    content {
      topic_arn = topic.value
      events    = var.s3_notification_events
    }
  }
}