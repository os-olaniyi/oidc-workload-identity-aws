aws_region = "eu-west-1"

tags = {
  Project     = "nonaws-s3-access"
  ManagedBy   = "terraform"
  Environment = "production"
}

# 1 CA
cas = {
  "prod-ca" = {
    ca_common_name             = "prod-root-ca"
    organization               = "MyOrg"
    ca_permanent_deletion_days = 30
  }
}

# 1 S3 bucket
s3_buckets = {
  "prod-data" = {
    bucket_name = "CHANGE-ME-prod-data-bucket"
    ca_key      = "prod-ca"
  }
}
