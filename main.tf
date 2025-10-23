###############################################################################
# Vibe Landing Zone — COS Static Website + Optional Functions
###############################################################################

terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

provider "ibm" {
  region = var.region
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-cos-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = var.resource_group_id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name           = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  region_location       = var.region
  storage_class         = "standard"
  force_delete          = true

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn   = ibm_cos_bucket.vibe_bucket.crn
  key          = "index.html"
  content      = file("${path.module}/index.html")
  content_type = "text/html"
}

resource "ibm_cos_bucket_object" "error_html" {
  bucket_crn   = ibm_cos_bucket.vibe_bucket.crn
  key          = "404.html"
  content      = file("${path.module}/404.html")
  content_type = "text/html"
}

resource "ibm_function_namespace" "vibe_namespace" {
  name              = "vibe-namespace-${random_string.suffix.result}"
  resource_group_id = var.resource_group_id
}

output "vibe_bucket_name" {
  description = "Name of the created COS bucket"
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}

output "vibe_bucket_endpoint" {
  description = "Website endpoint for the COS bucket"
  value       = ibm_cos_bucket.vibe_bucket.website_endpoint
}

output "primaryoutputlink" {
  description = "Primary link to access your live Vibe app"
  value       = ibm_cos_bucket.vibe_bucket.website_endpoint
}
