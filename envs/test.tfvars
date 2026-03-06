aws_region = "eu-west-1"

tags = {
  Project     = "nonaws-s3-access"
  ManagedBy   = "terraform"
  Environment = "test"
}

# 2 CAs
cas = {
  "test-app-ca" = {
    ca_common_name = "test-app-root-ca"
    organization   = "MyOrg"
  }
  "test-analytics-ca" = {
    ca_common_name   = "test-analytics-root-ca"
    organization     = "MyOrg"
    ca_key_algorithm = "RSA_4096"
  }
}

# 4 S3 buckets split across the two CAs
s3_buckets = {
  "test-app-data" = {
    bucket_name = "CHANGE-ME-test-app-data"
    ca_key      = "test-app-ca"
  }
  "test-app-uploads" = {
    bucket_name = "CHANGE-ME-test-app-uploads"
    ca_key      = "test-app-ca"
  }
  "test-analytics-raw" = {
    bucket_name = "CHANGE-ME-test-analytics-raw"
    ca_key      = "test-analytics-ca"
  }
  "test-analytics-processed" = {
    bucket_name = "CHANGE-ME-test-analytics-processed"
    ca_key      = "test-analytics-ca"
  }
}

