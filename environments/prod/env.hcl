# Production Environment Configuration

include "root" {
  path = find_in_parent_folders()
}

# Environment-specific inputs
inputs = {
  environment                     = "prod"
  aws_region                     = "us-east-1"
  aws_secondary_region           = "us-west-2"
  enable_cross_region_replication = true
  backup_retention_days          = 30 # Standard retention for prod
  dr_backup_retention_days       = 90 # Extended DR retention for prod
}