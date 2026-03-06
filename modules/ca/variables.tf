variable "name" {
  description = "Unique name for this CA instance (used as prefix for all resources)"
  type        = string
}

variable "ca_common_name" {
  description = "Common name for the Private CA certificate"
  type        = string
}

variable "organization" {
  description = "Organization name in the CA certificate subject"
  type        = string
}

variable "ca_key_algorithm" {
  description = "Key algorithm for the Private CA"
  type        = string
  default     = "RSA_2048"
}

variable "ca_signing_algorithm" {
  description = "Signing algorithm for the Private CA"
  type        = string
  default     = "SHA256WITHRSA"
}

variable "ca_validity_years" {
  description = "Validity period for the root CA certificate in years"
  type        = number
  default     = 10
}

variable "ca_permanent_deletion_days" {
  description = "Number of days before the Private CA is permanently deleted (7-30)"
  type        = number
  default     = 7
}

variable "session_duration_seconds" {
  description = "Duration in seconds for IAM Roles Anywhere sessions (900-3600)"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
