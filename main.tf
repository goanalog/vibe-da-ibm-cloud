provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
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
  
  # FIX ATTEMPT 3: Use the 'acl' argument for public access
  acl                  = "public-read"
}

# REMOVED: The ibm_cos_bucket_public_access resource, as it's not supported by this provider version.

resource "ibm_cos_bucket_object" "vibe_code" {
  # This fix (from the first log's errors) is still necessary
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location

  key     = "index.html"
  content = local.html_content
  etag    = md5(local.html_content)
}

output "vibe_url" {
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}