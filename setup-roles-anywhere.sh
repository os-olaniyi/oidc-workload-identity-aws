#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup-roles-anywhere.sh
#
# Run this ONCE on your NON-AWS server after `terraform apply`.
# It generates a key + CSR, issues a cert from your Private CA,
# and configures the AWS CLI/SDK to use IAM Roles Anywhere automatically.
#
# Prerequisites: aws CLI installed and configured with credentials that have
#   acm-pca:IssueCertificate + acm-pca:GetCertificate permissions.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Fill these in from `terraform output` ────────────────────────────────────
CA_ARN="arn:aws:acm-pca:eu-west-1:123456789012:certificate-authority/xxxx"
TRUST_ANCHOR_ARN="arn:aws:rolesanywhere:eu-west-1:123456789012:trust-anchor/xxxx"
PROFILE_ARN="arn:aws:rolesanywhere:eu-west-1:123456789012:profile/xxxx"
ROLE_ARN="arn:aws:iam::123456789012:role/contabo-s3-access-contabo-role"
AWS_REGION="eu-west-1"
# ─────────────────────────────────────────────────────────────────────────────

CERT_DIR="/etc/iam-roles-anywhere"
HELPER_PATH="/usr/local/bin/aws_signing_helper"

echo "→ Creating cert directory..."
sudo mkdir -p "$CERT_DIR"

# 1. Generate private key and CSR
# CN=contabo-server is just an identifier — not a domain, not a hostname.
echo "→ Generating private key and CSR..."
sudo openssl req -new -newkey rsa:2048 -nodes \
  -keyout "$CERT_DIR/workload.key" \
  -out "$CERT_DIR/workload.csr" \
  -subj "/CN=contabo-server/O=MyOrg"

sudo chmod 600 "$CERT_DIR/workload.key"

# 2. Issue certificate from AWS Private CA
echo "→ Issuing certificate from AWS Private CA..."
CERT_ARN=$(aws acm-pca issue-certificate \
  --certificate-authority-arn "$CA_ARN" \
  --csr fileb://"$CERT_DIR/workload.csr" \
  --signing-algorithm SHA256WITHRSA \
  --validity Value=365,Type=DAYS \
  --region "$AWS_REGION" \
  --query CertificateArn --output text)

echo "  Certificate ARN: $CERT_ARN"

# Wait for issuance (usually a few seconds)
echo "→ Waiting for certificate to be issued..."
aws acm-pca wait certificate-issued \
  --certificate-authority-arn "$CA_ARN" \
  --certificate-arn "$CERT_ARN" \
  --region "$AWS_REGION"

# 3. Download the certificate
echo "→ Downloading certificate..."
aws acm-pca get-certificate \
  --certificate-authority-arn "$CA_ARN" \
  --certificate-arn "$CERT_ARN" \
  --region "$AWS_REGION" \
  --query Certificate \
  --output text | sudo tee "$CERT_DIR/workload.crt" > /dev/null

# Also save the certificate chain (CA cert) — some tools need it
aws acm-pca get-certificate \
  --certificate-authority-arn "$CA_ARN" \
  --certificate-arn "$CERT_ARN" \
  --region "$AWS_REGION" \
  --query CertificateChain \
  --output text | sudo tee "$CERT_DIR/ca-chain.crt" > /dev/null

echo "  Certificate saved to $CERT_DIR/workload.crt"

# 4. Download aws_signing_helper
echo "→ Downloading aws_signing_helper..."
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  ARCH_PATH="X86_64"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_PATH="ARM64"
else
  echo "Unsupported architecture: $ARCH" && exit 1
fi

sudo curl -fsSLo "$HELPER_PATH" \
  "https://rolesanywhere.amazonaws.com/releases/latest/${ARCH_PATH}/Linux/aws_signing_helper"
sudo chmod +x "$HELPER_PATH"

# 5. Configure AWS CLI profile
echo "→ Configuring AWS profile 'nonaws'..."
mkdir -p ~/.aws

# Append the profile block (idempotent — you can re-run safely)
grep -q "\[profile nonaws\]" ~/.aws/config 2>/dev/null || cat >> ~/.aws/config <<EOF

[profile nonaws]
region = ${AWS_REGION}
credential_process = ${HELPER_PATH} credential-process \\
  --certificate ${CERT_DIR}/workload.crt \\
  --private-key ${CERT_DIR}/workload.key \\
  --trust-anchor-arn ${TRUST_ANCHOR_ARN} \\
  --profile-arn ${PROFILE_ARN} \\
  --role-arn ${ROLE_ARN}
EOF

# 6. Smoke test
echo ""
echo "→ Testing credentials..."
aws sts get-caller-identity --profile nonaws

echo ""
echo "✓ Setup complete."
echo "  Use AWS_PROFILE=contabo or --profile nonaws in your scripts."
echo "  The signing helper automatically refreshes credentials before expiry."
