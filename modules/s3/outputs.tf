output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "policy_arn" {
  description = "ARN of the S3 read/write IAM policy"
  value       = aws_iam_policy.s3_read_write.arn
}
