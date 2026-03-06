# ─────────────────────────────────────────────
# S3 Bucket
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access — this bucket is private, accessed via IAM only
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_algorithm
      kms_master_key_id = var.kms_key_id
    }
  }
}

# ─────────────────────────────────────────────
# IAM Policy — S3 Read/Write for the Role
# ─────────────────────────────────────────────

data "aws_iam_policy_document" "s3_read_write" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [aws_s3_bucket.this.arn]
  }

  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_read_write" {
  name   = "${var.policy_name_prefix}-s3-rw"
  policy = data.aws_iam_policy_document.s3_read_write.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_read_write" {
  role       = var.role_name
  policy_arn = aws_iam_policy.s3_read_write.arn
}
