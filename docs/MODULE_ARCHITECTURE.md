# Module Architecture Guide

This document describes the consolidated infrastructure module architecture and organization in the AWS DR project.

## Module Structure Overview

The project has been refactored from three separate modules (`backup`, `dynamodb`, `s3`) into a single consolidated `infrastructure` module for better maintainability and cleaner architecture.

```
modules/infrastructure/
├── main.tf         # Terraform configuration and data sources (21 lines)
├── s3.tf           # S3 resources and configuration (275 lines)
├── dynamodb.tf     # DynamoDB resources and configuration (206 lines)
├── backup.tf       # AWS Backup resources and configuration (344 lines)
├── variables.tf    # Unified variable definitions (381 lines)
└── outputs.tf      # Consolidated outputs (119 lines)
```

## File Organization

### main.tf
Contains the core Terraform configuration:
- Terraform version requirements
- Provider configurations (AWS, random)
- AWS account data source

### s3.tf
Contains all S3-related resources:
- Primary and replica S3 buckets
- Bucket versioning and encryption
- Lifecycle configurations
- Cross-region replication setup
- IAM roles and policies for replication
- Bucket notifications

### dynamodb.tf
Contains all DynamoDB-related resources:
- Primary and replica DynamoDB tables
- Global table configuration
- Auto-scaling policies
- Point-in-time recovery settings
- Encryption configuration

### backup.tf
Contains all backup-related resources:
- KMS keys for backup encryption
- Backup vaults (primary and DR regions)
- Backup plans and schedules
- Backup selections for resources
- IAM roles and policies
- SNS notifications and CloudWatch alarms

### variables.tf
Unified variable definitions organized by service:
- Project and environment variables
- S3-specific variables
- DynamoDB-specific variables
- Backup-specific variables
- Cross-region replication settings

### outputs.tf
Consolidated outputs from all services:
- S3 bucket information
- DynamoDB table details
- Backup configuration details
- Infrastructure summary

## Benefits of Consolidation

### 1. **Simplified Architecture**
- Single module to manage instead of three separate modules
- Reduced complexity in environment configurations
- Easier dependency management

### 2. **Better Organization**
- Service-specific files for easier navigation
- Clear separation of concerns
- Logical grouping of related resources

### 3. **Improved Maintainability**
- Single point of configuration for all infrastructure
- Easier to update variables across all services
- Unified version management

### 4. **Enhanced Collaboration**
- Team members can work on different service files simultaneously
- Clear ownership boundaries for different services
- Reduced merge conflicts

### 5. **Consistent Resource Management**
- Unified tagging strategy across all resources
- Consistent naming conventions
- Shared locals and data sources

## Resource Distribution

| Service | Resources | File Size | Key Features |
|---------|-----------|-----------|--------------|
| S3 | 12 resources | 275 lines | Buckets, replication, lifecycle |
| DynamoDB | 8 resources | 206 lines | Tables, scaling, global tables |
| Backup | 12 resources | 344 lines | Vaults, plans, monitoring |
| **Total** | **32 resources** | **825 lines** | **Complete DR solution** |

## Migration Path

The consolidation was achieved by:

1. **Extracting resources** from individual modules
2. **Organizing by service** into dedicated files
3. **Consolidating variables** into unified definitions
4. **Updating outputs** to reference direct resources
5. **Maintaining compatibility** with existing configurations

## Best Practices Implemented

### File Organization
- Each service has its own dedicated file
- Clear commenting and section headers
- Logical resource ordering within files

### Variable Management
- Service-prefixed variable names (e.g., `s3_bucket_name`)
- Consistent default values
- Comprehensive descriptions

### Resource Naming
- Consistent naming patterns across all resources
- Environment and project prefixes
- Clear purpose identification in tags

### Documentation
- Inline comments for complex configurations
- Clear section headers
- Comprehensive variable descriptions

## Validation and Testing

The consolidated module has been validated with:
- ✅ `terragrunt validate` passes in all environments
- ✅ `terragrunt plan` shows 32 resources correctly
- ✅ No breaking changes to existing configurations
- ✅ All disaster recovery features preserved

This architecture provides a solid foundation for the AWS DR project while maintaining flexibility for future enhancements and modifications.