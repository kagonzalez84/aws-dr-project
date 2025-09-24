# AWS Disaster Recovery Project

This project demonstrates disaster recovery concepts using Terraform and Terragrunt with AWS services including DynamoDB, S3, and AWS Backup.

## Architecture Overview

The project implements a comprehensive disaster recovery strategy using:

- **DynamoDB**: Tables with Point-in-Time Recovery (PITR) and cross-region replication
- **S3**: Buckets with versioning, cross-region replication, and lifecycle policies
- **AWS Backup**: Centralized backup management with cross-region copy actions
- **Multi-Region Setup**: Primary (us-east-1) and DR (us-west-2) regions

## Project Structure

```
├── modules/                    # Reusable Terraform modules
│   └── infrastructure/        # Consolidated module with all AWS resources
│       ├── main.tf            # Main Terraform configuration and providers
│       ├── s3.tf              # S3 resources with versioning and replication
│       ├── dynamodb.tf        # DynamoDB tables with DR features
│       ├── backup.tf          # AWS Backup configuration and policies
│       ├── variables.tf       # Input variables for all services
│       └── outputs.tf         # Output values from all resources
├── environments/              # Environment-specific configurations
│   ├── common.hcl             # Shared configuration across environments
│   ├── dev/                   # Development environment
│   │   └── terragrunt.hcl     # Dev-specific configuration
│   └── prod/                  # Production environment
│       └── terragrunt.hcl     # Prod-specific configuration
├── scripts/                   # Utility scripts for testing DR
├── docs/                      # DR documentation and runbooks
└── root.hcl                   # Root Terragrunt configuration
```

## Getting Started

### Prerequisites

- Terraform >= 1.5.0
- Terragrunt >= 0.50.0
- AWS CLI configured with appropriate permissions
- Two AWS regions configured (primary and secondary)

### Setup

1. Clone this repository
2. Configure your AWS credentials
3. Review and update the configuration in `terragrunt.hcl`
4. Navigate to the desired environment directory
5. Run `terragrunt run-all plan` to preview changes
6. Run `terragrunt run-all apply` to deploy infrastructure

### Environment Variables

```bash
export AWS_REGION="us-east-1"
export AWS_SECONDARY_REGION="us-west-2"
export TF_VAR_environment="dev"  # or "prod"
```

## Disaster Recovery Features

### DynamoDB
- Point-in-Time Recovery enabled
- Cross-region global tables
- Automated backups with AWS Backup
- Continuous backup capabilities

### S3
- Versioning enabled
- Cross-region replication
- Lifecycle policies for cost optimization
- MFA delete protection

### AWS Backup
- Daily backup schedules
- Cross-region backup copies
- Automated recovery testing
- Compliance reporting

## Testing DR Scenarios

See the `scripts/` directory for utilities to:
- Seed test data
- Simulate failures
- Test recovery procedures
- Validate DR capabilities

## Documentation

For detailed information, see the following documents:

- [`docs/DR_PLAN.md`](docs/DR_PLAN.md) - Comprehensive disaster recovery plan with RTO/RPO objectives, procedures, and responsibilities
- [`docs/RECOVERY_SCENARIOS.md`](docs/RECOVERY_SCENARIOS.md) - Detailed recovery procedures for various disaster scenarios with step-by-step commands
- [`docs/TESTING_GUIDE.md`](docs/TESTING_GUIDE.md) - Comprehensive testing procedures, automated scripts, and DR drill protocols

## Cost Optimization

The project includes cost optimization features:
- S3 lifecycle policies to transition to cheaper storage classes
- DynamoDB on-demand billing for development
- Backup retention policies to manage storage costs
- Cross-region replication only for critical data

## Security

- KMS encryption for all data at rest
- IAM roles with least privilege
- MFA delete protection where applicable
- VPC endpoints for secure communication

## Monitoring and Alerting

- CloudWatch metrics for backup success/failure
- SNS notifications for DR events
- Backup compliance monitoring
- Cross-region replication monitoring

## Support

For questions or issues, please refer to the documentation in the `docs/` directory or create an issue in this repository.