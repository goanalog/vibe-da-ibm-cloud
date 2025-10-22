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

# Generate HMAC keys automatically (no manual vars)
resource "ibm_cos_hmac_key" "lite" {
  instance_id = ibm_resource_instance.cos.id
}

# COS bucket
resource "ibm_cos_bucket" "vibe" {
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos.id
  region               = var.region
  storage_class        = "standard"
  force_destroy        = true
}

# Public READ (no public write)
resource "ibm_cos_bucket_policy" "public_read" {
  bucket = ibm_cos_bucket.vibe.bucket_name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicGet"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "arn:aws:s3:::${ibm_cos_bucket.vibe.bucket_name}/*"
      }
    ]
  })
}

# Render index.html with embedded function URL (guest/default)
locals {
  embedded_function_url = "https://us-south.functions.appdomain.cloud/api/v1/web/guest/default/get-presigned-url"
  rendered_index        = replace(file("${path.module}/index.html"), "https://us-south.functions.appdomain.cloud/api/v1/web/guest/default/get-presigned-url", local.embedded_function_url)
}

# Auto-seed rendered index.html into the bucket
resource "ibm_cos_bucket_object" "index" {
  bucket_crn = ibm_resource_instance.cos.id
  bucket     = ibm_cos_bucket.vibe.bucket_name
  key        = "index.html"
  content    = local.rendered_index
  http_headers = {
    "Content-Type" = "text/html"
  }
  depends_on = [ibm_cos_bucket_policy.public_read]
}

# Cloud Function web action (Node.js 18) for presigned URL (Lite-friendly)
resource "ibm_function_action" "get_presigned_url" {
  name    = "get-presigned-url"
  publish = true
  exec {
    kind = "nodejs:18"
    code = file("${path.module}/function/getPresignedUrl.js")
  }
  parameters = {
    COS_ACCESS_KEY_ID     = ibm_cos_hmac_key.lite.access_key_id
    COS_SECRET_ACCESS_KEY = ibm_cos_hmac_key.lite.secret_access_key
    BUCKET                = ibm_cos_bucket.vibe.bucket_name
    REGION                = var.region
  }
  annotations = {
    "web-export" = true
    "raw-http"   = true
  }
}

locals {
  endpoint_base = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
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
  value       = ibm_cos_hmac_key.lite.access_key_id
  description = "Generated COS HMAC access key id (for reference)."
}

output "hmac_secret_access_key" {
  value       = ibm_cos_hmac_key.lite.secret_access_key
  description = "Generated COS HMAC secret access key (for reference)."
  sensitive   = true
}
