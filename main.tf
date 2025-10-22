provider "ibm" {
  region = var.region
}

data "ibm_resource_group" "default" {
  is_default = true
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# COS instance (Lite)
resource "ibm_resource_instance" "cos" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.default.id
}

# Generate HMAC credentials via resource key (Writer role)
resource "ibm_resource_key" "cos_hmac" {
  name                 = "vibe-hmac-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos.id
  role                 = "Writer"
}

# COS bucket (region is derived from the instance/location; provider v1.84 does not accept region/force_destroy here)
resource "ibm_cos_bucket" "vibe" {
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos.id
  storage_class        = "standard"
}

# Public READ via object ACL: ensure auto-seeded object has public-read
# Upload pre-rendered index.html with ACL if supported; fall back to default if field not available
resource "ibm_cos_bucket_object" "index" {
  bucket_crn = ibm_resource_instance.cos.id
  bucket     = ibm_cos_bucket.vibe.bucket_name
  key        = "index.html"
  content    = local.rendered_index
  http_headers = {
    "Content-Type" = "text/html"
  }
  # Some provider versions support 'canned_acl'; if present, this makes the object public
  canned_acl = "public-read"
}

# Cloud Function web action (Node.js 18) for presigned URL (Lite-friendly)
resource "ibm_function_action" "get_presigned_url" {
  name    = "get-presigned-url"
  publish = true
  exec {
    kind = "nodejs:18"
    code = file("${path.module}/function/getPresignedUrl.js")
  }

  # Parse HMAC keys from resource_key credentials JSON
  parameters = {
    COS_ACCESS_KEY_ID     = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].access_key_id
    COS_SECRET_ACCESS_KEY = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].secret_access_key
    BUCKET                = ibm_cos_bucket.vibe.bucket_name
    REGION                = var.region
  }

  annotations = {
    "web-export" = true
    "raw-http"   = true
  }
}

# Embed the guest/default function URL into the HTML prior to upload
locals {
  embedded_function_url = "https://us-south.functions.appdomain.cloud/api/v1/web/guest/default/get-presigned-url"
  rendered_index        = replace(file("${path.module}/index.html"), "https://us-south.functions.appdomain.cloud/api/v1/web/guest/default/get-presigned-url", local.embedded_function_url)
  endpoint_base         = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

output "bucket_name" {
  value       = ibm_cos_bucket.vibe.bucket_name
  description = "Unique COS bucket name."
}

output "vibe_bucket_url" {
  value       = local.endpoint_base
  description = "Base bucket endpoint."
}

output "vibe_url" {
  value       = "${local.endpoint_base}/index.html"
  description = "Public URL to the IDE (index.html)."
}

output "upload_endpoint" {
  value       = local.embedded_function_url
  description = "Web action URL for get-presigned-url (guest/default pre-embedded)."
}

output "hmac_access_key_id" {
  value       = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].access_key_id
  description = "Generated COS HMAC access key id (for reference)."
}

output "hmac_secret_access_key" {
  value       = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].secret_access_key
  description = "Generated COS HMAC secret access key (for reference)."
  sensitive   = true
}
