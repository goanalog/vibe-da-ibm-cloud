terraform {
  required_version = ">= 1.5.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

provider "ibm" {
  region = var.region
}

resource "ibm_resource_instance" "cos_instance" {
  name     = "vibe-instance"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = "global"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  storage_class        = "standard"
  force_delete         = true
}

resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
  bucket_crn    = ibm_cos_bucket.vibe_bucket.crn
  index_document = var.website_index
  error_document = var.website_error
}

resource "ibm_cos_object" "index_html" {
  bucket_crn   = ibm_cos_bucket.vibe_bucket.crn
  key          = var.website_index
  content      = file("${path.module}/sample-app/index.html")
  content_type = "text/html"
}
