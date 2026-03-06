variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "nonaws-s3-access"
}

variable "ca_common_name" {
  description = "Common name for the Private CA certificate"
  type        = string
  default     = "nonaws-root-ca"
}

variable "organization" {
  description = "Organization name embedded in the CA certificate subject"
  type        = string
  default     = "MyOrg"
}

variable "s3_bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "Bucket name must be 3–63 characters, lowercase alphanumeric, hyphens, or dots."
  }
}

variable "ca_key_algorithm" {
  description = "Key algorithm for the Private CA (e.g. RSA_2048, RSA_4096, EC_prime256v1)"
  type        = string
  default     = "RSA_2048"
}

variable "ca_signing_algorithm" {
  description = "Signing algorithm for the Private CA (e.g. SHA256WITHRSA, SHA512WITHRSA)"
  type        = string
  default     = "SHA256WITHRSA"
}

variable "ca_validity_years" {
  description = "Validity period for the root CA certificate in years"
  type        = number
  default     = 10

  validation {
    condition     = var.ca_validity_years >= 1 && var.ca_validity_years <= 20
    error_message = "Must be between 1 and 20 years."
  }
}

variable "session_duration_seconds" {
  description = "Duration in seconds for IAM Roles Anywhere sessions (900–3600)"
  type        = number
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 3600
    error_message = "Must be between 900 and 3600 seconds."
  }
}

variable "ca_permanent_deletion_days" {
  description = "Number of days before the Private CA is permanently deleted (7–30)"
  type        = number
  default     = 7

  validation {
    condition     = var.ca_permanent_deletion_days >= 7 && var.ca_permanent_deletion_days <= 30
    error_message = "Must be between 7 and 30 days."
  }
}

variable "s3_force_destroy" {
  description = "Allow Terraform to delete the S3 bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "s3_encryption_algorithm" {
  description = "Server-side encryption algorithm for the S3 bucket (AES256 or aws:kms)"
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.s3_encryption_algorithm)
    error_message = "Must be AES256 or aws:kms."
  }
}

variable "s3_kms_key_id" {
  description = "KMS key ID for S3 encryption (only used when s3_encryption_algorithm is aws:kms). Null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "nonaws-s3-access"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
