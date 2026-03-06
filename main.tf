# ─────────────────────────────────────────────
# 1. AWS Private Certificate Authority (Root CA)
# ─────────────────────────────────────────────

resource "aws_acmpca_certificate_authority" "root_ca" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA256WITHRSA"

    subject {
      common_name  = var.ca_common_name
      organization = var.organization
    }
  }

  # Disable CRL — not needed for Roles Anywhere in simple setups.
  # Enable if you need certificate revocation.
  revocation_configuration {}

  tags = var.tags
}

# Self-sign the root CA certificate (required to activate it)
resource "aws_acmpca_certificate" "root_ca_cert" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.root_ca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.root_ca.certificate_signing_request
  signing_algorithm           = "SHA256WITHRSA"

  template_arn = "arn:aws:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 10
  }
}

# Activate the CA by importing its own signed certificate
resource "aws_acmpca_certificate_authority_certificate" "root_ca_activation" {
  certificate_authority_arn = aws_acmpca_certificate_authority.root_ca.arn
  certificate               = aws_acmpca_certificate.root_ca_cert.certificate
  certificate_chain         = aws_acmpca_certificate.root_ca_cert.certificate_chain
}

# ─────────────────────────────────────────────
# 2. IAM Roles Anywhere — Trust Anchor
# ─────────────────────────────────────────────

resource "aws_rolesanywhere_trust_anchor" "this" {
  name    = "${var.project_name}-trust-anchor"
  enabled = true

  source {
    source_type = "AWS_ACM_PCA"
    source_data {
      acm_pca_arn = aws_acmpca_certificate_authority.root_ca.arn
    }
  }

  # Trust anchor only becomes usable after the CA is activated
  depends_on = [aws_acmpca_certificate_authority_certificate.root_ca_activation]

  tags = var.tags
}

# ─────────────────────────────────────────────
# 3. IAM Role — Assumed by the NONAWS Server
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

    # Scope to ONLY this trust anchor — prevents any other CA from using this role
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_rolesanywhere_trust_anchor.this.arn]
    }
  }
}

resource "aws_iam_role" "nonaws_server" {
  name               = "${var.project_name}-server-role"
  assume_role_policy = data.aws_iam_policy_document.roles_anywhere_trust.json
  tags               = var.tags
}

# ─────────────────────────────────────────────
# 4. IAM Roles Anywhere — Profile
# ─────────────────────────────────────────────
# The profile links the trust anchor → IAM role and controls session settings.

resource "aws_rolesanywhere_profile" "this" {
  name    = "${var.project_name}-profile"
  enabled = true

  role_arns        = [aws_iam_role.nonaws_server.arn]
  duration_seconds = 3600 # 1 hour — signing helper auto-refreshes

  tags = var.tags
}
