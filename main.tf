terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.62.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "ibm" {}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create Object Storage instance
resource "ibm_resource_instance" "cos_instance" {
  name     = var.cos_instance_name
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
}

# Create COS bucket
resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

# Upload index.html
resource "ibm_cos_object" "index_html" {
  bucket_crn   = ibm_cos_bucket.vibe_bucket.crn
  key          = "index.html"
  content_base64 = base64encode(var.index_html)
  content_type = "text/html"
}

# Outputs
output "vibe_url" {
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
  description = "Behold the consecrated endpoint for direct vibe consumption."
}

output "vibe_bucket_url" {
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
  description = "Direct link to your sacred bucket."
}
