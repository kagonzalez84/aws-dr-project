# Development Environment Configuration

include "root" {
  path = find_in_parent_folders()
}

# Environment-specific inputs
inputs = {
  environment                     = "dev"
  aws_region                     = "us-east-1"
  aws_secondary_region           = "us-west-2"
  enable_cross_region_replication = true
  backup_retention_days          = 7  # Shorter retention for dev
  dr_backup_retention_days       = 14 # Shorter DR retention for dev
}