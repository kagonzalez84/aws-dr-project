# AWS Backup Module for Disaster Recovery

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# KMS key for backup encryption
resource "aws_kms_key" "backup" {
  description             = "${var.project_name}-${var.environment}-backup-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Backup Service"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-backup-key"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.project_name}-${var.environment}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

# KMS key for DR region
resource "aws_kms_key" "backup_dr" {
  count = var.enable_cross_region_backup ? 1 : 0

  provider                = aws.secondary
  description             = "${var.project_name}-${var.environment}-backup-dr-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Backup Service"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-backup-dr-key"
      Environment = var.environment
      Purpose     = "disaster-recovery"
    }
  )
}

resource "aws_kms_alias" "backup_dr" {
  count = var.enable_cross_region_backup ? 1 : 0

  provider      = aws.secondary
  name          = "alias/${var.project_name}-${var.environment}-backup-dr"
  target_key_id = aws_kms_key.backup_dr[0].key_id
}

# Primary backup vault
resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-backup-vault"
      Environment = var.environment
    }
  )
}

# DR backup vault in secondary region
resource "aws_backup_vault" "dr" {
  count = var.enable_cross_region_backup ? 1 : 0

  provider    = aws.secondary
  name        = "${var.project_name}-${var.environment}-backup-vault-dr"
  kms_key_arn = aws_kms_key.backup_dr[0].arn

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-backup-vault-dr"
      Environment = var.environment
      Purpose     = "disaster-recovery"
    }
  )
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed backup policy
resource "aws_iam_role_policy_attachment" "backup_service_role" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Attach restore policy
resource "aws_iam_role_policy_attachment" "backup_restore_role" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup plan
resource "aws_backup_plan" "main" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  # Daily backup rule
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.backup_schedule

    start_window      = var.backup_start_window
    completion_window = var.backup_completion_window

    recovery_point_tags = merge(
      var.tags,
      {
        BackupType = "daily"
      }
    )

    lifecycle {
      cold_storage_after = var.backup_cold_storage_after
      delete_after       = var.backup_retention_days
    }

    # Cross-region copy action for disaster recovery
    dynamic "copy_action" {
      for_each = var.enable_cross_region_backup ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.dr[0].arn
        lifecycle {
          cold_storage_after = var.dr_backup_cold_storage_after
          delete_after       = var.dr_backup_retention_days
        }
      }
    }
  }

  # DynamoDB continuous backup rule
  dynamic "rule" {
    for_each = var.enable_dynamodb_continuous_backup ? [1] : []
    content {
      rule_name                = "dynamodb_continuous_backup"
      target_vault_name        = aws_backup_vault.main.name
      schedule                 = var.dynamodb_backup_schedule
      enable_continuous_backup = true

      start_window      = 30   # DynamoDB backups are fast
      completion_window = 120  # Usually complete quickly

      recovery_point_tags = merge(
        var.tags,
        {
          BackupType = "continuous"
          Service    = "dynamodb"
        }
      )

      lifecycle {
        delete_after = var.dynamodb_backup_retention_days
      }

      dynamic "copy_action" {
        for_each = var.enable_cross_region_backup ? [1] : []
        content {
          destination_vault_arn = aws_backup_vault.dr[0].arn
          lifecycle {
            delete_after = var.dr_backup_retention_days
          }
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-backup-plan"
      Environment = var.environment
    }
  )
}

# Backup selection for DynamoDB tables
resource "aws_backup_selection" "dynamodb" {
  count = var.enable_dynamodb_backup ? 1 : 0

  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-${var.environment}-dynamodb-backup-selection"
  plan_id      = aws_backup_plan.main.id

  resources = var.dynamodb_table_arns

  dynamic "condition" {
    for_each = length(var.backup_tag_conditions) > 0 ? [1] : []
    content {
      dynamic "string_equals" {
        for_each = var.backup_tag_conditions
        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }
    }
  }
}

# Backup selection for S3 buckets
resource "aws_backup_selection" "s3" {
  count = var.enable_s3_backup ? 1 : 0

  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-${var.environment}-s3-backup-selection"
  plan_id      = aws_backup_plan.main.id

  resources = var.s3_bucket_arns

  dynamic "condition" {
    for_each = length(var.backup_tag_conditions) > 0 ? [1] : []
    content {
      dynamic "string_equals" {
        for_each = var.backup_tag_conditions
        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }
    }
  }
}

# SNS topic for backup notifications
resource "aws_sns_topic" "backup_notifications" {
  count = var.enable_backup_notifications ? 1 : 0

  name = "${var.project_name}-${var.environment}-backup-notifications"

  tags = var.tags
}

# Backup vault notifications
resource "aws_backup_vault_notifications" "main" {
  count = var.enable_backup_notifications ? 1 : 0

  backup_vault_name   = aws_backup_vault.main.name
  sns_topic_arn       = aws_sns_topic.backup_notifications[0].arn
  backup_vault_events = var.backup_notification_events
}

# CloudWatch alarm for failed backups
resource "aws_cloudwatch_metric_alarm" "backup_failure" {
  count = var.enable_backup_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-backup-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup job failures"
  alarm_actions       = var.enable_backup_notifications ? [aws_sns_topic.backup_notifications[0].arn] : []

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  tags = var.tags
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}