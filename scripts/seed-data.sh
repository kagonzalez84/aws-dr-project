#!/bin/bash

# AWS DR Project - Data Seeding Script
# This script seeds test data into DynamoDB tables and S3 buckets for disaster recovery testing

set -e

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
PROJECT_NAME=${PROJECT_NAME:-"aws-dr-project"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed or not in PATH"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured properly"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Get table name from Terraform output
get_dynamodb_table_name() {
    local table_name
    table_name=$(cd "environments/${ENVIRONMENT}/dynamodb" && terragrunt output -raw table_name 2>/dev/null || echo "")
    
    if [ -z "$table_name" ]; then
        log_error "Could not retrieve DynamoDB table name. Make sure the infrastructure is deployed."
        exit 1
    fi
    
    echo "$table_name"
}

# Get S3 bucket name from Terraform output
get_s3_bucket_name() {
    local bucket_name
    bucket_name=$(cd "environments/${ENVIRONMENT}/s3" && terragrunt output -raw bucket_id 2>/dev/null || echo "")
    
    if [ -z "$bucket_name" ]; then
        log_error "Could not retrieve S3 bucket name. Make sure the infrastructure is deployed."
        exit 1
    fi
    
    echo "$bucket_name"
}

# Seed DynamoDB table with test data
seed_dynamodb_data() {
    local table_name="$1"
    log_info "Seeding DynamoDB table: $table_name"
    
    # Generate test users
    local users=(
        '{"user_id": {"S": "user-001"}, "email": {"S": "alice@example.com"}, "created_at": {"S": "2024-01-01T10:00:00Z"}, "name": {"S": "Alice Johnson"}, "status": {"S": "active"}}'
        '{"user_id": {"S": "user-002"}, "email": {"S": "bob@example.com"}, "created_at": {"S": "2024-01-02T11:00:00Z"}, "name": {"S": "Bob Smith"}, "status": {"S": "active"}}'
        '{"user_id": {"S": "user-003"}, "email": {"S": "charlie@example.com"}, "created_at": {"S": "2024-01-03T12:00:00Z"}, "name": {"S": "Charlie Brown"}, "status": {"S": "inactive"}}'
        '{"user_id": {"S": "user-004"}, "email": {"S": "diana@example.com"}, "created_at": {"S": "2024-01-04T13:00:00Z"}, "name": {"S": "Diana Prince"}, "status": {"S": "active"}}'
        '{"user_id": {"S": "user-005"}, "email": {"S": "eve@example.com"}, "created_at": {"S": "2024-01-05T14:00:00Z"}, "name": {"S": "Eve Wilson"}, "status": {"S": "pending"}}'
    )
    
    local count=0
    for user_data in "${users[@]}"; do
        if aws dynamodb put-item \
            --region "$AWS_REGION" \
            --table-name "$table_name" \
            --item "$user_data" \
            --condition-expression "attribute_not_exists(user_id)" 2>/dev/null; then
            ((count++))
        else
            log_warning "User with ID $(echo "$user_data" | jq -r '.user_id.S') already exists, skipping"
        fi
    done
    
    log_success "Seeded $count new users to DynamoDB table"
    
    # Verify data
    local item_count
    item_count=$(aws dynamodb scan \
        --region "$AWS_REGION" \
        --table-name "$table_name" \
        --select "COUNT" \
        --output text \
        --query 'Count')
    
    log_info "Total items in table: $item_count"
}

# Seed S3 bucket with test data
seed_s3_data() {
    local bucket_name="$1"
    log_info "Seeding S3 bucket: $bucket_name"
    
    # Create temporary directory for test files
    local temp_dir=$(mktemp -d)
    
    # Create test files
    echo "This is a test document for disaster recovery testing" > "$temp_dir/test-document-1.txt"
    echo "Another test file with different content for DR validation" > "$temp_dir/test-document-2.txt"
    echo '{"test": "data", "purpose": "disaster recovery", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > "$temp_dir/test-data.json"
    
    # Create a larger file for testing
    dd if=/dev/zero of="$temp_dir/large-test-file.bin" bs=1M count=10 2>/dev/null
    
    # Upload files
    local uploaded=0
    for file in "$temp_dir"/*; do
        local filename=$(basename "$file")
        local key="test-data/$(date +%Y/%m/%d)/$filename"
        
        if aws s3 cp "$file" "s3://$bucket_name/$key" --region "$AWS_REGION" >/dev/null 2>&1; then
            ((uploaded++))
            log_info "Uploaded: $key"
        else
            log_warning "Failed to upload: $filename"
        fi
    done
    
    # Clean up
    rm -rf "$temp_dir"
    
    log_success "Uploaded $uploaded files to S3 bucket"
    
    # List objects to verify
    local object_count
    object_count=$(aws s3api list-objects-v2 \
        --bucket "$bucket_name" \
        --query 'KeyCount' \
        --output text 2>/dev/null || echo "0")
    
    log_info "Total objects in bucket: $object_count"
}

# Add more test data with batch operations
seed_batch_dynamodb_data() {
    local table_name="$1"
    log_info "Seeding batch data to DynamoDB table: $table_name"
    
    # Create batch request file
    local batch_file=$(mktemp)
    
    cat > "$batch_file" << EOF
{
    "$table_name": [
EOF
    
    # Generate 25 batch items (max batch size is 25)
    for i in $(seq 6 30); do
        local user_id=$(printf "user-%03d" $i)
        local email="${user_id}@example.com"
        local created_at=$(date -u -d "$i days ago" +"%Y-%m-%dT%H:%M:%SZ")
        local name="Test User $i"
        local status=(active inactive pending)
        local random_status=${status[$((RANDOM % 3))]}
        
        cat >> "$batch_file" << EOF
        {
            "PutRequest": {
                "Item": {
                    "user_id": {"S": "$user_id"},
                    "email": {"S": "$email"},
                    "created_at": {"S": "$created_at"},
                    "name": {"S": "$name"},
                    "status": {"S": "$random_status"}
                }
            }
        }$([ $i -lt 30 ] && echo "," || echo "")
EOF
    done
    
    cat >> "$batch_file" << EOF
    ]
}
EOF
    
    # Execute batch write
    if aws dynamodb batch-write-item \
        --region "$AWS_REGION" \
        --request-items "file://$batch_file" >/dev/null 2>&1; then
        log_success "Batch seeded 25 additional users"
    else
        log_warning "Batch write may have partially failed (this is normal if items already exist)"
    fi
    
    # Clean up
    rm -f "$batch_file"
}

# Main execution
main() {
    log_info "Starting data seeding for AWS DR Project"
    log_info "Environment: $ENVIRONMENT"
    log_info "Region: $AWS_REGION"
    log_info "Project: $PROJECT_NAME"
    
    check_prerequisites
    
    # Get resource names
    local dynamodb_table_name
    local s3_bucket_name
    
    dynamodb_table_name=$(get_dynamodb_table_name)
    s3_bucket_name=$(get_s3_bucket_name)
    
    log_info "DynamoDB Table: $dynamodb_table_name"
    log_info "S3 Bucket: $s3_bucket_name"
    
    # Seed data
    seed_dynamodb_data "$dynamodb_table_name"
    seed_batch_dynamodb_data "$dynamodb_table_name"
    seed_s3_data "$s3_bucket_name"
    
    log_success "Data seeding completed successfully!"
    
    # Summary
    echo ""
    log_info "=== SEEDING SUMMARY ==="
    
    local final_dynamodb_count
    final_dynamodb_count=$(aws dynamodb scan \
        --region "$AWS_REGION" \
        --table-name "$dynamodb_table_name" \
        --select "COUNT" \
        --output text \
        --query 'Count')
    
    local final_s3_count
    final_s3_count=$(aws s3api list-objects-v2 \
        --bucket "$s3_bucket_name" \
        --query 'KeyCount' \
        --output text 2>/dev/null || echo "0")
    
    echo "DynamoDB items: $final_dynamodb_count"
    echo "S3 objects: $final_s3_count"
    echo ""
    log_info "You can now test disaster recovery scenarios using the test-dr.sh script"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Environment variables:"
        echo "  AWS_REGION     AWS region (default: us-east-1)"
        echo "  ENVIRONMENT    Environment name (default: dev)"
        echo "  PROJECT_NAME   Project name (default: aws-dr-project)"
        echo ""
        echo "This script seeds test data into DynamoDB tables and S3 buckets"
        echo "for disaster recovery testing purposes."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac