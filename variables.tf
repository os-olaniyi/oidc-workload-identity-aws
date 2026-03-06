variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "cas" {
  description = "Map of CA instances. Key = unique CA identifier."
  type = map(object({
    ca_common_name             = string
    organization               = string
    ca_key_algorithm           = optional(string, "RSA_2048")
    ca_signing_algorithm       = optional(string, "SHA256WITHRSA")
    ca_validity_years          = optional(number, 10)
    ca_permanent_deletion_days = optional(number, 7)
    session_duration_seconds   = optional(number, 3600)
  }))
}

variable "s3_buckets" {
  description = "Map of S3 bucket instances. Key = unique bucket identifier. ca_key must match a key in var.cas."
  type = map(object({
    bucket_name          = string
    ca_key               = string
    force_destroy        = optional(bool, false)
    encryption_algorithm = optional(string, "aws:kms")
    kms_key_id           = optional(string, null)
  }))
}
