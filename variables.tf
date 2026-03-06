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
  # Override this — S3 bucket names are global across all AWS accounts
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
