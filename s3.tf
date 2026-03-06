# ─────────────────────────────────────────────
# S3 Bucket
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
  tags   = var.tags
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
  name   = "${var.project_name}-s3-read-write"
  policy = data.aws_iam_policy_document.s3_read_write.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_read_write" {
  role       = aws_iam_role.nonaws_server.name
  policy_arn = aws_iam_policy.s3_read_write.arn
}
