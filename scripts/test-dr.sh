#!/bin/bash

# AWS DR Project - Disaster Recovery Testing Script
# This script helps test various disaster recovery scenarios

set -e

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
AWS_SECONDARY_REGION=${AWS_SECONDARY_REGION:-"us-west-2"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
PROJECT_NAME=${PROJECT_NAME:-"aws-dr-project"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if ! command -v terragrunt &> /dev/null; then
        missing_tools+=("terragrunt")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured properly"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Get resource information
get_resource_info() {
    log_info "Gathering resource information..."
    
    # Get DynamoDB table name
    DYNAMODB_TABLE_NAME=$(cd "environments/${ENVIRONMENT}/dynamodb" && terragrunt output -raw table_name 2>/dev/null || echo "")
    if [ -z "$DYNAMODB_TABLE_NAME" ]; then
        log_error "Could not retrieve DynamoDB table name. Make sure the infrastructure is deployed."
        exit 1
    fi
    
    # Get S3 bucket name
    S3_BUCKET_NAME=$(cd "environments/${ENVIRONMENT}/s3" && terragrunt output -raw bucket_id 2>/dev/null || echo "")
    if [ -z "$S3_BUCKET_NAME" ]; then
        log_error "Could not retrieve S3 bucket name. Make sure the infrastructure is deployed."
        exit 1
    fi
    
    # Get backup vault name
    BACKUP_VAULT_NAME=$(cd "environments/${ENVIRONMENT}/backup" && terragrunt output -raw backup_vault_name 2>/dev/null || echo "")
    if [ -z "$BACKUP_VAULT_NAME" ]; then
        log_warning "Could not retrieve backup vault name. Some tests may not work."
    fi
    
    log_success "Resource information gathered"
    echo "  DynamoDB Table: $DYNAMODB_TABLE_NAME"
    echo "  S3 Bucket: $S3_BUCKET_NAME"
    echo "  Backup Vault: $BACKUP_VAULT_NAME"
    echo ""
}

# Test 1: Verify Point-in-Time Recovery is enabled
test_dynamodb_pitr() {
    log_test "Testing DynamoDB Point-in-Time Recovery status"
    
    local pitr_status
    pitr_status=$(aws dynamodb describe-continuous-backups \
        --region "$AWS_REGION" \
        --table-name "$DYNAMODB_TABLE_NAME" \
        --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$pitr_status" = "ENABLED" ]; then
        log_success "Point-in-Time Recovery is ENABLED"
    else
        log_error "Point-in-Time Recovery is NOT ENABLED (Status: $pitr_status)"
        return 1
    fi
    
    # Check earliest restore time
    local earliest_restore_time
    earliest_restore_time=$(aws dynamodb describe-continuous-backups \
        --region "$AWS_REGION" \
        --table-name "$DYNAMODB_TABLE_NAME" \
        --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.EarliestRestorableDateTime' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$earliest_restore_time" != "UNKNOWN" ]; then
        log_info "Earliest restorable time: $earliest_restore_time"
    fi
}

# Test 2: Verify cross-region replication
test_cross_region_replication() {
    log_test "Testing cross-region replication"
    
    # Check if table exists in secondary region
    local replica_exists
    replica_exists=$(aws dynamodb describe-table \
        --region "$AWS_SECONDARY_REGION" \
        --table-name "$DYNAMODB_TABLE_NAME" \
        --query 'Table.TableName' \
        --output text 2>/dev/null || echo "NOTFOUND")
    
    if [ "$replica_exists" = "$DYNAMODB_TABLE_NAME" ]; then
        log_success "Replica table exists in secondary region"
        
        # Check replica status
        local replica_status
        replica_status=$(aws dynamodb describe-table \
            --region "$AWS_SECONDARY_REGION" \
            --table-name "$DYNAMODB_TABLE_NAME" \
            --query 'Table.TableStatus' \
            --output text 2>/dev/null || echo "UNKNOWN")
        
        log_info "Replica table status: $replica_status"
        
        # Compare item counts
        local primary_count
        local replica_count
        
        primary_count=$(aws dynamodb scan \
            --region "$AWS_REGION" \
            --table-name "$DYNAMODB_TABLE_NAME" \
            --select "COUNT" \
            --output text \
            --query 'Count' 2>/dev/null || echo "0")
        
        replica_count=$(aws dynamodb scan \
            --region "$AWS_SECONDARY_REGION" \
            --table-name "$DYNAMODB_TABLE_NAME" \
            --select "COUNT" \
            --output text \
            --query 'Count' 2>/dev/null || echo "0")
        
        log_info "Primary region items: $primary_count"
        log_info "Secondary region items: $replica_count"
        
        if [ "$primary_count" -eq "$replica_count" ]; then
            log_success "Item counts match between regions"
        else
            log_warning "Item counts differ (replication may be in progress)"
        fi
    else
        log_error "Replica table not found in secondary region"
        return 1
    fi
}

# Test 3: Verify S3 cross-region replication
test_s3_replication() {
    log_test "Testing S3 cross-region replication"
    
    # Check replication configuration
    local replication_status
    replication_status=$(aws s3api get-bucket-replication \
        --region "$AWS_REGION" \
        --bucket "$S3_BUCKET_NAME" \
        --query 'ReplicationConfiguration.Rules[0].Status' \
        --output text 2>/dev/null || echo "NOTFOUND")
    
    if [ "$replication_status" = "Enabled" ]; then
        log_success "S3 replication is enabled"
        
        # Get destination bucket
        local dest_bucket
        dest_bucket=$(aws s3api get-bucket-replication \
            --region "$AWS_REGION" \
            --bucket "$S3_BUCKET_NAME" \
            --query 'ReplicationConfiguration.Rules[0].Destination.Bucket' \
            --output text 2>/dev/null | sed 's|arn:aws:s3:::|  |')
        
        if [ -n "$dest_bucket" ] && [ "$dest_bucket" != "None" ]; then
            log_info "Destination bucket: $dest_bucket"
            
            # Check if destination bucket exists
            if aws s3api head-bucket --bucket "$dest_bucket" --region "$AWS_SECONDARY_REGION" 2>/dev/null; then
                log_success "Destination bucket is accessible"
                
                # Compare object counts (basic check)
                local source_count
                local dest_count
                
                source_count=$(aws s3api list-objects-v2 \
                    --bucket "$S3_BUCKET_NAME" \
                    --region "$AWS_REGION" \
                    --query 'KeyCount' \
                    --output text 2>/dev/null || echo "0")
                
                dest_count=$(aws s3api list-objects-v2 \
                    --bucket "$dest_bucket" \
                    --region "$AWS_SECONDARY_REGION" \
                    --query 'KeyCount' \
                    --output text 2>/dev/null || echo "0")
                
                log_info "Source bucket objects: $source_count"
                log_info "Destination bucket objects: $dest_count"
            else
                log_error "Cannot access destination bucket"
                return 1
            fi
        fi
    else
        log_error "S3 replication is not enabled"
        return 1
    fi
}

# Test 4: Verify backup jobs
test_backup_jobs() {
    log_test "Testing AWS Backup jobs"
    
    if [ -z "$BACKUP_VAULT_NAME" ]; then
        log_warning "Backup vault name not available, skipping backup tests"
        return 0
    fi
    
    # Check recent backup jobs
    local recent_jobs
    recent_jobs=$(aws backup list-backup-jobs \
        --region "$AWS_REGION" \
        --by-backup-vault-name "$BACKUP_VAULT_NAME" \
        --max-results 10 \
        --query 'BackupJobs[?CreationDate >= `'$(date -u -d '7 days ago' +%Y-%m-%d)'`]' 2>/dev/null || echo "[]")
    
    local job_count
    job_count=$(echo "$recent_jobs" | jq length 2>/dev/null || echo "0")
    
    if [ "$job_count" -gt 0 ]; then
        log_success "Found $job_count recent backup jobs"
        
        # Show job statuses
        echo "$recent_jobs" | jq -r '.[] | "  Job ID: \(.BackupJobId) | Status: \(.State) | Created: \(.CreationDate)"' 2>/dev/null || echo "  Could not parse job details"
    else
        log_warning "No recent backup jobs found"
    fi
    
    # Check backup vault
    local vault_recovery_points
    vault_recovery_points=$(aws backup list-recovery-points-by-backup-vault \
        --region "$AWS_REGION" \
        --backup-vault-name "$BACKUP_VAULT_NAME" \
        --max-results 5 \
        --query 'RecoveryPoints | length(@)' \
        --output text 2>/dev/null || echo "0")
    
    log_info "Recovery points in vault: $vault_recovery_points"
}

# Test 5: Simulate data corruption and recovery
test_point_in_time_recovery_simulation() {
    log_test "Simulating point-in-time recovery scenario (DRY RUN)"
    
    # Note: This is a dry run simulation that doesn't actually perform recovery
    log_info "This test simulates a point-in-time recovery without actually performing it"
    
    # Get current timestamp
    local current_time
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get a timestamp from 1 hour ago (recovery point)
    local recovery_time
    recovery_time=$(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ")
    
    log_info "Current time: $current_time"
    log_info "Simulated recovery point: $recovery_time"
    
    # Check if we could restore to this point
    local earliest_restore_time
    earliest_restore_time=$(aws dynamodb describe-continuous-backups \
        --region "$AWS_REGION" \
        --table-name "$DYNAMODB_TABLE_NAME" \
        --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.EarliestRestorableDateTime' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$earliest_restore_time" != "UNKNOWN" ]; then
        log_info "Earliest restorable time: $earliest_restore_time"
        
        # Convert to epoch for comparison
        local recovery_epoch
        local earliest_epoch
        
        recovery_epoch=$(date -d "$recovery_time" +%s 2>/dev/null || echo "0")
        earliest_epoch=$(date -d "${earliest_restore_time%.*}Z" +%s 2>/dev/null || echo "0")
        
        if [ "$recovery_epoch" -ge "$earliest_epoch" ]; then
            log_success "Recovery to $recovery_time would be possible"
            
            # Show what the restore command would look like
            echo ""
            log_info "Recovery command (DO NOT RUN in production):"
            echo "aws dynamodb restore-table-to-point-in-time \\"
            echo "  --region $AWS_REGION \\"
            echo "  --source-table-name $DYNAMODB_TABLE_NAME \\"
            echo "  --target-table-name ${DYNAMODB_TABLE_NAME}-restored-$(date +%Y%m%d-%H%M%S) \\"
            echo "  --restore-date-time $recovery_time"
            echo ""
        else
            log_warning "Recovery to $recovery_time would NOT be possible (too old)"
        fi
    fi
}

# Test 6: Verify versioning and lifecycle policies
test_s3_versioning_lifecycle() {
    log_test "Testing S3 versioning and lifecycle policies"
    
    # Check versioning status
    local versioning_status
    versioning_status=$(aws s3api get-bucket-versioning \
        --region "$AWS_REGION" \
        --bucket "$S3_BUCKET_NAME" \
        --query 'Status' \
        --output text 2>/dev/null || echo "NOTFOUND")
    
    if [ "$versioning_status" = "Enabled" ]; then
        log_success "S3 versioning is enabled"
    else
        log_error "S3 versioning is not enabled (Status: $versioning_status)"
        return 1
    fi
    
    # Check lifecycle configuration
    local lifecycle_rules
    lifecycle_rules=$(aws s3api get-bucket-lifecycle-configuration \
        --region "$AWS_REGION" \
        --bucket "$S3_BUCKET_NAME" \
        --query 'Rules | length(@)' \
        --output text 2>/dev/null || echo "0")
    
    if [ "$lifecycle_rules" -gt 0 ]; then
        log_success "Lifecycle policies are configured ($lifecycle_rules rules)"
        
        # Show rule details
        aws s3api get-bucket-lifecycle-configuration \
            --region "$AWS_REGION" \
            --bucket "$S3_BUCKET_NAME" \
            --query 'Rules[].{ID:ID,Status:Status,Transitions:Transitions[0].StorageClass}' \
            --output table 2>/dev/null || log_warning "Could not display lifecycle rule details"
    else
        log_warning "No lifecycle policies configured"
    fi
}

# Run all tests
run_all_tests() {
    log_info "Running all disaster recovery tests..."
    echo ""
    
    local failed_tests=0
    local total_tests=6
    
    # Run each test
    test_dynamodb_pitr || ((failed_tests++))
    echo ""
    
    test_cross_region_replication || ((failed_tests++))
    echo ""
    
    test_s3_replication || ((failed_tests++))
    echo ""
    
    test_backup_jobs || ((failed_tests++))
    echo ""
    
    test_point_in_time_recovery_simulation || ((failed_tests++))
    echo ""
    
    test_s3_versioning_lifecycle || ((failed_tests++))
    echo ""
    
    # Summary
    local passed_tests=$((total_tests - failed_tests))
    
    echo "=== TEST SUMMARY ==="
    echo "Passed: $passed_tests/$total_tests"
    echo "Failed: $failed_tests/$total_tests"
    
    if [ $failed_tests -eq 0 ]; then
        log_success "All tests passed! ✅"
        return 0
    else
        log_warning "Some tests failed. Review the output above for details."
        return 1
    fi
}

# Main function
main() {
    echo "AWS Disaster Recovery Testing Script"
    echo "===================================="
    echo ""
    log_info "Environment: $ENVIRONMENT"
    log_info "Primary Region: $AWS_REGION"
    log_info "Secondary Region: $AWS_SECONDARY_REGION"
    echo ""
    
    check_prerequisites
    get_resource_info
    
    case "${1:-all}" in
        "pitr"|"point-in-time")
            test_dynamodb_pitr
            ;;
        "replication"|"cross-region")
            test_cross_region_replication
            test_s3_replication
            ;;
        "backup"|"backups")
            test_backup_jobs
            ;;
        "simulate"|"simulation")
            test_point_in_time_recovery_simulation
            ;;
        "s3"|"versioning")
            test_s3_versioning_lifecycle
            ;;
        "all"|*)
            run_all_tests
            ;;
    esac
}

# Show help
show_help() {
    echo "Usage: $0 [test-type]"
    echo ""
    echo "Test types:"
    echo "  all                Run all tests (default)"
    echo "  pitr              Test DynamoDB Point-in-Time Recovery"
    echo "  replication       Test cross-region replication"
    echo "  backup            Test backup jobs and recovery points"
    echo "  simulate          Simulate recovery scenarios"
    echo "  s3                Test S3 versioning and lifecycle"
    echo ""
    echo "Environment variables:"
    echo "  AWS_REGION             Primary AWS region (default: us-east-1)"
    echo "  AWS_SECONDARY_REGION   Secondary AWS region (default: us-west-2)"
    echo "  ENVIRONMENT            Environment name (default: dev)"
    echo "  PROJECT_NAME           Project name (default: aws-dr-project)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 pitr              # Test only Point-in-Time Recovery"
    echo "  $0 replication       # Test only cross-region replication"
}

# Handle arguments
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac