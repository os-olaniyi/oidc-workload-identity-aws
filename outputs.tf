output "trust_anchor_arn" {
  description = "ARN of the IAM Roles Anywhere trust anchor — needed for aws_signing_helper"
  value       = aws_rolesanywhere_trust_anchor.this.arn
}

output "profile_arn" {
  description = "ARN of the IAM Roles Anywhere profile — needed for aws_signing_helper"
  value       = aws_rolesanywhere_profile.this.arn
}

output "role_arn" {
  description = "ARN of the IAM role the Contabo server will assume"
  value       = aws_iam_role.contabo_server.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

output "ca_arn" {
  description = "ARN of the Private CA — used to issue workload certificates"
  value       = aws_acmpca_certificate_authority.root_ca.arn
}

output "signing_helper_command" {
  description = "aws_signing_helper credential-process command for ~/.aws/config"
  value       = <<-EOT
    credential_process = ./aws_signing_helper credential-process \
      --certificate /etc/iam-roles-anywhere/workload.crt \
      --private-key /etc/iam-roles-anywhere/workload.key \
      --trust-anchor-arn ${aws_rolesanywhere_trust_anchor.this.arn} \
      --profile-arn ${aws_rolesanywhere_profile.this.arn} \
      --role-arn ${aws_iam_role.contabo_server.arn}
  EOT
}
