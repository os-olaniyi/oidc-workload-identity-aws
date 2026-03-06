# ─────────────────────────────────────────────
# CA instances
# ─────────────────────────────────────────────

module "ca" {
  source   = "./modules/ca"
  for_each = var.cas

  name                       = each.key
  ca_common_name             = each.value.ca_common_name
  organization               = each.value.organization
  ca_key_algorithm           = each.value.ca_key_algorithm
  ca_signing_algorithm       = each.value.ca_signing_algorithm
  ca_validity_years          = each.value.ca_validity_years
  ca_permanent_deletion_days = each.value.ca_permanent_deletion_days
  session_duration_seconds   = each.value.session_duration_seconds
  tags                       = var.tags
}

# ─────────────────────────────────────────────
# S3 bucket instances
# ─────────────────────────────────────────────

module "s3" {
  source   = "./modules/s3"
  for_each = var.s3_buckets

  bucket_name          = each.value.bucket_name
  role_name            = module.ca[each.value.ca_key].role_name
  policy_name_prefix   = each.key
  force_destroy        = each.value.force_destroy
  encryption_algorithm = each.value.encryption_algorithm
  kms_key_id           = each.value.kms_key_id
  tags                 = var.tags
}
