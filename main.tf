terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.84.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.5.0"
}

provider "ibm" {}

# Random suffix for globally-unique names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ----- Variables -----
variable "region" {
  description = "Region for COS instance"
  type        = string
  default     = "us-south"
}

variable "enable_functions" {
  description = "Enable IBM Cloud Functions (OpenWhisk) presign endpoint (optional)"
  type        = bool
  default     = false
}

# ----- COS Lite Instance -----
resource "ibm_resource_instance" "cos" {
  name     = "vibe-cos-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
  tags     = ["vibe", "lite", "da"]
}

# ----- COS Bucket (cross-region us-geo for public hosting) -----
resource "ibm_cos_bucket" "vibe" {
  bucket_name           = "vibe-bucket-${random_string.suffix.result}"
  ibm_cos_instance_crn  = ibm_resource_instance.cos.id
  storage_class         = "standard"
  cross_region_location = "us-geo"
}

# ----- Upload sample index.html at deploy time -----
resource "ibm_cos_bucket_object" "index" {
  bucket_crn      = ibm_cos_bucket.vibe.bucket_crn
  bucket_location = ibm_cos_bucket.vibe.cross_region_location
  key             = "index.html"
  content         = file("${path.module}/index.html")
  content_type    = "text/html"
}

# (Optional) IBM Cloud Functions resources - behind a feature flag
# NOTE: Provider schemas may differ across versions; this block is disabled by default.
# Enable by setting -var enable_functions=true
# The code for the action lives in manifest_upload.js (Node.js).
# If you enable this, ensure your account has Functions Lite enabled in the chosen region.
resource "ibm_function_namespace" "vibe" {
  count     = var.enable_functions ? 1 : 0
  name      = "vibe-ns-${random_string.suffix.result}"
  location  = var.region
}

resource "ibm_function_action" "presign" {
  count      = var.enable_functions ? 1 : 0
  name       = "vibe-presign-${random_string.suffix.result}"
  namespace  = ibm_function_namespace.vibe[0].name
  exec {
    kind = "nodejs:default"
    code = file("${path.module}/manifest_upload.js")
  }
  # Expose as web action (annotations may be schema-version dependent)
  annotations = jsonencode({
    "web-export" = "true",
    "raw-http"   = "true"
  })
}

# ----- Outputs -----
output "vibe_bucket_name" {
  description = "COS bucket name hosting your app"
  value       = ibm_cos_bucket.vibe.bucket_name
}

output "vibe_url" {
  description = "Public URL for your deployed Vibe app"
  value       = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

output "vibe_presign_endpoint" {
  description = "Optional Functions endpoint for presigned upload (only when enable_functions=true)"
  value       = var.enable_functions ? "https://us-south.functions.cloud.ibm.com/api/v1/web/${ibm_function_action.presign[0].namespace}/default/${ibm_function_action.presign[0].name}.json" : null
}
