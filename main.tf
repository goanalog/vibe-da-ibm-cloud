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
# Locals — smart fallback logic for HTML content
# ---------------------------------------------------------------------
locals {
  # Priority:
  # 1. Inline HTML from catalog input
  # 2. File path provided by user
  # 3. Default included index.html in module
  html_content = (
    length(trimspace(var.index_html)) > 0 ? var.index_html :
    (length(trimspace(var.index_html_file)) > 0 ? file(var.index_html_file) : file("${path.module}/index.html"))
  )
}

# ---------------------------------------------------------------------
# Generate a random suffix for globally unique resource names
# ---------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ---------------------------------------------------------------------
# Get resource group
# ---------------------------------------------------------------------
data "ibm_resource_group" "selected" {
  name = var.resource_group
}

# ---------------------------------------------------------------------
# Create COS instance
# ---------------------------------------------------------------------
resource "ibm_resource_instance" "cos_instance" {
  name              = var.cos_instance_name
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.selected.id
}

# ---------------------------------------------------------------------
# Create COS bucket
# ---------------------------------------------------------------------
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
  
  # --- FIX 2: Set public access directly on the bucket ---
  public_access        = true
}

# ---------------------------------------------------------------------
# Upload the index.html (inline or default)
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "index_html" {
  bucket       = ibm_cos_bucket.bucket.bucket_name
  key          = "index.html"
  content      = local.html_content
  content_type = "text/html"
  
  # Ensure bucket is created and public before uploading
  depends_on = [ibm_cos_bucket.bucket] 
}

# ---------------------------------------------------------------------
# Upload the vibe-face.png asset
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "vibe_face" {
  bucket       = ibm_cos_bucket.bucket.bucket_name
  key          = "vibe-face.png"
  
  # --- FIX 1: Changed "source" to "file" ---
  file         = "${path.module}/vibe-face.png"
  content_type = "image/png"
  
  # Ensure bucket is created and public before uploading
  depends_on = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# (The old public access resource block has been deleted)
# ---------------------------------------------------------------------