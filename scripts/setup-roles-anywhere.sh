#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup-roles-anywhere.sh
#
# Run this ONCE on your NON-AWS server after `terraform apply`.
# It generates a key + CSR, issues a cert from your Private CA,
# and configures the AWS CLI/SDK to use IAM Roles Anywhere automatically.
#
# Usage: ./setup-roles-anywhere.sh <config-file>
#        ./setup-roles-anywhere.sh --help
#
# Prerequisites: aws CLI installed and configured with credentials that have
#   acm-pca:IssueCertificate + acm-pca:GetCertificate permissions.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Help ─────────────────────────────────────────────────────────────────────

usage() {
  cat <<'USAGE'
Usage: ./setup-roles-anywhere.sh <config-file>

Reads all parameters from a config file (.conf).
See scripts/configs/setup-roles-anywhere.conf.example for a template.

Required variables in config file:
  CA_ARN              ARN of the AWS Private CA
  TRUST_ANCHOR_ARN    ARN of the IAM Roles Anywhere trust anchor
  PROFILE_ARN         ARN of the IAM Roles Anywhere profile
  ROLE_ARN            ARN of the IAM role to assume
  AWS_REGION          AWS region (e.g. eu-west-1)

Optional variables (defaults shown):
  SERVER_CN           Common name for the workload certificate  [workload-server]
  ORGANIZATION        Organization name in the certificate      [MyOrg]
  SIGNING_ALGORITHM   Signing algorithm for cert issuance       [SHA256WITHRSA]
  CERT_VALIDITY_DAYS  Certificate validity in days              [365]
  AWS_PROFILE_NAME    AWS CLI profile name to create            [nonaws]
  CERT_DIR            Directory to store certs and keys         [/etc/iam-roles-anywhere]
  HELPER_PATH         Path to install aws_signing_helper        [/usr/local/bin/aws_signing_helper]
USAGE
}

# ── Parse arguments ──────────────────────────────────────────────────────────

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  [ $# -eq 0 ] && exit 1
  exit 0
fi

CONFIG_FILE="$1"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: config file not found: $CONFIG_FILE" >&2
  exit 1
fi

# ── Load config ──────────────────────────────────────────────────────────────

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ── Set defaults for optional variables ──────────────────────────────────────

SERVER_CN="${SERVER_CN:-workload-server}"
ORGANIZATION="${ORGANIZATION:-MyOrg}"
SIGNING_ALGORITHM="${SIGNING_ALGORITHM:-SHA256WITHRSA}"
CERT_VALIDITY_DAYS="${CERT_VALIDITY_DAYS:-365}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-nonaws}"
CERT_DIR="${CERT_DIR:-/etc/iam-roles-anywhere}"
HELPER_PATH="${HELPER_PATH:-/usr/local/bin/aws_signing_helper}"

# ── Validate required variables ─────────────────────────────────────────────

MISSING=()
[ -z "${CA_ARN:-}" ] && MISSING+=("CA_ARN")
[ -z "${TRUST_ANCHOR_ARN:-}" ] && MISSING+=("TRUST_ANCHOR_ARN")
[ -z "${PROFILE_ARN:-}" ] && MISSING+=("PROFILE_ARN")
[ -z "${ROLE_ARN:-}" ] && MISSING+=("ROLE_ARN")
[ -z "${AWS_REGION:-}" ] && MISSING+=("AWS_REGION")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Error: missing required variables in $CONFIG_FILE:" >&2
  for var in "${MISSING[@]}"; do
    echo "  - $var" >&2
  done
  echo "" >&2
  echo "Run './setup-roles-anywhere.sh --help' for details." >&2
  exit 1
fi

# ── Begin setup ──────────────────────────────────────────────────────────────

echo "Config loaded from: $CONFIG_FILE"
echo "  CA:       $CA_ARN"
echo "  Region:   $AWS_REGION"
echo "  Profile:  $AWS_PROFILE_NAME"
echo ""

# 1. Create cert directory
echo "-> Creating cert directory..."
sudo mkdir -p "$CERT_DIR"

# 2. Generate private key and CSR
echo "-> Generating private key and CSR..."
sudo openssl req -new -newkey rsa:2048 -nodes \
  -keyout "$CERT_DIR/workload.key" \
  -out "$CERT_DIR/workload.csr" \
  -subj "/CN=${SERVER_CN}/O=${ORGANIZATION}"

sudo chmod 600 "$CERT_DIR/workload.key"

# 3. Issue certificate from AWS Private CA
echo "-> Issuing certificate from AWS Private CA..."
CERT_ARN=$(aws acm-pca issue-certificate \
  --certificate-authority-arn "$CA_ARN" \
  --csr "fileb://${CERT_DIR}/workload.csr" \
  --signing-algorithm "$SIGNING_ALGORITHM" \
  --validity "Value=${CERT_VALIDITY_DAYS},Type=DAYS" \
  --region "$AWS_REGION" \
  --query CertificateArn --output text)

echo "  Certificate ARN: $CERT_ARN"

# Wait for issuance (usually a few seconds)
echo "-> Waiting for certificate to be issued..."
aws acm-pca wait certificate-issued \
  --certificate-authority-arn "$CA_ARN" \
  --certificate-arn "$CERT_ARN" \
  --region "$AWS_REGION"

# 4. Download the certificate
echo "-> Downloading certificate..."
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

# 5. Download aws_signing_helper
echo "-> Downloading aws_signing_helper..."
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

# 6. Configure AWS CLI profile
echo "-> Configuring AWS profile '${AWS_PROFILE_NAME}'..."
mkdir -p ~/.aws

# Append the profile block (idempotent — you can re-run safely)
grep -q "\[profile ${AWS_PROFILE_NAME}\]" ~/.aws/config 2>/dev/null || cat >> ~/.aws/config <<EOF

[profile ${AWS_PROFILE_NAME}]
region = ${AWS_REGION}
credential_process = ${HELPER_PATH} credential-process \\
  --certificate ${CERT_DIR}/workload.crt \\
  --private-key ${CERT_DIR}/workload.key \\
  --trust-anchor-arn ${TRUST_ANCHOR_ARN} \\
  --profile-arn ${PROFILE_ARN} \\
  --role-arn ${ROLE_ARN}
EOF

# 7. Smoke test
echo ""
echo "-> Testing credentials..."
aws sts get-caller-identity --profile "$AWS_PROFILE_NAME"

echo ""
echo "Setup complete."
echo "  Use AWS_PROFILE=${AWS_PROFILE_NAME} or --profile ${AWS_PROFILE_NAME} in your scripts."
echo "  The signing helper automatically refreshes credentials before expiry."
