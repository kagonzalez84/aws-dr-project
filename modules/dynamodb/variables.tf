# Variables for DynamoDB module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions"
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  description = "Describe a GSI for the table"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
    read_capacity   = optional(number)
    write_capacity  = optional(number)
  }))
  default = []
}

variable "read_capacity" {
  description = "The number of read units for this table"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "The number of write units for this table"
  type        = number
  default     = 5
}

variable "enable_point_in_time_recovery" {
  description = "Whether to enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enables deletion protection for table"
  type        = bool
  default     = true
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for disaster recovery"
  type        = bool
  default     = true
}

variable "enable_streams" {
  description = "Indicates whether DynamoDB Streams is to be enabled"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "When an item in the table is modified, StreamViewType determines what information is written to the table's stream"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition = contains([
      "KEYS_ONLY",
      "NEW_IMAGE",
      "OLD_IMAGE",
      "NEW_AND_OLD_IMAGES"
    ], var.stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

variable "kms_key_id" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption"
  type        = string
  default     = null
}

variable "secondary_kms_key_id" {
  description = "The ARN of the CMK for secondary region encryption"
  type        = string
  default     = null
}

variable "enable_autoscaling" {
  description = "Whether to enable autoscaling"
  type        = bool
  default     = false
}

variable "autoscaling_read_min_capacity" {
  description = "The minimum capacity for read autoscaling"
  type        = number
  default     = 5
}

variable "autoscaling_read_max_capacity" {
  description = "The maximum capacity for read autoscaling"
  type        = number
  default     = 40
}

variable "autoscaling_read_target_value" {
  description = "The target value for read capacity autoscaling"
  type        = number
  default     = 70.0
}

variable "autoscaling_write_min_capacity" {
  description = "The minimum capacity for write autoscaling"
  type        = number
  default     = 5
}

variable "autoscaling_write_max_capacity" {
  description = "The maximum capacity for write autoscaling"
  type        = number
  default     = 40
}

variable "autoscaling_write_target_value" {
  description = "The target value for write capacity autoscaling"
  type        = number
  default     = 70.0
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}