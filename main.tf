provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  # This optimization is still correct
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
  # REMOVED: public_access = true (This was the source of Error 1)
}

# FIX 1: Add a separate resource to manage public access
resource "ibm_cos_bucket_public_access" "vibe_bucket_public_access" {
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  bucket_name          = ibm_cos_bucket.vibe_bucket.bucket_name
  public_access        = "public" # Allows public read access
}

resource "ibm_cos_bucket_object" "vibe_code" {
  # FIX 2: Use the arguments required by the provider (as seen in logs)
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location

  # REMOVED: bucket = ibm_cos_bucket.vibe_bucket.bucket_name (Source of Error 2)
  
  # These arguments are correct
  key     = "index.html"
  content = local.html_content
  etag    = md5(local.html_content)
}

output "vibe_url" {
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}