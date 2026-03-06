variable "name" {
  description = "Unique name for this CA instance (used as prefix for all resources)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Name must only contain alphanumeric characters and hyphens."
  }
}

variable "ca_common_name" {
  description = "Common name for the Private CA certificate"
  type        = string

  validation {
    condition     = length(var.ca_common_name) > 0 && length(var.ca_common_name) <= 64
    error_message = "Common name must be between 1 and 64 characters."
  }
}

variable "organization" {
  description = "Organization name in the CA certificate subject"
  type        = string

  validation {
    condition     = length(var.organization) > 0 && length(var.organization) <= 64
    error_message = "Organization must be between 1 and 64 characters."
  }
}

variable "ca_key_algorithm" {
  description = "Key algorithm for the Private CA"
  type        = string
  default     = "RSA_2048"

  validation {
    condition     = contains(["RSA_2048", "RSA_4096", "EC_prime256v1", "EC_secp384r1"], var.ca_key_algorithm)
    error_message = "Must be one of: RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1."
  }
}

variable "ca_signing_algorithm" {
  description = "Signing algorithm for the Private CA"
  type        = string
  default     = "SHA256WITHRSA"

  validation {
    condition     = contains(["SHA256WITHRSA", "SHA384WITHRSA", "SHA512WITHRSA", "SHA256WITHECDSA", "SHA384WITHECDSA", "SHA512WITHECDSA"], var.ca_signing_algorithm)
    error_message = "Must be one of: SHA256WITHRSA, SHA384WITHRSA, SHA512WITHRSA, SHA256WITHECDSA, SHA384WITHECDSA, SHA512WITHECDSA."
  }
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

variable "ca_permanent_deletion_days" {
  description = "Number of days before the Private CA is permanently deleted (7-30)"
  type        = number
  default     = 7

  validation {
    condition     = var.ca_permanent_deletion_days >= 7 && var.ca_permanent_deletion_days <= 30
    error_message = "Must be between 7 and 30 days."
  }
}

variable "session_duration_seconds" {
  description = "Duration in seconds for IAM Roles Anywhere sessions (900-3600)"
  type        = number
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 3600
    error_message = "Must be between 900 and 3600 seconds."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
