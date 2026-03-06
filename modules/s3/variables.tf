variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase alphanumeric, hyphens, or dots."
  }
}

variable "role_name" {
  description = "Name of the IAM role to attach the S3 policy to"
  type        = string
}

variable "policy_name_prefix" {
  description = "Prefix for the IAM policy name (must be unique per bucket)"
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to delete the S3 bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for S3 encryption. Null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
