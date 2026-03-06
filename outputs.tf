output "cas" {
  description = "All CA instances with their ARNs and role details"
  value = {
    for k, ca in module.ca : k => {
      ca_arn           = ca.ca_arn
      role_arn         = ca.role_arn
      trust_anchor_arn = ca.trust_anchor_arn
      profile_arn      = ca.profile_arn
    }
  }
}

output "s3_buckets" {
  description = "All S3 bucket instances with their names and ARNs"
  value = {
    for k, s3 in module.s3 : k => {
      bucket_name = s3.bucket_name
      bucket_arn  = s3.bucket_arn
      policy_arn  = s3.policy_arn
    }
  }
}

output "signing_helper_commands" {
  description = "aws_signing_helper credential-process commands per CA"
  value = {
    for k, ca in module.ca : k => <<-EOT
      credential_process = ./aws_signing_helper credential-process \
        --certificate /etc/iam-roles-anywhere/workload.crt \
        --private-key /etc/iam-roles-anywhere/workload.key \
        --trust-anchor-arn ${ca.trust_anchor_arn} \
        --profile-arn ${ca.profile_arn} \
        --role-arn ${ca.role_arn}
    EOT
  }
}
