aws_region = "eu-west-1"

tags = {
  Project     = "nonaws-s3-access"
  ManagedBy   = "terraform"
  Environment = "dev"
}

# 1 CA
cas = {
  "dev-ca" = {
    ca_common_name             = "dev-root-ca"
    organization               = "MyOrg"
    ca_permanent_deletion_days = 7
  }
}

# 2 S3 buckets linked to the single CA
s3_buckets = {
  "dev-data" = {
    bucket_name = "CHANGE-ME-dev-data-bucket"
    ca_key      = "dev-ca"
  }
  "dev-logs" = {
    bucket_name = "CHANGE-ME-dev-logs-bucket"
    ca_key      = "dev-ca"
  }
}
