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
  html_content = (
    length(trimspace(var.index_html)) > 0 ? var.index_html :
    (length(trimspace(var.index_html_file)) > 0 ? file(var.index_html_file) : file("${path.module}/index.html"))
  )
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
  
  # --- FIX 3: Replaced policy resource with 'acl' ---
  acl                  = "public-read" 
}

# ---------------------------------------------------------------------
# Upload the index.html
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "index.html"
  content         = local.html_content
  
  # --- FIX 1: Removed 'content_type' ---
  
  depends_on = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# Upload the vibe-face.png asset
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "vibe_face" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "vibe-face.png"
  
  # --- FIX 2: Changed 'file' to 'filebase64' ---
  content         = filebase64("${path.module}/vibe-face.png")
  
  # --- FIX 1: Removed 'content_type' ---
  
  depends_on = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# (The 'ibm_cos_bucket_policy' resource has been deleted)
# ---------------------------------------------------------------------