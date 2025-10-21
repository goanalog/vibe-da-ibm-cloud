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

provider "ibm" {
  region = var.region
}

# ---------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------
locals {
  html_content = var.index_html
}

# ---------------------------------------------------------------------
# Random Suffix
# ---------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ---------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------
data "ibm_resource_group" "selected" {
  name = var.resource_group
}

# ---------------------------------------------------------------------
# COS Instance
# ---------------------------------------------------------------------
resource "ibm_resource_instance" "cos_instance" {
  name              = var.cos_instance_name
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.selected.id
}

# ---------------------------------------------------------------------
# COS Bucket
# ---------------------------------------------------------------------
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

# ---------------------------------------------------------------------
# Upload the index.html
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "index.html"
  content         = local.html_content
  
  # 'content_type' removed (fix from 19:38 log)
  
  depends_on = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# Upload the vibe-face.png asset
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "vibe_face" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "vibe-face.png"
  
  # Changed to 'filebase64' (fix from 19:38 log)
  content         = filebase64("${path.module}/vibe-face.png")
  
  # 'content_type' removed (fix from 19:38 log)

  depends_on = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# (The 'ibm_cos_bucket_policy' resource has been removed
#  because it is not supported by provider v1.84.2)
# ---------------------------------------------------------------------