output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "trust_anchor_arn" {
  description = "ARN of the IAM Roles Anywhere trust anchor"
  value       = aws_rolesanywhere_trust_anchor.this.arn
}

output "profile_arn" {
  description = "ARN of the IAM Roles Anywhere profile"
  value       = aws_rolesanywhere_profile.this.arn
}

output "ca_arn" {
  description = "ARN of the Private CA"
  value       = aws_acmpca_certificate_authority.this.arn
}
