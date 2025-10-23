provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  # Optimized local from previous review
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
}

# Use the dedicated resource for public access (works in newer providers)
resource "ibm_cos_bucket_public_access" "vibe_bucket_public_access" {
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  bucket_name          = ibm_cos_bucket.vibe_bucket.bucket_name
  public_access        = "public" # Allows public read access
}

resource "ibm_cos_bucket_object" "vibe_code" {
  # Use bucket_crn and bucket_location (required in older providers, still works in newer)
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location 

  key     = "index.html"
  content = local.html_content
  etag    = md5(local.html_content)

  # No ACL needed here when using ibm_cos_bucket_public_access
}

output "vibe_url" {
  value       = "https://s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}