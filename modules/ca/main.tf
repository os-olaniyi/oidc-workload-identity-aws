# ─────────────────────────────────────────────
# 1. AWS Private Certificate Authority (Root CA)
# ─────────────────────────────────────────────

resource "aws_acmpca_certificate_authority" "this" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = var.ca_key_algorithm
    signing_algorithm = var.ca_signing_algorithm

    subject {
      common_name  = var.ca_common_name
      organization = var.organization
    }
  }

  revocation_configuration {}

  permanent_deletion_time_in_days = var.ca_permanent_deletion_days

  # Set to true in production to prevent accidental deletion ($400/month resource)
  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}

# Self-sign the root CA certificate (required to activate it)
resource "aws_acmpca_certificate" "this" {
  certificate_authority_arn    = aws_acmpca_certificate_authority.this.arn
  certificate_signing_request = aws_acmpca_certificate_authority.this.certificate_signing_request
  signing_algorithm           = var.ca_signing_algorithm

  template_arn = "arn:aws:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = var.ca_validity_years
  }
}

# Activate the CA by importing its own signed certificate
resource "aws_acmpca_certificate_authority_certificate" "this" {
  certificate_authority_arn = aws_acmpca_certificate_authority.this.arn
  certificate              = aws_acmpca_certificate.this.certificate
  certificate_chain        = aws_acmpca_certificate.this.certificate_chain
}

# ─────────────────────────────────────────────
# 2. IAM Roles Anywhere — Trust Anchor
# ─────────────────────────────────────────────

resource "aws_rolesanywhere_trust_anchor" "this" {
  name    = "${var.name}-trust-anchor"
  enabled = true

  source {
    source_type = "AWS_ACM_PCA"
    source_data {
      acm_pca_arn = aws_acmpca_certificate_authority.this.arn
    }
  }

  depends_on = [aws_acmpca_certificate_authority_certificate.this]

  tags = var.tags
}

# ─────────────────────────────────────────────
# 3. IAM Role — Assumed by the Non-AWS Server
# ─────────────────────────────────────────────

data "aws_iam_policy_document" "roles_anywhere_trust" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]

    principals {
      type        = "Service"
      identifiers = ["rolesanywhere.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_rolesanywhere_trust_anchor.this.arn]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-server-role"
  assume_role_policy = data.aws_iam_policy_document.roles_anywhere_trust.json
  tags               = var.tags
}

# ─────────────────────────────────────────────
# 4. IAM Roles Anywhere — Profile
# ─────────────────────────────────────────────

resource "aws_rolesanywhere_profile" "this" {
  name    = "${var.name}-profile"
  enabled = true

  role_arns        = [aws_iam_role.this.arn]
  duration_seconds = var.session_duration_seconds

  tags = var.tags
}
