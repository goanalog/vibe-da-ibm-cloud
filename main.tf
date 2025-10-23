provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  # OPTIMIZED: Use the raw HTML variable if provided, otherwise read the file content.
  # This removes the unnecessary base64 encode/decode cycle.
  html_content = var.vibe_code_raw != "" ? var.vibe_code_raw : file("${path.module}/index.html")
}

resource "ibm_resource_instance" "vibe_instance" {
  name     = "vibe-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = "global"
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = "us-south"
  force_delete         = true

  # BUG FIX: Add this line to make the website URL public (403 fix)
  public_access        = true
}

resource "ibm_cos_bucket_object" "vibe_code" {
  bucket  = ibm_cos_bucket.vibe_bucket.bucket_name
  key     = "index.html"
  # UPDATED: Use the optimized local variable
  content = local.html_content
  etag    = md5(local.html_content)
}

output "vibe_url" {
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}