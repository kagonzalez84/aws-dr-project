# Recovery Scenarios and Procedures

## Overview

This document provides detailed recovery scenarios and step-by-step procedures for various disaster situations that may affect the AWS DR Project infrastructure. Each scenario includes specific commands, validation steps, and rollback procedures.

## Table of Contents

1. [Scenario Classification](#scenario-classification)
2. [DynamoDB Recovery Scenarios](#dynamodb-recovery-scenarios)
3. [S3 Recovery Scenarios](#s3-recovery-scenarios)
4. [Cross-Service Recovery Scenarios](#cross-service-recovery-scenarios)
5. [Regional Failover Scenarios](#regional-failover-scenarios)
6. [Backup Recovery Scenarios](#backup-recovery-scenarios)
7. [Validation and Testing](#validation-and-testing)

## Scenario Classification

### Severity Levels

| Level | Description | Response Time | Stakeholder Notification |
|-------|-------------|---------------|-------------------------|
| **Critical** | Service completely unavailable | < 15 minutes | Immediate |
| **High** | Significant performance degradation | < 30 minutes | Within 1 hour |
| **Medium** | Minor service disruption | < 1 hour | Within 4 hours |
| **Low** | Planned maintenance or non-critical issues | < 4 hours | Next business day |

### Impact Categories

- **Data Loss**: Potential or actual data corruption/loss
- **Service Outage**: Complete service unavailability
- **Performance**: Degraded service performance
- **Security**: Security breach or vulnerability
- **Compliance**: Regulatory or compliance issues

## DynamoDB Recovery Scenarios

### Scenario 1: Accidental Data Deletion

**Trigger**: Application bug or human error deletes critical data

**Impact**: Data Loss - Critical

**Detection Time**: 5-30 minutes

#### Recovery Procedure

```bash
#!/bin/bash
# DynamoDB Point-in-Time Recovery Script

# Configuration
REGION="us-east-1"
SOURCE_TABLE="aws-dr-project-prod-users"
RECOVERY_TABLE="aws-dr-project-prod-users-recovery"
INCIDENT_TIME="2024-01-15T14:30:00Z"

# Step 1: Stop application writes
echo "Step 1: Stopping application writes..."
# Update application configuration to read-only mode
# Scale down write capacity or disable write operations

# Step 2: Identify last known good state
echo "Step 2: Identifying recovery point..."
# Review CloudWatch logs and application logs
# Determine exact time before data corruption

# Step 3: Restore table to point-in-time
echo "Step 3: Starting point-in-time recovery..."
aws dynamodb restore-table-to-point-in-time \
    --region $REGION \
    --source-table-name $SOURCE_TABLE \
    --target-table-name $RECOVERY_TABLE \
    --restore-date-time $INCIDENT_TIME \
    --billing-mode-override PAY_PER_REQUEST

# Step 4: Monitor restoration progress
echo "Step 4: Monitoring restoration..."
while true; do
    STATUS=$(aws dynamodb describe-table \
        --region $REGION \
        --table-name $RECOVERY_TABLE \
        --query 'Table.TableStatus' \
        --output text)
    
    echo "Restoration status: $STATUS"
    
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ Table restoration completed successfully"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ Table restoration failed"
        exit 1
    fi
    
    sleep 30
done

# Step 5: Validate recovered data
echo "Step 5: Validating recovered data..."
ORIGINAL_COUNT=$(aws dynamodb scan \
    --region $REGION \
    --table-name $SOURCE_TABLE \
    --select "COUNT" \
    --query 'Count' \
    --output text)

RECOVERED_COUNT=$(aws dynamodb scan \
    --region $REGION \
    --table-name $RECOVERY_TABLE \
    --select "COUNT" \
    --query 'Count' \
    --output text)

echo "Original table count: $ORIGINAL_COUNT"
echo "Recovered table count: $RECOVERED_COUNT"

# Step 6: Sample data validation
echo "Step 6: Performing sample data validation..."
# Get sample items from both tables for comparison
aws dynamodb scan \
    --region $REGION \
    --table-name $RECOVERY_TABLE \
    --limit 10 \
    --query 'Items[*]' > /tmp/recovered_sample.json

# Step 7: Switch application to recovered table
echo "Step 7: Switching application traffic..."
# Option A: Rename tables (requires downtime)
# aws dynamodb delete-table --region $REGION --table-name $SOURCE_TABLE
# Wait for deletion, then rename recovery table

# Option B: Update application configuration (preferred)
# Update application to point to new table name
# Update IAM policies if needed

echo "✅ Recovery procedure completed"
echo "📋 Post-recovery tasks:"
echo "   - Update application configuration"
echo "   - Perform full data validation"
echo "   - Monitor application performance"
echo "   - Document incident and lessons learned"
```

#### Validation Steps

```bash
# Data integrity validation
./scripts/test-dr.sh validate-dynamodb

# Performance validation
aws dynamodb describe-table \
    --region us-east-1 \
    --table-name aws-dr-project-prod-users-recovery \
    --query 'Table.[TableName,TableStatus,ItemCount,TableSizeBytes]'

# Application functionality test
# Run application test suite
# Verify user authentication and data operations
```

#### Rollback Procedure

```bash
# If recovery fails or causes issues
echo "Initiating rollback..."

# Step 1: Revert application configuration
# Point application back to original table

# Step 2: Clean up recovery table
aws dynamodb delete-table \
    --region us-east-1 \
    --table-name aws-dr-project-prod-users-recovery

# Step 3: Restore from backup if PITR is insufficient
# Use AWS Backup recovery points
```

### Scenario 2: DynamoDB Regional Outage

**Trigger**: Primary region (us-east-1) DynamoDB service unavailable

**Impact**: Service Outage - Critical

**Detection Time**: 2-5 minutes

#### Recovery Procedure

```bash
#!/bin/bash
# DynamoDB Regional Failover Script

# Configuration
PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"
TABLE_NAME="aws-dr-project-prod-users"

echo "🚨 DynamoDB Regional Failover Initiated"

# Step 1: Verify primary region status
echo "Step 1: Verifying primary region status..."
PRIMARY_STATUS=$(aws dynamodb describe-table \
    --region $PRIMARY_REGION \
    --table-name $TABLE_NAME \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null || echo "UNAVAILABLE")

echo "Primary region status: $PRIMARY_STATUS"

# Step 2: Check DR region availability
echo "Step 2: Checking DR region availability..."
DR_STATUS=$(aws dynamodb describe-table \
    --region $DR_REGION \
    --table-name $TABLE_NAME \
    --query 'Table.TableStatus' \
    --output text)

echo "DR region status: $DR_STATUS"

if [ "$DR_STATUS" != "ACTIVE" ]; then
    echo "❌ DR region table not available"
    exit 1
fi

# Step 3: Update application configuration
echo "Step 3: Updating application configuration..."
# Update environment variables or configuration files
export AWS_DEFAULT_REGION=$DR_REGION
export DYNAMODB_ENDPOINT="https://dynamodb.$DR_REGION.amazonaws.com"

# Step 4: Update DNS/Load Balancer
echo "Step 4: Updating traffic routing..."
# Update Route 53 records or load balancer configuration
# Point application traffic to DR region

# Step 5: Validate failover
echo "Step 5: Validating failover..."
./scripts/test-dr.sh validate-failover

# Step 6: Monitor replication lag
echo "Step 6: Monitoring replication status..."
aws dynamodb describe-table \
    --region $DR_REGION \
    --table-name $TABLE_NAME \
    --query 'Table.Replicas[0].ReplicaStatus'

echo "✅ Failover completed to region: $DR_REGION"
```

## S3 Recovery Scenarios

### Scenario 3: Accidental Object Deletion

**Trigger**: Bulk deletion of objects in S3 bucket

**Impact**: Data Loss - High

**Detection Time**: 5-60 minutes

#### Recovery Procedure

```bash
#!/bin/bash
# S3 Object Recovery Script

# Configuration
BUCKET_NAME="aws-dr-project-prod-bucket"
REGION="us-east-1"
INCIDENT_TIME="2024-01-15T15:00:00Z"

echo "🔄 S3 Object Recovery Initiated"

# Step 1: List deleted objects (if versioning enabled)
echo "Step 1: Identifying deleted objects..."
aws s3api list-object-versions \
    --bucket $BUCKET_NAME \
    --query 'DeleteMarkers[?LastModified>`'$INCIDENT_TIME'`].[Key,VersionId]' \
    --output table > /tmp/deleted_objects.txt

cat /tmp/deleted_objects.txt

# Step 2: Restore objects from versions
echo "Step 2: Restoring objects from versions..."
while IFS=$'\t' read -r key version_id; do
    if [ ! -z "$key" ] && [ "$key" != "Key" ]; then
        echo "Restoring: $key"
        aws s3api delete-object \
            --bucket $BUCKET_NAME \
            --key "$key" \
            --version-id "$version_id"
    fi
done < /tmp/deleted_objects.txt

# Step 3: Restore from cross-region replica if needed
echo "Step 3: Checking cross-region replica..."
REPLICA_BUCKET="aws-dr-project-prod-bucket-replica"
REPLICA_REGION="us-west-2"

# List objects in replica bucket
aws s3 ls s3://$REPLICA_BUCKET --region $REPLICA_REGION --recursive > /tmp/replica_objects.txt

# Step 4: Sync missing objects from replica
echo "Step 4: Syncing from replica bucket..."
aws s3 sync \
    s3://$REPLICA_BUCKET \
    s3://$BUCKET_NAME \
    --region $REPLICA_REGION \
    --source-region $REPLICA_REGION \
    --exclude "*" \
    --include "critical-data/*"

# Step 5: Validate recovery
echo "Step 5: Validating object recovery..."
./scripts/test-dr.sh validate-s3

echo "✅ S3 object recovery completed"
```

### Scenario 4: S3 Bucket Corruption

**Trigger**: Malware or application error corrupts objects

**Impact**: Data Loss - Critical

**Detection Time**: 15-120 minutes

#### Recovery Procedure

```bash
#!/bin/bash
# S3 Bucket Corruption Recovery

BUCKET_NAME="aws-dr-project-prod-bucket"
BACKUP_BUCKET="aws-dr-project-prod-bucket-backup"
REGION="us-east-1"

echo "🛡️ S3 Corruption Recovery Initiated"

# Step 1: Isolate corrupted bucket
echo "Step 1: Isolating corrupted bucket..."
# Update bucket policy to deny all access except recovery role
aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": ["arn:aws:s3:::'$BUCKET_NAME'/*", "arn:aws:s3:::'$BUCKET_NAME'"],
            "Condition": {
                "StringNotEquals": {
                    "aws:PrincipalArn": "arn:aws:iam::123456789012:role/S3RecoveryRole"
                }
            }
        }]
    }'

# Step 2: Assess corruption scope
echo "Step 2: Assessing corruption scope..."
# Create manifest of potentially corrupted objects
aws s3 ls s3://$BUCKET_NAME --recursive > /tmp/current_objects.txt
aws s3 ls s3://$BACKUP_BUCKET --recursive > /tmp/backup_objects.txt

# Compare sizes and timestamps
diff /tmp/current_objects.txt /tmp/backup_objects.txt > /tmp/corruption_diff.txt

# Step 3: Restore from clean backup
echo "Step 3: Restoring from clean backup..."
# Restore from AWS Backup or clean replica
aws s3 sync \
    s3://$BACKUP_BUCKET \
    s3://$BUCKET_NAME \
    --delete \
    --exact-timestamps

# Step 4: Verify object integrity
echo "Step 4: Verifying object integrity..."
# Calculate checksums for critical files
aws s3api head-object \
    --bucket $BUCKET_NAME \
    --key critical-file.txt \
    --query 'ETag' \
    --output text

# Step 5: Remove isolation policy
echo "Step 5: Restoring normal access..."
aws s3api delete-bucket-policy --bucket $BUCKET_NAME

echo "✅ S3 corruption recovery completed"
```

## Cross-Service Recovery Scenarios

### Scenario 5: Complete Application Stack Failure

**Trigger**: Regional outage affecting both DynamoDB and S3

**Impact**: Service Outage - Critical

**Detection Time**: 1-3 minutes

#### Recovery Procedure

```bash
#!/bin/bash
# Complete Stack Recovery Script

PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"

echo "🚨 Complete Stack Failover Initiated"

# Step 1: Activate DR region infrastructure
echo "Step 1: Activating DR region infrastructure..."
cd /path/to/terraform
terraform workspace select prod-dr
terraform apply -auto-approve -target=module.dynamodb
terraform apply -auto-approve -target=module.s3
terraform apply -auto-approve -target=module.backup

# Step 2: Update DNS and routing
echo "Step 2: Updating DNS and routing..."
# Update Route 53 health checks and routing
aws route53 change-resource-record-sets \
    --hosted-zone-id Z123456789 \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "api.example.com",
                "Type": "A",
                "SetIdentifier": "DR-Region",
                "Failover": {
                    "Type": "PRIMARY"
                },
                "TTL": 60,
                "ResourceRecords": [{"Value": "192.0.2.2"}]
            }
        }]
    }'

# Step 3: Start application in DR region
echo "Step 3: Starting application in DR region..."
# Deploy application to DR region if not already running
# Update configuration for DR region resources

# Step 4: Validate complete stack
echo "Step 4: Validating complete stack..."
./scripts/test-dr.sh all

echo "✅ Complete stack failover completed"
echo "🔄 Primary region restoration:"
echo "   - Monitor AWS Service Health Dashboard"
echo "   - Plan failback when primary region is restored"
echo "   - Sync any data changes from DR region"
```

## Backup Recovery Scenarios

### Scenario 6: Restore from AWS Backup

**Trigger**: Need to restore from centralized backup system

**Impact**: Data Recovery - Medium

**Detection Time**: Varies

#### Recovery Procedure

```bash
#!/bin/bash
# AWS Backup Recovery Script

BACKUP_VAULT="aws-dr-project-prod-backup-vault"
REGION="us-east-1"
RECOVERY_DATE="2024-01-15"

echo "💾 AWS Backup Recovery Initiated"

# Step 1: List available recovery points
echo "Step 1: Listing recovery points..."
aws backup list-recovery-points-by-backup-vault \
    --backup-vault-name $BACKUP_VAULT \
    --region $REGION \
    --by-creation-date-after $RECOVERY_DATE \
    --query 'RecoveryPoints[*].[RecoveryPointArn,CreationDate,ResourceType]' \
    --output table

# Step 2: Select recovery point
read -p "Enter Recovery Point ARN: " RECOVERY_POINT_ARN
read -p "Enter Resource Type (DynamoDB/S3): " RESOURCE_TYPE

# Step 3: Start restore job
echo "Step 3: Starting restore job..."
if [ "$RESOURCE_TYPE" = "DynamoDB" ]; then
    RESTORE_JOB=$(aws backup start-restore-job \
        --region $REGION \
        --recovery-point-arn "$RECOVERY_POINT_ARN" \
        --metadata '{
            "original-table-name": "aws-dr-project-prod-users",
            "target-table-name": "aws-dr-project-prod-users-restored"
        }' \
        --iam-role-arn "arn:aws:iam::123456789012:role/aws-dr-project-prod-backup-role" \
        --resource-type "DynamoDB" \
        --query 'RestoreJobId' \
        --output text)
else
    echo "S3 restore not yet implemented in script"
    exit 1
fi

echo "Restore Job ID: $RESTORE_JOB"

# Step 4: Monitor restore progress
echo "Step 4: Monitoring restore progress..."
while true; do
    STATUS=$(aws backup describe-restore-job \
        --region $REGION \
        --restore-job-id $RESTORE_JOB \
        --query 'Status' \
        --output text)
    
    echo "Restore status: $STATUS"
    
    if [ "$STATUS" = "COMPLETED" ]; then
        echo "✅ Restore completed successfully"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ Restore job failed"
        aws backup describe-restore-job \
            --region $REGION \
            --restore-job-id $RESTORE_JOB \
            --query 'StatusMessage'
        exit 1
    fi
    
    sleep 60
done

echo "✅ AWS Backup recovery completed"
```

## Validation and Testing

### Post-Recovery Validation Checklist

#### DynamoDB Validation

```bash
# 1. Table status and configuration
aws dynamodb describe-table \
    --region us-east-1 \
    --table-name aws-dr-project-prod-users \
    --query 'Table.[TableStatus,ItemCount,TableSizeBytes]'

# 2. Global table replication
aws dynamodb describe-table \
    --region us-west-2 \
    --table-name aws-dr-project-prod-users \
    --query 'Table.Replicas[*].[RegionName,ReplicaStatus]'

# 3. Point-in-time recovery status
aws dynamodb describe-continuous-backups \
    --region us-east-1 \
    --table-name aws-dr-project-prod-users

# 4. Sample data validation
./scripts/test-dr.sh validate-data
```

#### S3 Validation

```bash
# 1. Bucket status and configuration
aws s3api get-bucket-versioning \
    --bucket aws-dr-project-prod-bucket

# 2. Cross-region replication status
aws s3api get-bucket-replication \
    --bucket aws-dr-project-prod-bucket

# 3. Object count and size validation
aws s3 ls s3://aws-dr-project-prod-bucket --recursive --summarize

# 4. Critical object validation
./scripts/test-dr.sh validate-s3-objects
```

#### Application Validation

```bash
# 1. Health check endpoints
curl -f https://api.example.com/health

# 2. Authentication functionality
./scripts/test-dr.sh test-auth

# 3. Data operations
./scripts/test-dr.sh test-crud

# 4. Performance benchmarks
./scripts/test-dr.sh performance-test
```

### Recovery Time Measurement

```bash
#!/bin/bash
# Recovery Time Tracking

START_TIME=$(date +%s)

# Perform recovery procedures...
# ...

END_TIME=$(date +%s)
RECOVERY_TIME=$((END_TIME - START_TIME))

echo "Recovery completed in $RECOVERY_TIME seconds"
echo "RTO Target: 14400 seconds (4 hours)"

if [ $RECOVERY_TIME -lt 14400 ]; then
    echo "✅ RTO target met"
else
    echo "❌ RTO target exceeded - review and optimize procedures"
fi
```

## Lessons Learned Template

After each recovery event, document:

1. **Incident Summary**
   - Timeline of events
   - Root cause analysis
   - Impact assessment

2. **Recovery Effectiveness**
   - RTO/RPO achieved vs. targets
   - Procedure accuracy
   - Tool effectiveness

3. **Improvements Identified**
   - Process gaps
   - Tool limitations
   - Training needs

4. **Action Items**
   - Procedure updates
   - Tool improvements
   - Team training

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-15  
**Next Review**: 2024-04-15  
**Owner**: DR Team