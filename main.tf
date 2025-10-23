provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  # Handle both raw HTML and fallback sample
  source_final = var.vibe_code_raw != "" ? base64encode(var.vibe_code_raw) : base64encode(file("${path.module}/index.html"))
  html_decoded = base64decode(local.source_final)
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

# --- CRITICAL FIX ADDED HERE ---
# This resource makes the bucket's contents readable by the public.
# Without this, the vibe_url will return a 403 Access Denied error.
resource "ibm_cos_bucket_public_access" "vibe_bucket_public_access" {
  bucket_name   = ibm_cos_bucket.vibe_bucket.bucket_name
  public_access = "public-read"
  
  # We must ensure this happens *after* the bucket is created
  depends_on = [
    ibm_cos_bucket.vibe_bucket
  ]
}
# --- END OF FIX ---

resource "ibm_cos_bucket_object" "vibe_code" {
  # --- FIX based on provider error log ---
  # Replaced 'bucket' with 'bucket_crn' and added required 'bucket_location'
  # to match the provider's expected arguments.
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location
  # --- END OF FIX ---
  
  key     = "index.html"
  content = local.html_decoded
  etag    = md5(local.html_decoded)

  # We must ensure this happens *after* the public access is set
  depends_on = [
    ibm_cos_bucket_public_access.vibe_bucket_public_access
  ]
}

output "vibe_url" {
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}

